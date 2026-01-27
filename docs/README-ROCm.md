# ROCm transcription choices

This note summarizes the ROCm options we evaluated for Whisper-style transcription
and why some were not chosen.

## Options overview

Option A: openai-whisper (torch ROCm)
- Complexity: low to medium
- Chance of success: low to medium (20-50%) on newer AMD GPUs
- Speed: faster than CPU when it works, slower than CTranslate2/CUDA
- Notes: we tried this route, but it can fail with
  `HIP error: invalid device function`, which usually means missing kernels for
  the GPU `gfx` target in the ROCm build

Option B: CTranslate2 ROCm (AMD fork)
- Complexity: high
- Chance of success: low to medium (30-50%)
- Speed: potentially very fast
- Notes: requires ROCm fork + custom build; not in nixpkgs
- Link (AMD blog): `https://rocm.blogs.amd.com/artificial-intelligence/ctranslate2/README.html`
- Link (ROCm fork): `https://github.com/ROCm/CTranslate2`

Option C: whisper.cpp with HIP
- Complexity: high
- Chance of success: medium (40-60%)
- Speed: good once working
- Notes: heavy packaging work in Nix, custom build flags

## Decision summary
- Torch+ROCm was tested but is not reliable across newer AMD GPUs (HIP errors).
- CTranslate2 ROCm and whisper.cpp remain possible, but both require heavier
  custom packaging work in Nix.
