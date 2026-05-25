# Git Repositories

## Main App (iOS Application)

| Item | Value |
|------|-------|
| **Repository Name** | VoicePen |
| **Git URL** | git@github.com:asunnyboy861/VoicePen.git |
| **Repo URL** | https://github.com/asunnyboy861/VoicePen |
| **Visibility** | Public |
| **Primary Language** | Swift |
| **GitHub Pages** | ✅ **ENABLED** (from `/docs` folder) |

## Policy Pages (Deployed from Main Repository /docs)

| Page | URL | Status |
|------|-----|--------|
| Landing Page | https://asunnyboy861.github.io/VoicePen/ | ✅ Active |
| Support | https://asunnyboy861.github.io/VoicePen/support.html | ✅ Active |
| Privacy Policy | https://asunnyboy861.github.io/VoicePen/privacy.html | ✅ Active |
| Terms of Use | https://asunnyboy861.github.io/VoicePen/terms.html | ✅ Active |

## Repository Structure

```
VoicePen/
├── VoicePen/                    # iOS App Source Code
│   ├── VoicePen.xcodeproj/      # Xcode Project
│   ├── VoicePen/                # Swift Source Files
│   │   ├── Views/
│   │   │   ├── Components/      # PrivacyBadge, RecordButton
│   │   │   ├── Onboarding/      # OnboardingView
│   │   │   ├── Recording/       # RecordingView, RecordingListView, WaveformView
│   │   │   ├── Settings/        # SettingsView
│   │   │   ├── Support/         # ContactSupportView
│   │   │   └── Transcription/   # TranscriptionDetailView, TimestampTextView
│   │   ├── Models/              # Recording, TranscriptSegment
│   │   ├── Services/            # AudioRecorder, TranscriptionEngine, Export, PostProcessor
│   │   └── VoicePenApp.swift    # App Entry Point
│   └── VoicePenTests/
├── docs/                        # Policy Pages (GitHub Pages source)
│   ├── index.html
│   ├── support.html
│   └── privacy.html
├── .github/workflows/
│   └── deploy.yml
├── us.md
├── capabilities.md
├── price.md
├── icon.md
└── nowgit.md
```
