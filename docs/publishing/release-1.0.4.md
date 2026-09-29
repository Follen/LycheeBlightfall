## 1.0.4 — 2026-09-29

- 调整字号、提示音、提前量时保留当前爆发计时，不再中断本轮提醒，也不会重复播报。
- 倒计时归零后停止刷新，保留准备提示；时间后推时自动恢复倒计时。
- 减少公共冷却、括号及姓名板事件中的重复姓名板扫描。
- 修复旧公共冷却估计恢复时，偶尔未及时更新提示时间的问题。
- 统一发布包及平台版本为 1.0.4，收割与吞病的既定判断规则保持不变。

## 1.0.4 — 2026-09-29

- Keep the current burst timeline when changing font size, sounds, or lead times, without replaying announced cues.
- Stop display updates at zero while keeping the action prompt visible; resume if the target moves into the future.
- Avoid redundant nameplate scans on GCD, proc-overlay, and incremental nameplate events.
- Fix missed countdown refreshes when a previously observed GCD duration becomes fresh again.
- Align package and platform versions at 1.0.4; existing Soul Reaper and Blightfall timing rules are unchanged.

Validation: 433 offline Lua 5.1 assertions passed. Live combat verification remains separate.
