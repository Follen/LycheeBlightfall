# 末日突降“括号”读取路径

2026-09-28。以下为前期研究记录。后续 0.3.0 已接入有公开值检查及回退的事件推断，见 `visceral-strength-audit.md`。已找到 SAT 使用显示/隐藏钩子的具体实现，不能把缺少实测说成不能监控；正式服目标场景运行可用性仍未验证。

当前中文名称：49530/81340 = 末日突降。黑暗降临 451026/451032 是不同技能，之前对话将其当作邪 DK 主动技能解释不正确。

数据 PIN `PIN-844e56206c15b8a81da4ca386208008d855bf69b077af8b0cbcbd6adeb14657a`：SpellActivationOverlay 记录 ID120，SpellID81340，OverlayFileDataID450932。捕获 CAP-3a554fb8a226091fdb0a37db21f6d0f114d36310b6a4e4e2f765a4771f05542a。

固定 UI 源码 `09b9db7948abc9b9648dedaab51eb0cf3ee67b31`：

- SpellActivationOverlayDocumentation.lua：SPELL_ACTIVATION_OVERLAY_SHOW/HIDE 的 spellID 未标秘密载荷。HIDE 的 ID 可为 nil，表示全部隐藏，不能只处理 81340。
- Blizzard_FrameXML/SpellActivationOverlay.lua：OnEvent 先收到 SHOW，再根据 displaySpellActivationOverlays 决定是否显示框体。直接监听事件能避开该 Lua 显示开关；不据此保证所有客户端内部设置下都发送事件。
- 同文件 ShowOverlay / GetOverlay：框体按 spellID/position 分组且由 pool 复用；单个框体生命周期不等于固定技能生命周期。
- HideOverlays 开始淡出，动画 OnFinished 才 ReleaseOverlay，因此 OnHide 晚于触发消失事件。父框体隐藏和可视设置也不能等同于真实光环移除。
- IsSpellOverlayed 查询属于可研究的技能高亮入口，不直接假设其 spellID 与屏幕括号的 aura ID 相同。

候选验证路径是 SHOW/HIDE 事件，先 issecretvalue 再比较 81340。必须先证明第三方框体能注册、在相应副本战斗场景收到事件、且 ID 为公开值。只有满足这些条件，才可用它记录提示状态；不能据此读取层数、剩余时间，也不能将消失一律解释为成功消耗。若要推断脏腑之力，应结合相关成功施法和事件顺序实测；重新触发、过期、重载和其他清除都要处理。

源码捕获：CAP-719f797897579e51fe0e1ef0c355242ddcca4540d1eb92e14ebddf1e65470345、CAP-0b1c3ae3ef10e9eef601247e25134b809f7112384529db4cc24c3ce47e23901a。

再次检查 XML 与发布 TOC：模板和父框体未显式标 forbidden，主线 TOC 加载这组 Lua/XML。此结果不证明 C++ 事件分发、运行时框体状态、钩子调用权限以及战斗条件。不能从“暴雪内部代码可以读”推出“普通插件也可以读”。

最新被动清单中正式服已不再运行；仅存在 5.5.4.69934 怀旧服和 1.60.1.70009 测试服，它们不能用于证明正式服行为。没有发送输入、创建 live operation 或待清理的游戏报告。

已准备 `tools/probes/sudden-doom-events.lua`，但未执行。它只测试普通插件事件注册与公开末日突降事件，明确区分无样本与不可读取；不挂钩、不修改暴雪框体。OnShow/OnHide 路线本身仍未验证。需要正式服邪 DK 在实际目标场景触发末日突降后才能继续判定。

## SAT 实现参考

本机正式服 `D:/Game/World of Warcraft/_retail_/Interface/AddOns/SpellAlertTimer`，TOC 标题 SpellAlertTimer(SAT)，版本 20260901。用户称 AST，当前找到的对应插件是 SAT。

- `SpellAlertTimer.lua:132` 对 SpellActivationOverlayFrame.ShowOverlay 使用 hooksecurefunc，接收 spellID 并获取对应 overlay；139 行挂钩 HideOverlays，按 spellID 隐藏自己创建的容器；153 行处理 HideAllOverlays。它没有通过括号框体的 OnShow/OnHide 实现这部分监控。
- 83–114 行创建 CustomAuraContainerTemplate，按 includeSpellIDs 过滤玩家光环，调用 SetDurationCooldown 让暴雪容器负责倒计时显示。此实现没有读取普通剩余秒数来做推荐判断。
- 固定暴雪源码 `Blizzard_AuraContainer/Blizzard_CustomAuraButton.lua:139–148` 中，SetDurationCooldown 对 cooldown 设置 SecretAspect.Cooldown 和 SecretAspect.Shown。这说明不能把 SAT 的倒计时显示当成普通插件获得了公开时长的证据。捕获 CAP-7468a08eb30701af7be852e3ab59bd4013cd4778a1061f793db871d069c6de1a。
- 由此可把“监听括号出现/消失”提升为有现成插件实现依据的方案；仍不能从源码或安装状态宣称已经验证 M+/团本战斗，也不能把消失直接视为末日突降被消耗。不要混淆暴雪原始 overlay 和 SAT 创建的受限光环倒计时控件。
