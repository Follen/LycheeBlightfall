"""Generate the bundled alert. The API key is accepted only via env/getpass."""
import getpass
import argparse
import json
import os
from pathlib import Path
import subprocess
import sys
import urllib.request

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument("--cue", choices=["blightfall", "reaper"], default="blightfall")
args = parser.parse_args()
key = os.environ.get("MINIMAX_API_KEY") or getpass.getpass("MiniMax API key (hidden): ")
payload = {
    "model": "speech-2.8-hd", "text": "准备收割" if args.cue == "reaper" else "准备吞病", "stream": False,
    "voice_setting": {"voice_id": "Chinese (Mandarin)_Warm_Girl", "speed": 1.1, "vol": 1, "pitch": 0},
    "audio_setting": {"sample_rate": 32000, "bitrate": 128000, "format": "mp3", "channel": 1},
    "output_format": "hex", "language_boost": "Chinese",
}
request = urllib.request.Request("https://api.minimax.cn/v1/t2a_v2",
    data=json.dumps(payload).encode(), headers={"Authorization": "Bearer " + key, "Content-Type": "application/json"})
with urllib.request.urlopen(request, timeout=90) as response:
    result = json.load(response)
del key, request
status = result.get("base_resp", {})
if status.get("status_code") != 0:
    raise SystemExit("MiniMax rejected synthesis; status code: " + str(status.get("status_code")))
audio = bytes.fromhex(result["data"]["audio"])
out = root / ("addon/LycheeBlightfall_Core/Media/prepare-" + args.cue + ".ogg")
subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", "pipe:0",
    "-af", "volume=2.4", "-c:a", "libvorbis", "-q:a", "5", "-map_metadata", "-1", str(out)], input=audio, check=True)
if args.cue == "reaper":
    subprocess.run([sys.executable, str(root / "tools/match_voice_level.py"), str(out),
        str(root / "addon/LycheeBlightfall_Core/Media/prepare-blightfall.ogg")], check=True)
print("Generated:", out.name, "bytes:", out.stat().st_size,
      "source duration ms:", result.get("extra_info", {}).get("audio_length"))
