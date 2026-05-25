# Pricing Configuration

## Monetization Model: Subscription (IAP)

## Subscription Group
- **Group Name**: VoicePen Pro
- **Group ID**: com.zzoutuo.VoicePen.pro

## Subscription Tiers

### 1. Monthly Subscription
- **Reference Name**: Pro Monthly
- **Product ID**: `com.zzoutuo.VoicePen.pro.monthly`
- **Price**: $1.99 per month
- **Display Name**: VoicePen Pro Monthly
- **Description**: Unlimited recordings & all features
- **Localization**: English (US)

### 2. Yearly Subscription
- **Reference Name**: Pro Yearly
- **Product ID**: `com.zzoutuo.VoicePen.pro.yearly`
- **Price**: $9.99 per year (58% savings vs monthly)
- **Display Name**: VoicePen Pro Yearly
- **Description**: Unlimited recordings & all features
- **Localization**: English (US)

### 3. Lifetime Purchase
- **Reference Name**: Lifetime Access
- **Product ID**: `com.zzoutuo.VoicePen.pro.lifetime`
- **Price**: $19.99 one-time
- **Display Name**: VoicePen Pro Lifetime
- **Description**: Pay once, own forever
- **Note**: No ongoing server costs — all processing is on-device

## Free Tier
- **Recordings per month**: 5
- **All other features**: Fully available (on-device transcription, export, iCloud sync, title editing, audio playback)
- **Limitation**: Recording count only

## Free Trial
- **Duration**: Not offered (free tier serves as trial)

## Policy Pages Required
- Support Page: ✅ (Must include subscription management info)
- Privacy Policy: ✅
- Terms of Use: ✅ (REQUIRED for subscription apps)

## Apple IAP Compliance Checklist
- [ ] Auto-renewal terms included in Terms
- [ ] Cancellation instructions included in Terms
- [ ] Pricing clearly stated in Paywall
- [ ] Restore purchases functionality implemented
- [ ] Subscription management link in Settings

## IAP Implementation Plan

### PurchaseManager.swift (StoreKit 2)
- Product IDs: `com.zzoutuo.VoicePen.pro.monthly`, `com.zzoutuo.VoicePen.pro.yearly`, `com.zzoutuo.VoicePen.pro.lifetime`
- Features: fetch products, purchase, restore, status tracking, transaction listener
- UsageTracker: free limit enforcement (5/month)

### Paywall UI Requirements
- All 3 products displayed with pricing
- Auto-renewal disclosure text
- Privacy Policy + Terms of Use links below Subscribe button
- Restore Purchases button
- No dark patterns

## Competitive Price Positioning

| Competitor | Price | Model | VoicePen Advantage |
|------------|-------|-------|-------------------|
| Otter.ai | $8.33/mo ($100/yr) | Subscription | 5-10x cheaper |
| Notta | $8.17/mo ($98/yr) | Subscription | 5-10x cheaper |
| VoiceScriber | $49.99 lifetime or $5.99/wk | Mixed | 2-3x cheaper |
| Whisper Notes | $6.99 once | Paid | Free to try first |
| Aiko | ~$9.99 once | Paid | Free to try first |
| Apple Dictation | Free | Built-in | More features, offline AI |
