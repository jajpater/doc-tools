#!/usr/bin/env python3
import argparse
import json
import sys
from pathlib import Path
from typing import Iterable, List

from faster_whisper import WhisperModel
from tqdm import tqdm


def srt_time(t: float) -> str:
    h, m = divmod(int(t), 3600)
    m, s = divmod(m, 60)
    ms = int((t - int(t)) * 1000)
    return f"{h:02}:{m:02}:{s:02},{ms:03}"


def format_time(seconds: float) -> str:
    h = int(seconds // 3600)
    m = int((seconds % 3600) // 60)
    s = int(seconds % 60)
    return f"{h:02d}:{m:02d}:{s:02d}"


def write_org(segments, info, path: Path) -> None:
    with path.open("w", encoding="utf-8") as f:
        f.write("#+TITLE: Transcriptie\n")
        f.write(f"#+LANGUAGE: {info.language}\n")
        f.write(f"#+LANGUAGE_PROBABILITY: {info.language_probability:.3f}\n\n")

        for seg in segments:
            timestamp = format_time(seg.start)
            f.write(f"[{timestamp}] {seg.text.strip()}\n\n")


def write_md(segments, info, path: Path) -> None:
    with path.open("w", encoding="utf-8") as f:
        f.write("# Transcriptie\n\n")
        f.write(f"**Taal:** {info.language} (zekerheid: {info.language_probability:.1%})\n\n")
        f.write("---\n\n")

        for seg in segments:
            timestamp = format_time(seg.start)
            f.write(f"## [{timestamp}]\n\n{seg.text.strip()}\n\n")


def write_json(segments, info, path: Path) -> None:
    data = {
        "language": info.language,
        "language_probability": info.language_probability,
        "segments": [
            {
                "start": seg.start,
                "end": seg.end,
                "text": seg.text,
                "avg_logprob": seg.avg_logprob,
                "no_speech_prob": seg.no_speech_prob,
                "temperature": seg.temperature,
                "tokens": seg.tokens,
            }
            for seg in segments
        ],
    }
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")


def write_srt(segments, path: Path) -> None:
    with path.open("w", encoding="utf-8") as f:
        for i, seg in enumerate(segments, 1):
            f.write(f"{i}\n{srt_time(seg.start)} --> {srt_time(seg.end)}\n{seg.text.strip()}\n\n")


def write_vtt(segments, path: Path) -> None:
    with path.open("w", encoding="utf-8") as f:
        f.write("WEBVTT\n\n")
        for seg in segments:
            start = srt_time(seg.start).replace(",", ".")
            end = srt_time(seg.end).replace(",", ".")
            f.write(f"{start} --> {end}\n{seg.text.strip()}\n\n")


def parse_formats(values: Iterable[str]) -> List[str]:
    if not values:
        return ["org"]

    formats: List[str] = []
    for value in values:
        parts = [p.strip().lower() for p in value.split(",") if p.strip()]
        formats.extend(parts)

    if "all" in formats:
        return ["org", "md", "json", "srt", "vtt"]

    seen = set()
    deduped = []
    for fmt in formats:
        if fmt not in seen:
            seen.add(fmt)
            deduped.append(fmt)
    return deduped


def resolve_output_paths(
    audio_path: Path, output: str | None, formats: List[str]
) -> dict[str, Path]:
    ext_map = {
        "org": ".org",
        "md": ".md",
        "json": ".json",
        "srt": ".srt",
        "vtt": ".vtt",
    }

    if output:
        out_path = Path(output)
        if out_path.is_dir():
            base = out_path / audio_path.stem
            return {fmt: base.with_suffix(ext_map[fmt]) for fmt in formats}

        if out_path.suffix:
            if len(formats) == 1:
                return {formats[0]: out_path}
            base = out_path.with_suffix("")
            return {fmt: base.with_suffix(ext_map[fmt]) for fmt in formats}

        base = out_path
        return {fmt: base.with_suffix(ext_map[fmt]) for fmt in formats}

    base = audio_path.with_suffix("")
    return {fmt: base.with_suffix(ext_map[fmt]) for fmt in formats}


def pick_device(device: str, verbose: bool = False) -> str:
    if device == "rocm":
        if verbose:
            print("Device 'rocm' gekozen, gebruikt CUDA backend (ROCm build van PyTorch).")
        return "cuda"

    if device != "auto":
        return device

    try:
        import torch

        if torch.cuda.is_available():
            if verbose:
                print(f"GPU gevonden: {torch.cuda.get_device_name(0)}")
            return "cuda"
    except ImportError:
        if verbose:
            print("PyTorch niet gevonden, gebruik CPU.")

    if verbose:
        print("Geen CUDA beschikbaar, gebruik CPU.")
    return "cpu"


def transcribe(audio_path: Path, model_name: str, device: str, compute: str, vad_filter: bool):
    try:
        model = WhisperModel(model_name, device=device, compute_type=compute)
    except RuntimeError as e:
        if "libcublas" in str(e) or "CUDA" in str(e):
            print("CUDA niet beschikbaar, val terug op CPU...")
            device = "cpu"
            compute = "int8"
            model = WhisperModel(model_name, device=device, compute_type=compute)
        else:
            raise

    segments_iter, info = model.transcribe(str(audio_path), vad_filter=vad_filter)
    segments = []
    with tqdm(desc="Segmenten verwerken", unit=" seg") as pbar:
        for seg in segments_iter:
            segments.append(seg)
            pbar.update(1)
    return segments, info


def main() -> int:
    parser = argparse.ArgumentParser(description="Transcribe audio with faster-whisper")
    parser.add_argument("audio", help="Pad naar audiobestand (mp3/wav/...)")
    parser.add_argument(
        "-f",
        "--format",
        action="append",
        help="Output format: org, md, json, srt, vtt, all (mag meerdere keren of comma-separated)",
    )
    parser.add_argument("-o", "--output", help="Output pad (bestand, basisnaam of directory)")
    parser.add_argument("--model", default="large-v3", help="Modelnaam of pad (default: large-v3)")
    parser.add_argument("--device", default="auto", choices=["auto", "cpu", "cuda", "rocm"])
    parser.add_argument(
        "--compute-type",
        default=None,
        help="float16, int8_float16, int8, etc. (default: int8 op CPU, float16 op GPU)",
    )
    parser.add_argument("--no-vad", action="store_true", help="Schakel VAD filter uit")
    parser.add_argument("-v", "--verbose", action="store_true")
    args = parser.parse_args()

    audio_path = Path(args.audio).resolve()
    if not audio_path.exists():
        print(f"Error: Bestand niet gevonden: {audio_path}")
        return 1

    formats = parse_formats(args.format or [])
    allowed = {"org", "md", "json", "srt", "vtt"}
    unknown = [f for f in formats if f not in allowed]
    if unknown:
        print(f"Onbekende format(s): {', '.join(unknown)}")
        return 1

    output_paths = resolve_output_paths(audio_path, args.output, formats)

    device = pick_device(args.device, verbose=args.verbose)
    compute = args.compute_type or ("int8" if device == "cpu" else "float16")

    if args.verbose:
        print(f"Model laden: {args.model} op {device} ({compute})...")

    segments, info = transcribe(
        audio_path, args.model, device, compute, vad_filter=not args.no_vad
    )

    if args.verbose:
        print("Bestanden schrijven...")

    for fmt in formats:
        out_path = output_paths[fmt]
        if fmt == "org":
            write_org(segments, info, out_path)
        elif fmt == "md":
            write_md(segments, info, out_path)
        elif fmt == "json":
            write_json(segments, info, out_path)
        elif fmt == "srt":
            write_srt(segments, out_path)
        elif fmt == "vtt":
            write_vtt(segments, out_path)

    print("✓ Klaar:")
    for fmt in formats:
        print(f"  {fmt}: {output_paths[fmt]}")
    print(f"  Taal: {info.language} (p={info.language_probability:.3f})")
    print(f"  Segmenten: {len(segments)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
