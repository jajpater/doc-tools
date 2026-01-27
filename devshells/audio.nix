{ pkgs }:

let
  lib = pkgs.lib;
  py = pkgs.python3Packages;
  has = name: builtins.hasAttr name py;
  opt = name: lib.optional (has name) py.${name};
in
pkgs.mkShell {
  packages =
    (with pkgs; [
      python3
      ffmpeg
      id3v2
      vorbis-tools
    ])
    ++ lib.flatten [
      (opt "faster-whisper")
      (opt "torch")
      (opt "tqdm")
    ];
}
