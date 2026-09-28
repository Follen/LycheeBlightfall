# 1.0.3 模拟依据

本版采用 heart9_margin2.simc：有乌心剩 9 秒收割，无乌心保留默认单体约 7 秒，吞病保留 2 GCD。validation-pooled.csv 中同名行对应本版。其他候选（例如 boundary_small0）的更高分未用于本版本。

93 组共 279000 次有效模拟。每组请求 3001 次，剔除一轮预热，报告 count=3000。结果为完整 APL 的单体伤害，不是 AOE 或插件实战增伤保证。REPORT.md 保留搜索时的原始结论，包含未采用候选。

复现：使用官方预编译 SimC 1210-01 / 4c7c736，分别输入 default.simc、heart9_margin2.simc，参数如下：

```text
iterations=3001 threads=1 deterministic=1 target_error=0 max_time=300 vary_combat_length=0 fixed_time=1 optimal_raid=1 desired_targets=1 seed=51001 enemy=Target enemy_fixed_health_percentage=0 json2=result.json
```

300 秒种子 51001/51002/51003；180 秒 52001；450 秒 53001。Git 收录汇总与关键输入，完整原始 JSON/TXT 日志保留于本地 Analyze/reaper-opt-20260928。附带搜索脚本为原始工作区脚本，依赖该工作区的原始 manifest 和输入；上述命令可独立复现本版组合。
