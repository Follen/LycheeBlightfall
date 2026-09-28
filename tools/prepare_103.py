from pathlib import Path
import json, shutil
root=Path(__file__).resolve().parents[1]
p=root/'docs/publishing';w=root/'Analyze/reaper-opt-20260928'
notes={'Changelog.md':'''## 1.0.3 — 2026-09-28

- 乌心这轮：单体和群怪均在乌心剩约 9 秒时提示收割。
- 没乌心：单体保留突变后约 7 秒的 SimC 默认节奏，群怪不额外等待。
- 修正单体未打收割便提前催吞病的问题，以实际收割成功后的窗口为准。
- 新增完整判断规则及 27.9 万次模拟说明，展示本版方案的独立复测图表。

''','Changelog.en.md':'''## 1.0.3 — 2026-09-28

- With Heart, prepare Soul Reaper with about 9 seconds remaining in both ST and AoE.
- Without Heart, retain the default 7-second ST delay; AoE adds no extra wait.
- Wait for actual Soul Reaper before issuing single-target Blightfall cues.
- Document timing rules and the selected policy's results from 279,000 simulations.

'''}
for name,section in notes.items():
    f=root/name;s=f.read_text(encoding='utf-8')
    if '## 1.0.3' not in s:
        head,rest=s.split('\n',1);f.write_text(head+'\n\n'+section+rest.lstrip(),encoding='utf-8')
(p/'release-1.0.3.md').write_text(notes['Changelog.md']+'更新后 /reload。\n\n'+notes['Changelog.en.md'],encoding='utf-8')
shutil.copy2(p/'release-1.0.3.md',p/'github-release-notes.md')
d=root/'docs/simulation'
for name in ['validation-pooled.json','validation-pooled.csv','validation.png','heart9_margin2.simc']:
    shutil.copy2(w/name,d/name)
(d/'README.md').write_text('''# 1.0.3 模拟依据

本版采用 heart9_margin2.simc：有乌心剩 9 秒收割，无乌心保留默认单体约 7 秒，吞病保留 2 GCD。validation-pooled.csv 中同名行对应本版。其他候选（例如 boundary_small0）的更高分未用于本版本。

93 组共 279000 次有效模拟。每组请求 3001 次，剔除一轮预热，报告 count=3000。结果为完整 APL 的单体伤害，不是 AOE 或插件实战增伤保证。REPORT.md 保留搜索时的原始结论，包含未采用候选。

复现：使用官方预编译 SimC 1210-01 / 4c7c736，分别输入 default.simc、heart9_margin2.simc，参数如下：

```text
iterations=3001 threads=1 deterministic=1 target_error=0 max_time=300 vary_combat_length=0 fixed_time=1 optimal_raid=1 desired_targets=1 seed=51001 enemy=Target enemy_fixed_health_percentage=0 json2=result.json
```

300 秒种子 51001/51002/51003；180 秒 52001；450 秒 53001。Git 收录汇总与关键输入，完整原始 JSON/TXT 日志保留于本地 Analyze/reaper-opt-20260928。附带搜索脚本为原始工作区脚本，依赖该工作区的原始 manifest 和输入；上述命令可独立复现本版组合。
''',encoding='utf-8')
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.font_manager import FontProperties
plt.rcParams['font.family']=FontProperties(fname='C:/Windows/Fonts/msyh.ttc').get_name()
plt.rcParams['axes.unicode_minus']=False
rs=sorted([x for x in json.loads((w/'validation-pooled.json').read_text()) if x['name']=='heart9_margin2'],key=lambda x:x['duration'])
fig,ax=plt.subplots(figsize=(8,5.6),layout='constrained')
fig.patch.set_facecolor('#faf8f6');ax.set_facecolor('#faf8f6')
ax.barh(range(3),[x['delta_pct'] for x in rs],color='#d53c49',height=.44)
ax.errorbar([x['delta_pct'] for x in rs],range(3),xerr=[x['delta_ci95_pct'] for x in rs],fmt='none',ecolor='#402d30',capsize=5)
ax.set_yticks(range(3),['3 分钟 · 每方案 3000 次','5 分钟 · 每方案 9000 次','7.5 分钟 · 每方案 3000 次']);ax.invert_yaxis()
for y,x in enumerate(rs):
    ax.text(x['delta_pct']+x['delta_ci95_pct']+.025,y,f"+{x['delta_pct']:.2f}%",va='center',fontsize=14,fontweight='bold')
ax.set_xlim(0,1.3);ax.set_xlabel('整场平均总伤害提升（相对 SimC 默认）')
ax.spines[['top','right','left']].set_visible(False);ax.grid(axis='x',alpha=.15);ax.set_axisbelow(True)
fig.suptitle('1.0.3 选用方案 · 单体独立复测',fontsize=20,fontweight='bold')
ax.set_title('筛选及复测共 27.9 万次 · 93 组\n有乌心剩 9 秒收割；无乌心保留默认约 7 秒\n吞病保留 2 个公共冷却 · 萨莱因＋乌心模板',fontsize=11,pad=18)
fig.text(.5,-.055,'误差线：差值近似 95% 区间；不是插件实战收益保证，未测试 AOE。',ha='center',fontsize=9)
fig.savefig(root/'docs/media/simc-results.png',dpi=160,bbox_inches='tight');plt.close(fig)
