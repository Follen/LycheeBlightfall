"""Create a clean install ZIP from the two addon folders only."""
import hashlib
from pathlib import Path
import zipfile

root = Path(__file__).resolve().parents[1]
source = root / "addon"
target = root / "dist/LycheeBlightfall-1.0.0.zip"
target.parent.mkdir(exist_ok=True)
files = sorted(p for p in source.rglob("*") if p.is_file() and p.name != "ncc.json" and not any(part.startswith(".") for part in p.relative_to(source).parts))
assert {p.relative_to(source).parts[0] for p in files} == {"LycheeBlightfall", "LycheeBlightfall_Core"}
for file in files:
    if file.suffix.lower() in {".lua", ".toc", ".txt", ".html"}:
        assert b"sk-api-" not in file.read_bytes(), "Credential marker in " + file.name
for folder in ("LycheeBlightfall", "LycheeBlightfall_Core"):
    toc = source / folder / (folder + ".toc")
    for line in toc.read_text(encoding="utf-8").splitlines():
        entry = line.strip()
        if entry and not entry.startswith("#"):
            assert (toc.parent / entry.replace("\\", "/")).is_file(), "Missing TOC file: " + entry
assert (source / "LycheeBlightfall_Core/Media/prepare-blightfall.ogg").read_bytes().startswith(b"OggS")
with zipfile.ZipFile(target, "w", zipfile.ZIP_DEFLATED) as archive:
    for file in files:
        archive.write(file, file.relative_to(source).as_posix())
with zipfile.ZipFile(target) as archive:
    assert archive.testzip() is None
digest = hashlib.sha256(target.read_bytes()).hexdigest()
target.with_suffix(".zip.sha256").write_text(digest + "  " + target.name + "\n", encoding="ascii")
print(f"Packaged {len(files)} files, {target.stat().st_size} bytes: {target}")
print("SHA256:", digest)
