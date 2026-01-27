{ pkgs }:

let
  lib = pkgs.lib;
  langs = pkgs.tesseractLanguages or {};
  has = name: builtins.hasAttr name langs;
  opt = name: lib.optional (has name) langs.${name};
in
pkgs.mkShell {
  packages =
    (with pkgs; [
      python3
      tesseract
      ocrmypdf
      poppler-utils
      img2pdf
    ])
    ++ lib.flatten [
      (opt "nld")
      (opt "eng")
      (opt "deu")
      (opt "lat")
      (opt "heb")
      (opt "ell")
      (opt "grc")
      (opt "fra")
    ];
}
