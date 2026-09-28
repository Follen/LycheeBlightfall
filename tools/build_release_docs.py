"""Build player READMEs and publishing HTML from the bilingual release copy."""
from pathlib import Path
import html
import json
import re

ROOT = Path(__file__).resolve().parents[1]
PUB = ROOT / "docs/publishing"
VERSION = re.search(r"^## Version: (.+)$", (ROOT / "addon/LycheeBlightfall/LycheeBlightfall.toc").read_text(encoding="utf-8"), re.M).group(1).strip()

def render_markdown(source):
    blocks, listing, table = [], False, False
    for line in source.splitlines():
        if not line.startswith('|') and table:
            blocks.append('</tbody></table>'); table = False
        if not line.startswith("- ") and listing:
            blocks.append("</ul>"); listing = False
        if not line.strip():
            continue
        value = html.escape(line)
        if line.startswith('|'):
            cells = [cell.strip() for cell in line.strip('|').split('|')]
            if all(re.fullmatch(r':?-+:?', cell) for cell in cells):
                continue
            tag = 'td' if table else 'th'
            if not table:
                blocks.append('<table><tbody>'); table = True
            blocks.append('<tr>' + ''.join(f'<{tag}>'+html.escape(c)+f'</{tag}>' for c in cells)+'</tr>')
        elif re.fullmatch(r'!\[.*\]\(https://[^ ]+\)', line):
            alt, url = re.fullmatch(r'!\[(.*)\]\((https://[^ ]+)\)', line).groups()
            blocks.append('<p><img style="max-width:100%;height:auto" src="'+html.escape(url,quote=True)+'" alt="'+html.escape(alt,quote=True)+'"></p>')
        elif line.startswith("## "):
            blocks.append("<h2>" + html.escape(line[3:]) + "</h2>")
        elif line.startswith("# "):
            blocks.append("<h1>" + html.escape(line[2:]) + "</h1>")
        elif line.startswith("- "):
            if not listing:
                blocks.append("<ul>"); listing = True
            blocks.append("<li>" + html.escape(line[2:]) + "</li>")
        else:
            blocks.append("<p>" + value + "</p>")
    if listing:
        blocks.append("</ul>")
    if table:
        blocks.append('</tbody></table>')
    return "\n".join(blocks) + "\n"

for lang, filename in [("zh-CN", "README.md"), ("en", "README.en.md")]:
    source = (PUB / f"description.{lang}.md").read_text(encoding="utf-8")
    (PUB / f"description.{lang}.html").write_text(render_markdown(source), encoding="utf-8")
    title, body = source.split("\n", 1)
    nav = "[English](README.en.md) · [更新日志](Changelog.md)" if lang == "zh-CN" else "[简体中文](README.md) · [Changelog](Changelog.en.md)"
    screenshots = "## 游戏内截图\n\n以下三张为玩家提供的原始截图；顶部封面为宣传图。" if lang == "zh-CN" else "## In-game screenshots\n\nThese three images are the player's supplied screenshots; the cover is a promotional image."
    readme = title + "\n\n" + nav + "\n\n![Cover](docs/media/release-cover.png)\n" + body
    readme += "\n" + screenshots + "\n\n![Combat](docs/media/combat.png)\n\n![Settings](docs/media/settings.png)\n\n![Positioning](docs/media/positioning.png)\n"
    (ROOT / filename).write_text(readme, encoding="utf-8")

metadata = {
    "name": "[荔枝]智能吞病收割提醒", "name_en": "Lychee Blightfall", "version": VERSION,
    "summary_zh": "萨莱因邪 DK 收割与吞病语音倒计时，乌心分支与单体时机经 27.9 万次模拟筛选、复测。",
    "summary_en": "Soul Reaper and Blightfall cues for San'layn Unholy DKs, with single-target timings evaluated across 279,000 simulations.",
    "branch": "retail", "interface": 120100, "game_version": "12.1.0",
    "repository": "https://github.com/Follen/LycheeBlightfall",
    "package": f"dist/LycheeBlightfall-{VERSION}.zip", "cover": "docs/media/release-cover.png",
    "logo": "docs/media/logo.png",
    "screenshots": ["docs/media/combat.png", "docs/media/settings.png", "docs/media/positioning.png"],
}
target = PUB / "metadata.json"
if target.exists():
    old = json.loads(target.read_text(encoding="utf-8"))
    if "platforms" in old:
        metadata["platforms"] = old["platforms"]
target.write_text(json.dumps(metadata, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
(PUB / "summary.zh-CN.txt").write_text(metadata["summary_zh"] + "\n", encoding="utf-8")
(PUB / "summary.en.txt").write_text(metadata["summary_en"] + "\n", encoding="utf-8")
for lang, filename in [("zh-CN", "Changelog.md"), ("en", "Changelog.en.md")]:
    changelog = (ROOT / filename).read_text(encoding="utf-8")
    section = changelog.split("## " + VERSION + " — ", 1)[1].split("\n", 1)[1].split("\n## ", 1)[0]
    notes = [line[2:] for line in section.splitlines() if line.startswith("- ")]
    (PUB / f"changelog.{lang}.txt").write_bytes(("\r\n".join("• " + note for note in notes) + "\r\n").encode("utf-8"))
    (PUB / f"changelog.{lang}.html").write_text("".join("<p>" + html.escape(note) + "</p>" for note in notes), encoding="utf-8")
print("Built bilingual publishing copy and READMEs.")
