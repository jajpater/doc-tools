{ pkgs }:

pkgs.mkShell {
  packages = with pkgs; [
    python3
    python3Packages.requests
  ];
}
