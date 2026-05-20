# Capabilities Configuration

## Analysis
Based on operation guide analysis, the following capabilities were detected:
- "录音" / "麦克风" / "microphone" → Microphone access required
- "语音" / "speech" / "转写" / "transcription" → Speech Recognition required
- "同步" / "iCloud" / "CloudKit" → iCloud sync required
- "键盘扩展" / "keyboard extension" / "App Group" → App Group for data sharing
- "Lock Screen" / "Widget" / "WidgetKit" → Widget extension required
- "后台" / "background" / "audio" → Audio background mode required

## Auto-Configured Capabilities
| Capability | Status | Method |
|------------|--------|--------|
| Microphone Access | ✅ Configured | INFOPLIST_KEY_NSMicrophoneUsageDescription in project.pbxproj |
| Speech Recognition | ✅ Configured | INFOPLIST_KEY_NSSpeechRecognitionUsageDescription in project.pbxproj |
| Audio Background Mode | ✅ Configured | INFOPLIST_KEY_UIBackgroundModes = "audio" in project.pbxproj |
| App Group | ✅ Configured | VoicePen.entitlements with group.com.zzoutuo.VoicePen |
| iCloud Container | ✅ Configured | VoicePen.entitlements with iCloud.com.zzoutuo.VoicePen |
| Entitlements Reference | ✅ Configured | CODE_SIGN_ENTITLEMENTS = VoicePen/VoicePen.entitlements in both Debug/Release |

## Manual Configuration Required
| Capability | Status | Steps |
|------------|--------|-------|
| CloudKit Container Setup | ⏳ Pending | 1. Open Apple Developer Portal → Identifiers → App ID → Enable iCloud; 2. Create CloudKit container "iCloud.com.zzoutuo.VoicePen" in Developer Portal; 3. In Xcode → Signing & Capabilities → iCloud → check the container |
| Keyboard Extension Target | ⏳ Pending | Will be created during PHASE 4+5 code generation |
| Widget Extension Target | ⏳ Pending | Will be created during PHASE 4+5 code generation |
| Provisioning Profiles | ⏳ Pending | Xcode automatic signing should handle this, but may need manual verification after adding capabilities |

## No Configuration Needed
- Push Notifications (not required for offline app)
- HealthKit (not applicable)
- Location Services (not applicable)
- Camera/Photo Library (not applicable)
- Sign in with Apple (no account system)
- Siri (not in MVP)
- Apple Watch (Phase 2 feature)

## Verification
- Build succeeded after configuration: ⏳ Pending (will verify in Step 6)
- All entitlements correct: ✅ (entitlements file created and referenced)
