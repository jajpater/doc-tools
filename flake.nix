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
          mkScriptsPackage = name: src:
            pkgs.stdenvNoCC.mkDerivation {
              pname = name;
              version = "0.1.0";
              src = src;
              dontBuild = true;
              dontPatchShebangs = true;
              installPhase = ''
                mkdir -p $out/bin
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
              '';
            };
        in
        {
          audio-tools = mkScriptsPackage "audio-tools" ./clusters/audio;
          pdf-tools = mkScriptsPackage "pdf-tools" ./clusters/pdf-tools;
          ocr-tools = mkScriptsPackage "ocr-tools" ./clusters/ocr;
          conversion-tools = mkScriptsPackage "conversion-tools" ./clusters/conversion;

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
