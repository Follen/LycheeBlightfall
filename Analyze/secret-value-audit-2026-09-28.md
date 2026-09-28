# 萨莱因邪 DK 吞病提醒：秘密值审计

日期：2026-09-28。范围：正式服、主目标、仅黑暗突变与灵魂收割；不实现插件。

## 固定证据

- 游戏：12.1.0.69933，zhCN，D:/Game/World of Warcraft/_retail_。
- 数据快照：PIN-844e56206c15b8a81da4ca386208008d855bf69b077af8b0cbcbd6adeb14657a。
- 官方 UI 源码：09b9db7948abc9b9648dedaab51eb0cf3ee67b31，快照 PIN-45c29347fe416f791f8ba7c16488bad55275cf8c359a4bfef22550ee9ef72d34。
- 本地 zhCN DBCache 捕获：CAP-ffbac4b667de6699b668505064c95b5ee1c421577efa90da660b03212de7d66a。
- 显式 Hotfix 覆盖查询：CAP-016ffd556609b1efadc9e00e3f29b41312f0677866f9fbc6b0235fea936171ec。所列记录未被该缓存覆盖。这不证明服务器 Hotfix 覆盖完整。
- SpellMisc 存在其他缺钥加密分区，整表覆盖为 partial；本文所列记录已返回，不能将该查询称为整表完整审计。
- SimC：4c7c73621e596419b5bd6faa5d68940a9c640379。

## 已确认的规则

1. UNIT_SPELLCAST_SUCCEEDED 受 SecretWhenUnitSpellCastRestricted 控制。官方谓词说明 player/pet 默认豁免，单个法术的 always/never 标记优先。所查黑暗突变 1233448、收割 343294、死亡缠绕 47541、传染 207317、替换缠绕 1242174、吞病 1271967 没有 always-secret cast 标记。应只注册 player，并在比较或使用 castGUID 去重前检查秘密值。
2. 光环在 combat、encounter、challenge mode 或 PvP 限制下通常保密；单个法术例外优先。1235391/63560 黑暗突变、377588/377589 食尸鬼狂热、1241521 收割、434159 脏腑之力、1271975 吞病可用光环的 Attributes[15] 均为 0，无 aura-never-secret 豁免。
3. GetPlayerAuraBySpellID、GetUnitAuraBySpellID 的 RequiresNonSecretAura 前置条件会在光环保密时返回无值。nil 不等于 Buff 已消失，不可用 nil 覆盖推算状态。
4. GCD 法术 61304：SpellMisc ID 41934，Attributes[15] = 0x80000000（有符号值 -2147483648），元数据名 COOLDOWN_NEVER_SECRET。可据此设计读取真实 GCD 的路径；运行时仍需验证返回字段非秘密值、duration > 0。空闲 duration=0 不能当作真实 GCD 长度。
5. SpellCooldownInfo.isOnGCD 明确 NeverSecret，但文档要求在 SPELL_UPDATE_COOLDOWN 响应中使用。它仅说明是否在 GCD 上，本身不是剩余时间。
6. C_Spell.GetOverrideSpell 无秘密返回标注；结合 1271975 的动作替换记录，有望通过 1233448 -> 1271967 校验吞病是否仍可用。属于源码支持的候选校验路径，尚无本次战斗运行验证，不能代替疾病/目标状态。
7. UnitSpellHaste 受 SecretWhenUnitStatsRestricted 控制，不能无条件用急速重算 GCD。
8. UNIT_SPELLCAST_SENT 的 target 字段为 ConditionalSecret；自己的成功施法事件没有命中确认。不能据此声称已精确确认主目标收割实际存在。

官方源码：
- [秘密谓词](https://github.com/Gethe/wow-ui-source/blob/09b9db7948abc9b9648dedaab51eb0cf3ee67b31/Interface/AddOns/Blizzard_APIDocumentationGenerated/SecretPredicatesDocumentation.lua)
- [秘密值查询接口](https://github.com/Gethe/wow-ui-source/blob/09b9db7948abc9b9648dedaab51eb0cf3ee67b31/Interface/AddOns/Blizzard_APIDocumentationGenerated/SecretPredicateAPIDocumentation.lua)
- [法术接口](https://github.com/Gethe/wow-ui-source/blob/09b9db7948abc9b9648dedaab51eb0cf3ee67b31/Interface/AddOns/Blizzard_APIDocumentationGenerated/SpellDocumentation.lua)
- [冷却字段](https://github.com/Gethe/wow-ui-source/blob/09b9db7948abc9b9648dedaab51eb0cf3ee67b31/Interface/AddOns/Blizzard_APIDocumentationGenerated/SpellSharedDocumentation.lua)

## 对方案的修正

- “固定 2.5 秒就是最优余量”没有依据。优先用最近一次有效公开 GCD 的两倍，参照 SimC 的两个 GCD 窗口；无有效观测时只能标记为估计并使用保守回退。
- 主目标收割逻辑应检查对应天赋（SimC 单体分支要求 Reaping + Soul Reaper），且本轮已记录有效施放；缺失时使用 DT 推算保底。不能伪称完全复刻 SimC：目标疾病、命中、免疫和未来行为未知。
- 在公开成功施法上推算 DT 初始时长及续时；替换缠绕也计入，同一次施法不能连同其伤害子事件重复累加。
- 默认文字和声音均提前建议出手时刻 3 秒。按用户最后修订，提示后也持续重算，不冻结出手时刻；文字出现后保持可见、每轮语音仅一次。倒计时可以随续时增加。
- 收割已观察到时，取突变与收割较早的结束时间为上限，不能通过延长突变把推荐推到收割之后。2 GCD 仍是 APL 启发的余量，不是完整 DPS 最优化证明。
- 吞病替换状态仅作为研究候选保留；用户已决定不纳入插件。清理依据自己的吞病成功施法及推算窗口结束。
- 查询按事件及关键节点触发；不轮询光环。只在候选爆发阶段处理 GCD 冷却事件；UI 显示时短暂更新数字，隐藏即停。

## 本次运行验证边界

仅做了被动窗口清单，没有发送游戏输入。唯一运行中的 12.1.0.69933 窗口返回 busy / foreignOwner=true / journal.invalid_window_owner / inputReady=false，不能接管或清除别的操作。

因此未验证大秘境/团本战斗中的实际事件字段、61304 冷却数值、替换技能返回和推算误差。没有创建需要恢复/清理的 live operation，也没有安装插件。

下一次有可用且已授权的客户端场景时，最小测试应只记录所需字段的 issecretvalue 标记及允许读取的公开数值，对比一轮 DT、普通/替换缠绕、传染、收割和吞病；禁止读取或序列化秘密值。普通脱战结果不能替代副本限制场景结果。
