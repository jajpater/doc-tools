{
  description = "Personal scripts - packaged for Nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          lib = pkgs.lib;
          conversionPython = pkgs.python3.withPackages (ps: with ps; [
            pypandoc
            pyyaml
            gitpython
            python-docx
          ]);
          mkScriptsPackage = { name, src, pythonEnv ? null, runtimePaths ? [ ] }:
            pkgs.stdenvNoCC.mkDerivation {
              pname = name;
              version = "0.1.0";
              src = src;
              dontBuild = true;
              dontPatchShebangs = true;
              nativeBuildInputs = [ pkgs.makeWrapper ];
              installPhase = ''
                mkdir -p $out/bin
                mkdir -p $out/libexec
                for f in "$src"/*; do
                  [ -e "$f" ] || continue
                  case "$f" in
                    *.md|*.txt) continue ;;
                    *__pycache__*) continue ;;
                  esac
                  if [ -d "$f" ]; then
                    cp -r "$f" "$out/bin/$(basename "$f")"
                  elif [ -f "$f" ]; then
                    cp -f "$f" "$out/bin/$(basename "$f")"
                  fi
                done
                chmod +x $out/bin/* 2>/dev/null || true

                if [ -n "${if pythonEnv != null then "1" else ""}" ]; then
                  runtime_path="${lib.makeBinPath runtimePaths}"
                  for f in "$out/bin"/*; do
                    [ -f "$f" ] || continue
                    if head -n 1 "$f" | grep -q '^#!/usr/bin/env python3'; then
                      base="$(basename "$f")"
                      mv "$f" "$out/libexec/$base"
                      makeWrapper "${pythonEnv}/bin/python3" "$out/bin/$base" \
                        --add-flags "$out/libexec/$base" \
                        ${if runtimePaths != [ ] then ''--prefix PATH : "$runtime_path"'' else ""}
                    fi
                  done
                fi
              '';
            };
        in
        {
          audio-tools = mkScriptsPackage {
            name = "audio-tools";
            src = ./clusters/audio;
          };
          pdf-tools = mkScriptsPackage {
            name = "pdf-tools";
            src = ./clusters/pdf-tools;
          };
          ocr-tools = mkScriptsPackage {
            name = "ocr-tools";
            src = ./clusters/ocr;
          };
          conversion-tools = mkScriptsPackage {
            name = "conversion-tools";
            src = ./clusters/conversion;
            pythonEnv = conversionPython;
            runtimePaths = with pkgs; [
              pandoc
            ];
          };

          all-scripts = pkgs.symlinkJoin {
            name = "all-scripts";
            paths = [
              self.packages.${system}.audio-tools
              self.packages.${system}.pdf-tools
              self.packages.${system}.ocr-tools
              self.packages.${system}.conversion-tools
            ];
          };

          default = self.packages.${system}.all-scripts;
        });

      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          audio = import ./devshells/audio.nix { inherit pkgs; };
          pdf-tools = import ./devshells/pdf-tools.nix { inherit pkgs; };
          ocr = import ./devshells/ocr.nix { inherit pkgs; };
          conversion = import ./devshells/conversion.nix { inherit pkgs; };
          planning = import ./devshells/planning.nix { inherit pkgs; };
          default = pkgs.mkShell {
            packages = with pkgs; [
              git
              python3
            ];
          };
        });
    };
}
