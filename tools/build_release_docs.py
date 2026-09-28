"""Build player READMEs and publishing HTML from the bilingual release copy."""
from pathlib import Path
import html
import json

ROOT = Path(__file__).resolve().parents[1]
PUB = ROOT / "docs/publishing"

def render_markdown(source):
    blocks, listing = [], False
    for line in source.splitlines():
        if not line.startswith("- ") and listing:
            blocks.append("</ul>"); listing = False
        if not line.strip():
            continue
        value = html.escape(line)
        if line.startswith("## "):
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
    "name": "荔枝邪DK吞病", "name_en": "Lychee Blightfall", "version": "1.0.0",
    "summary_zh": "萨莱因邪 DK 吞病倒计时与语音提醒，随施法更新建议时间，自动区分单体和群怪。",
    "summary_en": "A dynamic Blightfall countdown and voice reminder for San'layn Unholy Death Knights, with automatic single-target and AoE branches.",
    "branch": "retail", "interface": 120100, "game_version": "12.1.0",
    "repository": "https://github.com/Follen/LycheeBlightfall",
    "package": "dist/LycheeBlightfall-1.0.0.zip", "cover": "docs/media/release-cover.png",
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
(PUB / "changelog.zh-CN.txt").write_text("1.0.0 首次正式发布。\n萨莱因邪 DK 动态吞病倒计时与语音提醒。\n自动判断单体和群怪；默认提前 3 秒，文字和语音可分别设置。\n支持透明提示、拖动定位、字号与 SharedMedia 音效选择。\n设置整合进暴雪插件选项。\n", encoding="utf-8")
(PUB / "changelog.zh-CN.html").write_text("<p>1.0.0 首次正式发布。</p><p>萨莱因邪 DK 动态吞病倒计时与语音提醒，自动判断单体和群怪。</p><p>默认提前 3 秒，文字和语音可分别设置。支持透明提示、拖动定位、字号与 SharedMedia 音效选择。</p><p>设置整合进暴雪插件选项。</p>", encoding="utf-8")
print("Built bilingual publishing copy and READMEs.")
