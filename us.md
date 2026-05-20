# VoicePen - iOS Development Guide

## Executive Summary

**VoicePen** is a privacy-first, fully offline voice-to-text iOS application that transforms spoken words into written text entirely on-device. Built on WhisperKit and Apple CoreML, it delivers real-time transcription with smart punctuation correction, a custom keyboard extension for direct text insertion into any app, and Lock Screen widget for instant recording — all for a one-time $4.99 purchase with zero subscriptions, zero cloud uploads, and zero data collection.

**Target Audience**: Privacy-conscious professionals (lawyers, doctors, journalists), commuters, travelers, students, writers, and anyone who values offline capability and data sovereignty.

**Key Differentiators**:
- 100% offline — works in Airplane Mode, no server dependency
- ~300MB quantized Whisper Large V3 Turbo model (87% smaller than Whisper Notes' 2.2GB)
- Smart punctuation post-processing — fixes "comma"/"period" word output bug
- Custom keyboard extension — inserts transcribed text directly into any app's cursor position
- Lock Screen widget — one-tap recording without unlocking
- $4.99 one-time — 20x cheaper than Otter.ai ($100/year), no subscription fatigue

## Competitive Analysis

| App | Platform | Price | Offline | Privacy | Keyboard Ext | Lock Screen | Model Size | Languages |
|-----|----------|-------|---------|---------|-------------|-------------|------------|-----------|
| **VoicePen** | iOS | $4.99 once | ✅ Full | ✅ Zero data | ✅ Yes | ✅ Yes | ~300MB | 100+ |
| Whisper Notes | iOS/Mac | $6.99 once | ✅ Full | ✅ Zero data | ❌ No | ✅ Yes | ~2.2GB | 100+ |
| VoiceScriber | iOS | $49.99/$5.99/wk | ✅ Full | ✅ Zero data | ❌ No | ✅ Widget | ~500MB | 100+ |
| Aiko | iOS/Mac | ~$9.99 once | ✅ Full | ✅ Zero data | ❌ No | ❌ No | ~1GB | 100+ |
| Otter.ai | iOS/Android/Web | $8.33/mo | ❌ Cloud | ❌ Cloud | ❌ No | ❌ No | N/A | Limited |
| Apple Dictation | iOS | Free | ⚠️ Partial | ✅ Apple | ✅ System | ❌ No | N/A | Limited |
| Just Press Record | iOS/Mac | $4.99 once | ⚠️ Partial | ✅ Apple | ❌ No | ❌ No | N/A | Limited |
| Speakwise | iOS | Subscription | ⚠️ Partial | ⚠️ Mixed | ❌ No | ❌ No | N/A | 100+ |

**VoicePen's Competitive Edge**: Only app combining offline transcription + keyboard extension + Lock Screen widget + smart punctuation + smallest model size at the lowest one-time price.

## ⚠️ Feature Inventory (MANDATORY — Every Feature Must Be Listed)

### Primary Features

| # | Feature | User Operation Flow | Data Input | Processing | Data Output | Persistence | Acceptance Criteria |
|---|---------|--------------------|------------|------------|-------------|-------------|---------------------|
| 1 | **Audio Recording** | 1. User opens app → 2. Taps record button → 3. App shows waveform + timer → 4. User taps stop | Microphone audio stream | AVAudioSession → AVAudioRecorder → PCM 16kHz mono buffer → M4A file | Audio file saved, waveform displayed during recording, duration tracked | SwiftData Recording entity (id, title, createdAt, duration, audioFileName, language, modelUsed) | Recording plays back correctly, duration accurate, waveform visible |
| 2 | **Real-time Streaming Transcription** | 1. User starts recording → 2. Text appears in real-time as user speaks → 3. User stops → 4. Full transcript displayed | Live audio buffer from AVAudioRecorder | Audio buffer → WhisperKit streaming inference → Post-processing pipeline → Segmented text | Real-time text segments displayed during recording, final complete transcript after stop | SwiftData TranscriptSegment entities (text, startTime, endTime, confidence) linked to Recording | Text appears within 1-2 seconds of speaking, final transcript matches audio content |
| 3 | **Smart Punctuation Post-Processing** | 1. WhisperKit outputs raw text → 2. Post-processor runs automatically → 3. User sees corrected text | Raw WhisperKit output (e.g., "hello comma how are you period") | PostProcessor: fixPunctuationWords → removeFillerWords → filterHallucinations → sentenceSegmentation → capitalizeFirstLetters | Clean text with proper punctuation, no filler words, no hallucination segments | Processed text stored in TranscriptSegment entities | "comma" → ",", "period" → ".", "um"/"uh" removed, sentence capitalization correct |
| 4 | **Custom Keyboard Extension** | 1. User switches to VoicePen keyboard in any app → 2. Taps and holds mic button → 3. Speaks → 4. Releases → 5. Text inserted at cursor | Microphone audio from keyboard extension process | Shared App Group container → WhisperKit in extension process → PostProcessor → textDocumentProxy.insertText() | Transcribed text directly inserted into the active app's text field | Audio cached in shared App Group container, no persistent storage needed | Text appears at cursor position in Messages, Notes, Slack, Email, etc. |
| 5 | **Lock Screen Widget** | 1. User taps VoicePen widget on Lock Screen → 2. App opens in recording mode → 3. Recording starts automatically | Widget tap (deep link: voicepen://record) | Deep link handled by VoicePenApp → navigate to recording view → auto-start recording | App opens and begins recording immediately | Widget state via WidgetKit TimelineProvider | One tap from Lock Screen starts recording within 2 seconds |
| 6 | **Recording List & Search** | 1. User opens app → 2. Sees list of recordings grouped by date → 3. Can search across all transcripts | User scroll/tap, search text input | SwiftData query → filter by date, search by transcript text content | List of Recording cards with title, duration, preview text, privacy badge | SwiftData Recording + TranscriptSegment queries | All recordings visible, search returns matching transcripts within 1 second |
| 7 | **Recording Detail & Playback** | 1. User taps recording card → 2. Sees full transcript with timestamps → 3. Can play audio → 4. Taps timestamp to jump to position | Recording selection, audio playback controls | AVAudioPlayer → load M4A file → sync playback position with transcript timestamps | Audio playback with waveform, transcript with tappable timestamps | No additional persistence, reads from existing Recording/TranscriptSegment | Audio plays correctly, tapping timestamp seeks to correct position |
| 8 | **Text Editing** | 1. User opens recording detail → 2. Taps edit → 3. Modifies transcript text → 4. Saves | User text edits | SwiftUI TextEditor binding → update TranscriptSegment text in SwiftData | Edited transcript displayed | SwiftData TranscriptSegment text updated | Edits persist across app launches, original timestamps preserved |
| 9 | **Export (TXT/Markdown/SRT)** | 1. User opens recording detail → 2. Taps share/export → 3. Selects format → 4. Shares or saves | Format selection (TXT/MD/SRT) | Generate formatted string from TranscriptSegments → SRT includes timestamps, MD includes headers, TXT is plain | Formatted document in selected format | Temporary file generation, shared via UIActivityViewController | Exported file opens correctly in other apps, SRT timestamps valid |
| 10 | **Share** | 1. User opens recording detail → 2. Taps share → 3. System share sheet appears → 4. User selects target app | Share button tap | Read transcript text → present UIActivityViewController with text content | Text shared to target app (Messages, Mail, Notes, etc.) | No persistence needed | Text appears correctly in target app |
| 11 | **iCloud Sync** | 1. User records on iPhone → 2. Opens iPad → 3. Recording appears automatically | CloudKit sync trigger | SwiftData with CloudKit private database → automatic sync Recording + TranscriptSegment entities | Recordings and transcripts available on all iCloud-connected devices | CloudKit private database + iCloud Drive for audio files | Recording made on iPhone appears on iPad within 30 seconds on same iCloud account |
| 12 | **Multiple AI Models** | 1. User opens Settings → 2. Selects Transcription Model → 3. Chooses Whisper Turbo or Parakeet V3 | Model selection in Settings | ModelManager: download model from HuggingFace (first time) → cache in Application Support → load into WhisperKit | Selected model used for all subsequent transcriptions | Model files cached in Application Support/Models/, selection in UserDefaults | Model downloads successfully, transcription works with selected model |
| 13 | **Auto Language Detection** | 1. User records speech → 2. Language auto-detected → 3. Transcription uses detected language | Audio stream (no user input needed) | WhisperKit DecodingOptions(language: nil) → auto-detect language → transcribe in detected language | Transcript in correct language | Detected language stored in Recording.language | English, German, Chinese, Spanish, French, etc. all transcribed correctly without manual language selection |
| 14 | **Settings Page** | 1. User taps gear icon → 2. Sees settings options → 3. Modifies preferences | User selections (model, language, storage management) | SettingsViewModel → update UserDefaults / trigger model download / calculate storage | Updated settings reflected in app behavior | UserDefaults for preferences, FileManager for storage calculations | Model selection persists, storage display accurate, language preference saved |
| 15 | **Onboarding Flow** | 1. First launch → 2. Welcome screen → 3. Microphone permission → 4. Model download → 5. Ready | First launch detection (UserDefaults: hasCompletedOnboarding) | OnboardingViewModel → request permissions → download default model → mark onboarding complete | Permission granted, model downloaded, user can start recording | UserDefaults: hasCompletedOnboarding, model download state | Onboarding completes in under 3 minutes, user can record immediately after |
| 16 | **Dark Mode & Dynamic Type** | 1. User changes system appearance/text size → 2. App adapts automatically | System settings changes | SwiftUI automatic adaptation with semantic colors (.label, .secondaryLabel) and scalable fonts | UI renders correctly in light/dark, at all Dynamic Type sizes | No persistence needed (system-driven) | App looks correct in both modes, text readable at largest Dynamic Type size |
| 17 | **VoiceOver Support** | 1. VoiceOver user navigates app → 2. All elements accessible → 3. Recording and transcription usable | VoiceOver gestures | SwiftUI accessibility modifiers (.accessibilityLabel, .accessibilityHint, .accessibilityElement) | All interactive elements announced correctly | No persistence needed | VoiceOver user can record, view transcript, navigate settings without sighted assistance |

### Sub-Features & Detail Interactions

| # | Parent Feature | Sub-Feature | Detail Description | Interaction Pattern |
|---|---------------|-------------|-------------------|--------------------|
| 1.1 | Audio Recording | Pause/Resume | User can pause recording and resume without losing audio | Tap pause button, tap resume button |
| 1.2 | Audio Recording | Waveform Visualization | Real-time audio level waveform displayed during recording | Automatic, no user action needed |
| 1.3 | Audio Recording | VAD Auto-Stop | Voice Activity Detection stops recording after 2 seconds of silence | Automatic, configurable in Settings |
| 2.1 | Real-time Transcription | Streaming Text Display | Text appears word-by-word as user speaks | Automatic during recording |
| 3.1 | Smart Punctuation | Punctuation Word Fix | "comma" → ",", "period" → ".", "question mark" → "?", "exclamation mark" → "!" | Automatic post-processing |
| 3.2 | Smart Punctuation | Filler Word Removal | "um", "uh", "嗯", "啊" removed from transcript | Automatic post-processing |
| 3.3 | Smart Punctuation | Hallucination Filter | Overly long timestamp segments and repeated segments discarded | Automatic post-processing |
| 3.4 | Smart Punctuation | Sentence Capitalization | First letter of each sentence auto-capitalized | Automatic post-processing |
| 4.1 | Keyboard Extension | Permission Guide | Step-by-step guide to enable VoicePen keyboard in iOS Settings | User taps "Enable Keyboard" → redirected to Settings |
| 4.2 | Keyboard Extension | Hold-to-Speak | Press and hold mic button to record, release to transcribe and insert | Long press gesture |
| 5.1 | Lock Screen Widget | Circular Widget | Small circular widget showing mic icon | Tap to start recording |
| 5.2 | Lock Screen Widget | Rectangular Widget | Rectangular widget with "Record" label and mic icon | Tap to start recording |
| 6.1 | Recording List | Date Grouping | Recordings grouped by Today, Yesterday, older dates | Automatic grouping |
| 6.2 | Recording List | Swipe Actions | Swipe left to delete, swipe right to pin | Swipe gesture |
| 7.1 | Recording Detail | Timestamp Tapping | Tap any timestamp to jump audio playback to that position | Tap gesture on timestamp |
| 7.2 | Recording Detail | Copy Transcript | One-tap copy entire transcript to clipboard | Tap copy button |
| 12.1 | Multiple Models | Model Download Progress | Progress bar during first-time model download | Automatic, shown in onboarding and settings |
| 12.2 | Multiple Models | Storage Management | Show model sizes and allow deletion of unused models | Settings → Storage → Delete model |
| 14.1 | Settings | Storage Info | Display total storage used by recordings and models | Automatic calculation |
| 14.2 | Settings | Privacy Badge | "100% Offline" and "Zero Data Collection" indicators visible | Always visible in settings |
| 15.1 | Onboarding | Microphone Permission | System dialog requesting microphone access | System dialog, one-time |
| 15.2 | Onboarding | Speech Permission | System dialog requesting speech recognition access | System dialog, one-time |
| 15.3 | Onboarding | Model Download | Download default Whisper Turbo model (~300MB) with progress bar | Automatic after permissions granted |

### Cross-Feature Dependencies

| Dependency | Source Feature | Target Feature | Data Passed | Trigger Condition |
|------------|---------------|----------------|-------------|-------------------|
| Recording → Transcription | Audio Recording | Real-time Transcription | Audio buffer (PCM 16kHz) | Recording starts |
| Transcription → Post-Processing | Real-time Transcription | Smart Punctuation | Raw WhisperKit text output | Each transcription segment received |
| Post-Processing → Display | Smart Punctuation | Recording Detail | Processed text segments | Transcription complete |
| Recording → List | Audio Recording | Recording List | Recording entity (SwiftData) | Recording saved |
| Recording → Widget | Audio Recording | Lock Screen Widget | Deep link URL (voicepen://record) | Widget tapped |
| Keyboard → App Group | Custom Keyboard | Audio Recording | Audio file in shared container | Keyboard recording complete |
| Settings → Transcription | Settings Page | Multiple AI Models | Selected model identifier | Model selection changed |
| Onboarding → Recording | Onboarding Flow | Audio Recording | Permissions granted, model downloaded | Onboarding complete |
| Recording → iCloud | Audio Recording | iCloud Sync | Recording + TranscriptSegment entities | Recording saved (auto-sync) |
| Recording → Export | Recording Detail | Export | Transcript segments + format selection | Export button tapped |

## Apple Design Guidelines Compliance

- **HIG - Audio**: App requests microphone permission with clear explanation before first recording. Uses AVAudioSession properly with .record mode and .duckOthers option.
- **HIG - Privacy**: App displays privacy badge ("100% Offline") prominently. No data collection whatsoever. App Store privacy label: "Data Not Collected".
- **HIG - Keyboard Extensions**: Custom keyboard follows Apple Keyboard Extension guidelines — provides standard "next keyboard" button, requests Full Access only when needed for WhisperKit model access.
- **HIG - Widgets**: Lock Screen widgets use accessoryCircular and accessoryRectangular families per Apple guidelines.
- **HIG - Accessibility**: VoiceOver labels on all interactive elements, Dynamic Type support, minimum 44pt touch targets.
- **HIG - Navigation**: Uses SwiftUI NavigationStack with standard back navigation. No custom gesture conflicts.
- **HIG - Dark Mode**: All colors use semantic UIColor/SwiftUI Color tokens. Pure black background in dark mode (OLED-friendly).
- **HIG - Haptics**: UIImpactFeedbackGenerator on record start/stop, UINotificationFeedbackGenerator on transcription complete.
- **App Store Review 2.1**: App is fully functional offline. No placeholder content. All features work without network.
- **App Store Review 5.1.1**: No account required. No data collection. Privacy policy clearly states zero data practices.

## Technical Architecture

- **Language**: Swift 5.9+
- **Framework**: SwiftUI (primary), UIKit (keyboard extension)
- **Data**: SwiftData with CloudKit private database
- **AI Engine**: WhisperKit (argmaxinc/argmax-oss-swift)
- **Audio**: AVFoundation (AVAudioSession, AVAudioRecorder, AVAudioPlayer)
- **Widgets**: WidgetKit (Lock Screen + Home Screen)
- **Keyboard**: UIInputViewController (custom keyboard extension)
- **Sync**: CloudKit private database + iCloud Drive
- **Concurrency**: Swift Concurrency (async/await, Actor)
- **Architecture Pattern**: MVVM + SwiftData (View → ViewModel → Repository/Service)

## Module Structure

```
VoicePen/
├── VoicePenApp.swift
├── Views/
│   ├── Recording/
│   │   ├── RecordingListView.swift
│   │   ├── RecordingView.swift
│   │   ├── RecordingViewModel.swift
│   │   └── WaveformView.swift
│   ├── Transcription/
│   │   ├── TranscriptionDetailView.swift
│   │   ├── TranscriptionDetailViewModel.swift
│   │   └── TimestampTextView.swift
│   ├── Settings/
│   │   ├── SettingsView.swift
│   │   └── SettingsViewModel.swift
│   ├── Onboarding/
│   │   ├── OnboardingView.swift
│   │   └── OnboardingViewModel.swift
│   └── Components/
│       ├── PrivacyBadge.swift
│       └── RecordButton.swift
├── Models/
│   ├── Recording.swift
│   └── TranscriptSegment.swift
├── Services/
│   ├── TranscriptionEngine.swift
│   ├── AudioRecorderService.swift
│   ├── PostProcessor.swift
│   ├── ModelManager.swift
│   └── ExportService.swift
├── Keyboard/
│   └── VoicePenKeyboardViewController.swift
├── Widget/
│   ├── VoicePenWidget.swift
│   └── VoicePenProvider.swift
└── Resources/
    └── Assets.xcassets/
```

## ⚠️ Data Flow Diagram (MANDATORY — Every Feature's Data Lifecycle)

### Feature 1: Audio Recording
```
┌───────────────────────────────────────────────────────────┐
│  User Input                                                │
│  └── Tap record button → AVAudioSession activated         │
│       │                                                    │
│  ViewModel Processing                                      │
│  └── RecordingViewModel → startRecording() →              │
│      AVAudioRecorder.record() → Timer for metering        │
│       │                                                    │
│  Model/Persistence                                         │
│  └── M4A file saved to Documents/ → SwiftData Recording   │
│      entity created (id, title, duration, audioFileName)  │
│       │                                                    │
│  Display Output                                            │
│  └── WaveformView shows audio levels, timer displays      │
│      duration, recording indicator (red pulse)             │
│       │                                                    │
│  Cross-Feature Output                                      │
│  └── Audio buffer → TranscriptionEngine (Feature 2)       │
│      Recording entity → RecordingList (Feature 6)         │
└───────────────────────────────────────────────────────────┘
```

### Feature 2: Real-time Streaming Transcription
```
┌───────────────────────────────────────────────────────────┐
│  User Input                                                │
│  └── Speaking into microphone (no explicit action)        │
│       │                                                    │
│  ViewModel Processing                                      │
│  └── RecordingViewModel → audioBuffer →                   │
│      TranscriptionEngine.transcribeStream() →             │
│      WhisperKit streaming inference → raw segments        │
│       │                                                    │
│  Model/Persistence                                         │
│  └── TranscriptSegment entities created in SwiftData      │
│      (text, startTime, endTime, confidence)               │
│       │                                                    │
│  Display Output                                            │
│  └── Real-time text display in RecordingView              │
│      (text appears word-by-word as spoken)                │
│       │                                                    │
│  Cross-Feature Output                                      │
│  └── Raw text → PostProcessor (Feature 3)                 │
│      Segments → TranscriptionDetail (Feature 7)           │
└───────────────────────────────────────────────────────────┘
```

### Feature 3: Smart Punctuation Post-Processing
```
┌───────────────────────────────────────────────────────────┐
│  User Input                                                │
│  └── None (automatic pipeline)                            │
│       │                                                    │
│  ViewModel Processing                                      │
│  └── PostProcessor.process(text) →                        │
│      Step 1: fixPunctuationWords ("comma" → ",")          │
│      Step 2: removeFillerWords ("um", "uh" → "")          │
│      Step 3: filterHallucinations (long/repeated → drop)  │
│      Step 4: sentenceSegmentation (by punctuation+time)   │
│      Step 5: capitalizeFirstLetters                       │
│       │                                                    │
│  Model/Persistence                                         │
│  └── TranscriptSegment.text updated with processed text   │
│       │                                                    │
│  Display Output                                            │
│  └── Clean, properly punctuated text in all views         │
│       │                                                    │
│  Cross-Feature Output                                      │
│  └── Processed text → Export (Feature 9)                  │
│      Processed text → Share (Feature 10)                  │
│      Processed text → Keyboard Extension (Feature 4)      │
└───────────────────────────────────────────────────────────┘
```

### Feature 4: Custom Keyboard Extension
```
┌───────────────────────────────────────────────────────────┐
│  User Input                                                │
│  └── Switch to VoicePen keyboard → Hold mic button →     │
│      Speak → Release button                                │
│       │                                                    │
│  ViewModel Processing                                      │
│  └── VoicePenKeyboardViewController →                     │
│      AVAudioRecorder (in extension process) →             │
│      Audio saved to shared App Group container →          │
│      WhisperKit.transcribe() → PostProcessor.process()    │
│       │                                                    │
│  Model/Persistence                                         │
│  └── Audio cached in shared App Group container           │
│      (no SwiftData access from extension)                 │
│       │                                                    │
│  Display Output                                            │
│  └── textDocumentProxy.insertText(processedText)          │
│      → Text appears at cursor in host app                 │
│       │                                                    │
│  Cross-Feature Output                                      │
│  └── None (keyboard extension is self-contained)          │
└───────────────────────────────────────────────────────────┘
```

### Feature 5: Lock Screen Widget
```
┌───────────────────────────────────────────────────────────┐
│  User Input                                                │
│  └── Tap VoicePen widget on Lock Screen                   │
│       │                                                    │
│  ViewModel Processing                                      │
│  └── Widget tap → Deep link (voicepen://record) →        │
│      VoicePenApp.onOpenURL → navigate to RecordingView   │
│      → auto-start recording                               │
│       │                                                    │
│  Model/Persistence                                         │
│  └── None (widget triggers app launch)                    │
│       │                                                    │
│  Display Output                                            │
│  └── App opens in recording mode, recording starts        │
│       │                                                    │
│  Cross-Feature Output                                      │
│  └── Triggers Feature 1 (Audio Recording)                 │
└───────────────────────────────────────────────────────────┘
```

### Feature 6: Recording List & Search
```
┌───────────────────────────────────────────────────────────┐
│  User Input                                                │
│  └── Scroll list, tap search, type query                  │
│       │                                                    │
│  ViewModel Processing                                      │
│  └── RecordingListViewModel →                              │
│      SwiftData @Query → fetch Recordings sorted by date   │
│      Search: filter TranscriptSegments by text content    │
│       │                                                    │
│  Model/Persistence                                         │
│  └── SwiftData Recording + TranscriptSegment queries      │
│       │                                                    │
│  Display Output                                            │
│  └── Grouped list (Today, Yesterday, older) with cards    │
│      showing title, duration, preview text, privacy badge │
│       │                                                    │
│  Cross-Feature Output                                      │
│  └── Tap card → Feature 7 (Recording Detail)              │
└───────────────────────────────────────────────────────────┘
```

### Feature 11: iCloud Sync
```
┌───────────────────────────────────────────────────────────┐
│  User Input                                                │
│  └── None (automatic background sync)                     │
│       │                                                    │
│  ViewModel Processing                                      │
│  └── SwiftData automatic CloudKit sync →                  │
│      Private database syncs Recording + TranscriptSegment │
│      Audio files sync via iCloud Drive                     │
│       │                                                    │
│  Model/Persistence                                         │
│  └── CloudKit private database + iCloud Drive             │
│       │                                                    │
│  Display Output                                            │
│  └── Recordings appear on all iCloud-connected devices    │
│       │                                                    │
│  Cross-Feature Output                                      │
│  └── Synced recordings available in Feature 6 (List)      │
└───────────────────────────────────────────────────────────┘
```

### Feature 12: Multiple AI Models
```
┌───────────────────────────────────────────────────────────┐
│  User Input                                                │
│  └── Settings → Transcription Model → Select model        │
│       │                                                    │
│  ViewModel Processing                                      │
│  └── ModelManager → check downloaded models →             │
│      Download from HuggingFace if needed →                │
│      Cache to Application Support/Models/ →               │
│      Initialize WhisperKit with selected model             │
│       │                                                    │
│  Model/Persistence                                         │
│  └── Model files in Application Support/Models/           │
│      UserDefaults: selectedModel, downloadedModels        │
│       │                                                    │
│  Display Output                                            │
│  └── Model selection reflected in Settings,               │
│      download progress shown, storage usage displayed     │
│       │                                                    │
│  Cross-Feature Output                                      │
│  └── Selected model used by Feature 2 (Transcription)     │
└───────────────────────────────────────────────────────────┘
```

## Implementation Flow

1. Create Xcode project with SwiftUI, SwiftData, iOS 17.0 minimum
2. Add WhisperKit Swift Package dependency (argmaxinc/argmax-oss-swift)
3. Configure App Group for main app ↔ keyboard extension data sharing
4. Implement SwiftData models (Recording, TranscriptSegment)
5. Implement AudioRecorderService (AVAudioSession + AVAudioRecorder)
6. Implement TranscriptionEngine (WhisperKit integration + streaming)
7. Implement PostProcessor (punctuation fix, filler removal, hallucination filter)
8. Implement ModelManager (download, cache, select models)
9. Build RecordingView with waveform visualization
10. Build RecordingListView with search and date grouping
11. Build TranscriptionDetailView with playback and editing
12. Build SettingsView with model selection and storage management
13. Build OnboardingView with permissions and model download
14. Create Keyboard Extension target (VoicePenKeyboard)
15. Create Widget Extension target (VoicePenWidget)
16. Configure CloudKit for iCloud sync
17. Implement ExportService (TXT, Markdown, SRT)
18. Add VoiceOver labels and Dynamic Type support
19. Add haptic feedback on key interactions
20. Test in Airplane Mode (verify zero network requests)

## UI/UX Design Specifications

- **Color Scheme**:
  - Primary: #007AFF (system blue — trust, professionalism)
  - Recording: #FF3B30 (system red — recording active)
  - Success: #34C759 (system green — transcription complete)
  - Warning: #FF9500 (system orange — processing)
  - Privacy: #5856D6 (system purple — privacy badge)
  - Background Light: #FFFFFF, Dark: #000000 (OLED-friendly)
  - Text: semantic colors (.label, .secondaryLabel, .tertiaryLabel)

- **Typography**:
  - Page Title: SF Pro Display 28pt Bold
  - Card Title: SF Pro Display 17pt Semibold
  - Body Text: SF Pro Text 15pt Regular
  - Auxiliary: SF Pro Text 13pt Regular
  - Timestamps: SF Mono 12pt Medium
  - Recording Timer: SF Pro Display 48pt Light

- **Layout**:
  - Large record button (60% of screen width) at bottom
  - Privacy badge ("🔒 100% Offline") always visible at top
  - Recording cards with preview text, duration, lock icon
  - 16pt standard padding, 8pt compact padding

- **Animations**:
  - Button press: scale 0.95→1.0, 0.15s easeOut
  - Recording start: red pulse + haptic feedback (continuous)
  - Transcription complete: green checkmark + bounce, 0.3s spring
  - Text appearance: character-by-character fade-in, 0.05s/char
  - Page transition: iOS native slide, 0.35s
  - Waveform: real-time audio level animation

## Code Generation Rules

- One feature per module, high cohesion, low coupling
- MVVM pattern: View → ViewModel → Service/Repository
- Swift Concurrency (async/await, Actor) — no CompletionHandler
- WhisperKit uses Actor isolation for thread safety
- Custom Error enums with proper throw/catch
- Audio buffer released immediately after processing
- Zero network requests principle — all data processing on-device
- SwiftUI declarative UI with semantic colors
- Support Dynamic Type and VoiceOver
- English primary, German secondary via String Catalog
- No code comments unless explicitly requested

## Build & Deployment Checklist

- [ ] Xcode project configured (Swift 5.9+, iOS 17.0, SwiftUI)
- [ ] WhisperKit Swift Package added and resolved
- [ ] App Group configured (main app + keyboard extension)
- [ ] Microphone and Speech Recognition entitlements
- [ ] Keyboard Extension target created
- [ ] Widget Extension target created
- [ ] CloudKit capability enabled
- [ ] App Store metadata prepared (ASO optimized)
- [ ] Privacy policy page deployed
- [ ] Test in Airplane Mode (zero network requests)
- [ ] Test on iPhone 12+ and iPad
- [ ] VoiceOver audit complete
- [ ] Dynamic Type audit complete
- [ ] App Store Review Guidelines compliance verified

## ⚠️ App Store Compliance — AI Features

This app uses built-in on-device AI models (WhisperKit). No BYO API key required.

### Guideline 2.1(a) — App Completeness
- All AI features work offline without any API key or account
- WhisperKit models download on first launch with progress indicator
- No free tier / paid tier distinction — all features included in $4.99 purchase
- No "generation counting" or "free trial" mechanics

### Privacy Compliance
- App Store privacy label: "Data Not Collected"
- No analytics, no telemetry, no crash reporting (optional local-only)
- No account/registration required
- All processing on-device, zero network requests after model download
