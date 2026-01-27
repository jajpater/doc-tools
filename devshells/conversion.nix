{ pkgs }:

pkgs.mkShell {
  packages = with pkgs; [
    python3
    python3Packages.pypandoc
    python3Packages.pyyaml
    python3Packages.gitpython
    python3Packages.python-docx
    pandoc
    docx2txt
    unzip
    perl
    fzf
    wofi
    xmlstarlet
    imagemagick
    potrace
    poppler_utils
    libreoffice-fresh
    typst
    (texlive.combine {
      inherit (texlive)
        scheme-medium
        latexmk
        collection-fontsrecommended
        collection-latex
        collection-latexextra
        bidi
        zref;
    })
  ];
}
