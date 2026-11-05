# wtchet

从零重写的 WeChat Rootless 插件项目。当前里程碑只实现设置中心 UI 雏形，不实现具体微信功能。

## 0.1.0 设置中心原型
- 对照参考截图搭建双列磨砂卡片设置主页。
- 顶部标题与日志占位入口。
- 总开关、磨砂开关（当前仅为本地 UI 状态）。
- 24 个设置入口及独立占位子页面。
- 搜索设置项。
- 微信内临时悬浮入口用于打开设置主页。

## 当前明确不包含
- 不接管微信会话列表。
- 不实现分组、气泡、主题下载或其他业务功能。
- 不依赖旧项目 WCGlass / WeChatGlassGroups 的代码。

## 构建
需要 Theos 与 iOS 15.0 SDK：

```sh
make package THEOS_PACKAGE_SCHEME=rootless
```

包标识：`com.reaaut.wtchet`
