"""Boost the two bundled cues by 30%, softly limiting peaks with no headroom."""

import argparse
from array import array
import math
import os
from pathlib import Path
import subprocess
import sys
from tempfile import TemporaryDirectory


FILES = ("prepare-blightfall.ogg", "prepare-reaper.ogg")
GAIN = 1.3
KNEE = 0.75
CEILING = 0.95
SAMPLE_RATE = 32000


def run_ffmpeg(args, *, input_data=None):
    return subprocess.run(
        ["ffmpeg", "-hide_banner", "-loglevel", "error", *args],
        input=input_data,
        capture_output=True,
        check=True,
    ).stdout


def boost(source, target):
    pcm = run_ffmpeg(["-i", str(source), "-f", "f32le", "-ac", "1", "-ar", str(SAMPLE_RATE), "pipe:1"])
    samples = array("f")
    samples.frombytes(pcm)
    limited = 0
    for index, sample in enumerate(samples):
        if not math.isfinite(sample):
            raise ValueError(f"Non-finite sample in {source}")
        gained = abs(sample) * GAIN
        if gained > KNEE:
            limited += 1
            gained = CEILING - (CEILING - KNEE) * math.exp(-(gained - KNEE) / (CEILING - KNEE))
        samples[index] = math.copysign(gained, sample)
    run_ffmpeg([
        "-f", "f32le", "-ar", str(SAMPLE_RATE), "-ac", "1", "-i", "pipe:0",
        "-c:a", "libvorbis", "-q:a", "5", "-map_metadata", "-1", "-y", str(target),
    ], input_data=samples.tobytes())
    print(f"{source.name}: boosted {len(samples)} samples; softly limited {limited} peaks")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source_dir", type=Path, help="Directory containing the original two OGG files")
    parser.add_argument("output_dir", type=Path, help="Different directory for boosted OGG files")
    args = parser.parse_args()
    source_dir = args.source_dir.resolve(strict=True)
    output_dir = args.output_dir.resolve(strict=True)
    if source_dir == output_dir:
        parser.error("source and output directories must differ to avoid stacking gain")
    if sys.byteorder != "little":
        parser.error("float PCM conversion requires a little-endian host")
    for name in FILES:
        if not (source_dir / name).is_file():
            parser.error(f"missing source file: {name}")
    with TemporaryDirectory(dir=output_dir) as temp_dir:
        temporary = Path(temp_dir)
        for name in FILES:
            boost(source_dir / name, temporary / name)
        for name in FILES:
            os.replace(temporary / name, output_dir / name)


if __name__ == "__main__":
    main()
