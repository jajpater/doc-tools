# Scripts Repo (Nix-enabled)

This repo contains personal scripts organized into clusters, with a Nix flake
providing packages and dev shells.

## Layout

- `clusters/` - script collections (audio, pdf, ocr, planning, fs-tools, conversion)
- `packages/` - Nix packages (e.g. MinerU)
- `devshells/` - per-cluster devShells
- `docs/` - notes and legacy docs

## Quick use

Build a package:
```
nix build .#audio-tools
```

Run a shell for a cluster:
```
nix develop .#pdf-tools
```

List available outputs:
```
nix flake show
```

## OCR languages

The OCR devshell installs common Tesseract language packs when available:
`nld`, `eng`, `deu`, `lat`, `heb`, `ell` (Greek), `grc` (Ancient Greek), `fra`.
