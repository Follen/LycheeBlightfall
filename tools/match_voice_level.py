"""Match a new cue's average level to the existing bundled cue, with peak headroom."""
import re
import subprocess
import sys
from pathlib import Path

def levels(path):
    run = subprocess.run(["ffmpeg", "-hide_banner", "-i", str(path), "-af", "volumedetect", "-f", "null", "-"], capture_output=True, text=True, check=True)
    return [float(re.search(key + r":\s*(-?[\d.]+) dB", run.stderr).group(1)) for key in ("mean_volume", "max_volume")]

target, reference = map(Path, sys.argv[1:3])
mean, peak = levels(target)
reference_mean, _ = levels(reference)
gain = min(reference_mean - mean, -1.0 - peak)
temporary = target.with_name(target.stem + "-level-match.ogg")
subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", str(target), "-af", f"volume={gain:.2f}dB", "-c:a", "libvorbis", "-q:a", "5", "-map_metadata", "-1", str(temporary)], check=True)
temporary.replace(target)
print(f"Voice matched: adjustment {gain:+.2f} dB; reference mean {reference_mean:.1f} dB")
