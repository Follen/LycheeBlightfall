# 0.3.1 设置页空白修复

用户截图显示插件类别存在，选中后画布空白。旧代码将所有控件构建放在 OnShow，且注册时不 Hide 初始已显示的无父框体；切入已经可见的 Canvas 时没有可见性变化，OnShow 不一定触发，OnRefresh 又会因未构建而直接返回。

依据：UI commit `09b9db7948abc9b9648dedaab51eb0cf3ee67b31`，`Blizzard_SettingsPanel.lua:899–928` 的 DisplayLayout 先 SetParent/SetPoint/Show，再 CallRefreshOnFrame，最后显示 Canvas。捕获 `CAP-6f42ff830c4b428ac745ae86a0f37b108d23c60205e99b431c6d41a906f70900`。

`tests/settings_test.lua` 执行真实 Settings.lua，并模拟上述框体状态/选择顺序。旧代码报 `selected settings canvas must contain its controls: expected true, got false`。修复后两个 Canvas 初始可见状态及重新打开场景均通过，还检查控件数量、保存值、无重复构建、天赋刷新不提前构建页面。

修复：注册面板时明确 Hide；OnShow 与 OnRefresh 均确保构建；完成构建后才设置 built。普通天赋状态刷新不强制构建，保留懒加载。未改变吞病推荐算法。

验证：Settings 18、Engine 83、Runtime 65、Loader 15、Enemies 23 项编号断言通过。正式服两个运行窗口被工具报告为 foreignOwner / journal.invalid_window_owner，未接管、未发送输入或强制重载；本次游戏内展示与错误栈尚未读取。磁盘更新不代表当前会话已加载修复。
