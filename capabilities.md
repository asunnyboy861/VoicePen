# VoicePen — 配置文档

生成时间：2026-05-21

---

## 一、⚠️ 手动配置（需你操作才能生效）

### 🔴 Capabilities 配置

#### CloudKit Container — iCloud 同步

**影响功能**：不配置则录音和转写数据无法通过 iCloud 在设备间同步

**已自动配置部分**：
- ✅ Xcode Signing & Capabilities 中已启用 iCloud
- ✅ VoicePen.entitlements 中已添加 CloudKit 权限
- ✅ SwiftData ModelContainer 中已配置 cloudKitDatabase: .private("iCloud.com.zzoutuo.VoicePen")

**仍需手动配置**：
1. 打开 [Apple Developer](https://developer.apple.com)
2. 进入 **Certificates, Identifiers & Profiles** → **Identifiers**
3. 找到 `com.zzoutuo.VoicePen` → 点击编辑
4. 在 **App Services** 中确认 **iCloud** 已勾选启用
5. 进入 **Certificates, Identifiers & Profiles** → **Containers**
6. 确认 CloudKit Container `iCloud.com.zzoutuo.VoicePen` 已创建（如未创建，点击 "+" 创建）
7. 回到 Xcode → 项目设置 → Signing & Capabilities → iCloud → 确认 Container 已勾选
8. ⚠️ 配置完成后需要 Clean Build (Cmd+Shift+K) 并重新运行验证

---

### 🟡 扩展功能（MVP 后续迭代）

#### Keyboard Extension — 键盘扩展

**影响功能**：不创建则无法在任何 App 中直接插入转写文本

**配置步骤**：
1. 在 Xcode 中 → File → New → Target → **Custom Keyboard Extension**
2. 命名为 `VoicePenKeyboard`，Bundle ID 自动设为 `com.zzoutuo.VoicePen.VoicePenKeyboard`
3. 在 Keyboard Extension 的 Info.plist 中设置 `RequestsOpenAccess = YES`
4. 使用 App Group `group.com.zzoutuo.VoicePen` 与主 App 共享数据
5. 实现键盘 UI：显示最近转写文本列表，点击插入到光标位置

#### WidgetKit — Lock Screen 小组件

**影响功能**：不创建则无法在锁屏界面一键录音

**配置步骤**：
1. 在 Xcode 中 → File → New → Target → **Widget Extension**
2. 命名为 `VoicePenWidget`，Bundle ID 自动设为 `com.zzoutuo.VoicePen.VoicePenWidget`
3. 使用 App Group `group.com.zzoutuo.VoicePen` 与主 App 共享数据
4. 实现 Lock Screen Widget（.accessoryCircular 或 .accessoryRectangular）
5. 点击 Widget 通过 Deep Link 打开主 App 录音界面

---

## 二、✅ 自动配置记录（已由系统完成，无需操作）

### Capabilities 自动配置

| Capability | 说明 | 状态 |
|------------|------|------|
| Microphone Access | NSMicrophoneUsageDescription 已在 Info.plist 配置 | ✅ 已配置 |
| Speech Recognition | NSSpeechRecognitionUsageDescription 已在 Info.plist 配置 | ✅ 已配置 |
| Audio Background Mode | UIBackgroundModes = audio 已在 Info.plist 配置 | ✅ 已配置 |
| App Group | group.com.zzoutuo.VoicePen 已在 entitlements 配置 | ✅ 已配置 |
| iCloud Container | iCloud.com.zzoutuo.VoicePen 已在 entitlements 配置 | ✅ 已配置 |
| Entitlements Reference | CODE_SIGN_ENTITLEMENTS 已在 Debug/Release 配置 | ✅ 已配置 |

### 后端服务

| 服务 | 说明 | 状态 |
|------|------|------|
| 联系客服后端 | Cloudflare Workers 部署，地址：`https://feedback-board.iocompile67692.workers.dev/api/feedback` | ✅ 已部署 |
| NSAppTransportSecurity | 允许HTTPS出站连接，已在Info.plist配置 | ✅ 已配置 |

### 代码生成

| 模块 | 说明 | 状态 |
|------|------|------|
| 核心功能 | MVVM架构，录音/转写/回放/编辑/导出/设置 | ✅ 已完成 |
| TranscriptionEngine | WhisperKit 1.0.0 集成，large-v3-turbo 模型 | ✅ 已完成 |
| AudioRecorderService | AVFoundation 录音 + 音量监测 | ✅ 已完成 |
| PostProcessor | 标点修正/语气词移除/幻觉过滤 | ✅ 已完成 |
| ExportService | TXT/Markdown/SRT 导出 | ✅ 已完成 |
| ContactSupportView | 7主题选择、API对接、网络权限 | ✅ 已完成 |
| SettingsView | 政策页面链接、客服入口 | ✅ 已完成 |
| OnboardingView | 首次使用引导流程 | ✅ 已完成 |
| WaveformView | 实时音频波形可视化 | ✅ 已完成 |
| PrivacyBadge | "100% Offline" 状态指示器 | ✅ 已完成 |
| QA迭代 | 编译错误修复 + API兼容性修正 | ✅ 已完成 |

### 部署

| 项目 | 说明 | 状态 |
|------|------|------|
| GitHub仓库 | https://github.com/asunnyboy861/VoicePen | ✅ 已完成 |
| GitHub Pages | 政策页面已部署 | ✅ 已完成 |
| Landing Page | https://asunnyboy861.github.io/VoicePen/ | ✅ 已完成 |
| Support Page | https://asunnyboy861.github.io/VoicePen/support.html | ✅ 已完成 |
| Privacy Policy | https://asunnyboy861.github.io/VoicePen/privacy.html | ✅ 已完成 |
| App Store元数据 | keytext.md 已生成验证 | ✅ 已完成 |
| 定价配置 | $4.99 一次性购买 | ✅ 已完成 |

---

## 三、能力检测详情

### Analysis

Based on operation guide analysis, the following capabilities were detected:
- "录音" / "麦克风" / "microphone" → Microphone access required
- "语音" / "speech" / "转写" / "transcription" → Speech Recognition required
- "同步" / "iCloud" / "CloudKit" → iCloud sync required
- "键盘扩展" / "keyboard extension" / "App Group" → App Group for data sharing
- "Lock Screen" / "Widget" / "WidgetKit" → Widget extension required
- "后台" / "background" / "audio" → Audio background mode required

### No Configuration Needed

- Push Notifications (not required for offline app)
- HealthKit (not applicable)
- Location Services (not applicable)
- Camera/Photo Library (not applicable)
- Sign in with Apple (no account system)
- Siri (not in MVP)
- Apple Watch (Phase 2 feature)

### Verification

- Build succeeded: ✅ (iPhone 15 Pro simulator)
- All entitlements correct: ✅ (entitlements file created and referenced)
- WhisperKit SPM dependency resolved: ✅
