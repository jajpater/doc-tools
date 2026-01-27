{ pkgs }:

pkgs.mkShell {
  packages = with pkgs; [
    python3
    ghostscript
    imagemagick
    libtiff
    poppler_utils
    typst
    python3Packages.pymupdf
  ];
}
