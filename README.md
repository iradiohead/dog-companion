# 狗狗伙伴 (Dog Companion)

在 iPhone 上养一只属于你的专注伙伴：拍一张真狗照片，AI 生成漫画形象并抠图，然后它会在房间里陪你番茄钟专注。

灵感来自 [Cat On Chair](https://catonchair.app/)，但狗狗来自你自己的照片。

## 环境要求

- macOS + Xcode 15+
- **iPhone / iPad**：iOS 17+
- **MacBook**：macOS 14+（通过 Mac Catalyst 运行）
- [阿里云百炼](https://www.aliyun.com/product/bailian) 账号与 API Key（新用户有免费额度）

## 快速开始

### 1. 打开项目

```bash
open DogCompanion/DogCompanion.xcodeproj
```

### 2. 配置 API Key

```bash
cp DogCompanion/DogCompanion/Secrets.plist.example DogCompanion/DogCompanion/Secrets.plist
```

1. 登录 [百炼控制台](https://bailian.console.aliyun.com/)，开通服务
2. 在「API Key 管理」创建 Key
3. 编辑 `Secrets.plist`：

```xml
<key>DASHSCOPE_API_KEY</key>
<string>sk-xxxxxxxx</string>
```

> `Secrets.plist` 已在 `.gitignore` 中，不会提交到 Git。  
> 新用户开通百炼后 **90 天内可免费生成约 50 张图**（以控制台为准）。

### 3. 配置签名

在 Xcode 中选择 **DogCompanion** target → **Signing & Capabilities** → 勾选 **Automatically manage signing** → 选择你的 **Development Team**。

### 4. 运行

**iPhone / 模拟器：** 选择真机或模拟器，按 `Cmd + R`。

**MacBook：** 在 Xcode 顶部设备菜单选择 **My Mac (Mac Catalyst)**，然后 `Cmd + R`。Mac 版从相册/文件选图，无拍照按钮。

> **注意**：数据模型已更新。若从旧版升级，请删除 App 后重新安装。

## 核心功能

| 功能 | 说明 |
|------|------|
| 照片 → 漫画 → 抠图 | 通义万相生成 + Vision 端上抠图 |
| 场景 + 动画 | 狗狗在房间里呼吸、跳上垫子、点击有反应 |
| 番茄钟专注 | 默认 25 分钟，狗狗陪你专注 |
| 礼物解锁 | 完成专注解锁新场景和家具 |
| 换造型 | 重新拍照生成，每只狗限 3 次 |

## 项目结构

```
DogCompanion/
├── Models/          # Companion, SceneCatalog, FocusSessionState
├── Services/        # GenerationService, MattingService
├── ViewModels/      # Creation, Home (focus timer), Regeneration
├── Views/
│   ├── Creation/    # 拍照 → 选风格 → 生成 → 起名
│   ├── Home/        # 场景 + 专注计时
│   └── Components/  # SceneView, MotionView, FocusTimerView
└── Utilities/       # GiftUnlockPolicy, RegenerationPolicy
```

## 运行测试

```bash
xcodebuild test -project DogCompanion/DogCompanion.xcodeproj -scheme DogCompanion -destination 'platform=iOS Simulator,name=iPhone 16'
```

## 设计文档

- 领域词汇：`CONTEXT.md`
- 架构决策：`docs/adr/`（含 pivot 决策 ADR-0005）

## 上架前注意

1. **API Key 不能打包进客户端** — 需搭建后端代理（见 ADR-0001）
2. **隐私政策** — 需说明照片会发送至阿里云百炼进行处理
3. **Widget** — v1.1 计划加入静态主屏 Widget
