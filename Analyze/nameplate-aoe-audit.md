# 自动群怪分支与姓名板秘密值审计

2026-09-28，版本 0.2.0。用户要求只自动判断，已删除手动模式。

## 源码结论

固定 UI 源码 `09b9db7948abc9b9648dedaab51eb0cf3ee67b31`，PIN `PIN-45c29347fe416f791f8ba7c16488bad55275cf8c359a4bfef22550ee9ef72d34`。

- `NamePlateDocumentation.lua:36`：C_NamePlate.GetNamePlates 返回列表，未标秘密返回。
- `NamePlateManagerDocumentation.lua:117,138`：NAME_PLATE_UNIT_ADDED/REMOVED 的 unitToken 未标秘密载荷。
- `UnitDocumentation.lua:603,751,1856,2181`：UnitAffectingCombat、UnitCanAttack、UnitIsDeadOrGhost、UnitIsPlayer 未标秘密返回。SecretArguments=AllowedWhenUntainted 描述参数许可，不等于返回值是秘密。
- 同文件 3168：UnitThreatSituation 明确 SecretWhenUnitThreatStateRestricted，因此实现不读仇恨。
- `Blizzard_NamePlateBase.lua:29` 当前实现使用 unitToken；初始化也兼容 namePlateUnitToken。只接受公开的 nameplate 数字令牌，不读 GUID。

捕获：列表 CAP-b11c9027607f034790c51d724940b58e170529e5d6e90343c2b31cb33b07b8a7；进战 CAP-3ffe9f5efae5b68c700a57c3d6db3591ba70df0d8faccb62d25e321225f6a272；可攻击 CAP-3fe968d65fda3834f9d655dc05053188eca11142ab750572e252347a8ea78c6b；死亡 CAP-7ffa34360aa55ce48f09a5b44ef3286a788e30a905fe1559d190d1f265c4a66b；仇恨 CAP-8a4dab12c972a8e787584bcbc055bd576d8bd047ed8579445489a6f38c78cbb5。

## 实现

公开且可见的非玩家姓名板，活着、可攻击、处于战斗时计数；至少 3 个使用群怪分支。秘密值先判定，未知条目单独记录，不算敌人。列表不是完整战斗目标清单；关闭姓名板、超范围会漏数，进战不证明正在与自己的小队交战。

姓名板增删与 UNIT_FLAGS / UNIT_FACTION 更新单个条目；推算关键节点复核已知条目，未引入常驻轮询。重复增删不会累加或扣成负数。切专精停用时清空。

群怪不使用收割截止时间，采用突变截止时间；若观察到公开的乌拉特克贪婪之心使用（1297761），同时受其 20 秒增益限制。提前两个 GCD 推荐，每轮语音一次。其他饰品不纳入。单体沿用现有保守逻辑，并非完全复刻 SimC。

依据 SimC `4c7c73621e596419b5bd6faa5d68940a9c640379` 的 `ActionPriorityLists/default/deathknight_unholy.simc`。其 >=3 敌人分支以突变/饰品增益剩余不足 2 GCD 为触发条件，不要求收割仍在。

## 验证边界

41 项 Engine、47 项 Runtime、15 项 Loader、23 项姓名板计数离线断言通过；Lua 5.1 语法通过。测试包含秘密值哨兵、去重、敌人进战/死亡、3→2→3 切换、心脏限制以及实际施法清理。

再次被动检查正式服 12.1.0.69933 客户端 PID 31208，仍返回 busy / foreignOwner=true / journal.invalid_window_owner / inputReady=false。没有夺取其窗口、发送输入或启动新的 live operation。故尚无 M+ / 团本战斗的运行证据，不能将静态无秘密标注写成实测 NeverSecret。
