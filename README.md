# 狗狗伙伴 (Dog Companion)

在 iPhone 上养一只虚拟狗狗：拍一张真狗照片，AI 自动生成相似的漫画形象，然后通过喂食、玩耍、散步来照顾它。

## 环境要求

- macOS + Xcode 15+
- iOS 17+ 真机或模拟器（相机功能需真机）
- [Replicate](https://replicate.com) 账号与 API Token

## 快速开始

### 1. 打开项目

```bash
open DogCompanion/DogCompanion.xcodeproj
```

### 2. 配置 API Token

```bash
cp DogCompanion/DogCompanion/Secrets.plist.example DogCompanion/DogCompanion/Secrets.plist
```

编辑 `Secrets.plist`，将 `YOUR_TOKEN_HERE` 替换为你的 Replicate API Token：

```xml
<key>REPLICATE_API_TOKEN</key>
<string>r8_xxxxxxxx</string>
```

> `Secrets.plist` 已在 `.gitignore` 中，不会提交到 Git。

### 3. 配置签名

在 Xcode 中选择 **DogCompanion** target → **Signing & Capabilities** → 勾选 **Automatically manage signing** → 选择你的 **Development Team**。

> 若报错 `Signing for "DogCompanion" requires a development team`，就是这一步没配。模拟器一般也需要选 Personal Team。

### 4. 运行

选择真机或模拟器，按 `Cmd + R` 运行。

## 构建失败排查

| 报错 | 解决办法 |
|------|----------|
| `requires a development team` | Signing & Capabilities → 选择 Development Team |
| `Build input file cannot be found: Secrets.plist` | 运行 `cp DogCompanion/DogCompanion/Secrets.plist.example DogCompanion/DogCompanion/Secrets.plist`（项目已加自动复制脚本，Clean 后重编） |
| `404` / `模型未找到` | 社区模型需用 `version` 调用 API；拉取最新代码，并在 `Secrets.plist` 中配置 `REPLICATE_MODEL_VERSION` |
| `Cannot find 'UIApplication' in scope` | 拉取最新代码（已修复） |
| Xcode 版本过低 | 需要 **Xcode 15+**（iOS 17 / SwiftData / @Observable） |

## 项目结构

```
DogCompanion/
├── DogCompanionApp.swift          # App 入口
├── ContentView.swift              # 路由：无 Companion → 创建流程，有 → 主页
├── Models/
│   ├── Companion.swift            # SwiftData 实体
│   └── StyleTemplate.swift        # 三种漫画风格
├── Services/
│   ├── GenerationService.swift  # Replicate API 调用
│   └── SecretsProvider.swift      # 读取 Secrets.plist
├── ViewModels/
│   ├── CreationViewModel.swift    # 创建流程状态机
│   └── HomeViewModel.swift        # 养成逻辑
├── Views/
│   ├── Creation/                  # 拍照 → 选风格 → 生成 → 起名
│   ├── Home/                      # 主页
│   └── Components/                # 共用 UI 组件
└── Utilities/
    └── VitalStatsCalculator.swift # 饱食度/心情衰减与 Care Action
```

## 玩法说明

| 属性 | 规则 |
|------|------|
| 饱食度 | 喂食 +30；散步 −10；每 4 小时被动 −20 |
| 心情 | 玩耍 +30；散步 +20；每 6 小时被动 −20 |

三种漫画风格：日系动漫、扁平卡通、水彩手绘。

## v1.1 功能

- **换造型（Regeneration）**：主页右上角可重新拍照生成漫画形象，每只狗限 3 次

## 运行测试

在 Xcode 中按 `Cmd + U`，或：

```bash
xcodebuild test -project DogCompanion/DogCompanion.xcodeproj -scheme DogCompanion -destination 'platform=iOS Simulator,name=iPhone 16'
```

## 设计文档

- 领域词汇：`CONTEXT.md`
- 架构决策：`docs/adr/`

## 上架前注意

1. **API Key 不能打包进客户端** — 需搭建后端代理（见 ADR-0001）
2. **隐私政策** — 需说明照片会发送至 Replicate 进行处理
3. **App Icon** — 已包含默认图标，可在 `Assets.xcassets/AppIcon` 中替换为自定义设计
