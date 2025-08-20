# 📱 IRR Genius - App Store Submission Guide

## Overview
This guide walks you through publishing IRR Genius to the Apple App Store.

## Prerequisites ✅
- [✓] Xcode installed and working
- [✓] IRR Genius app fully functional
- [✓] App icon configured (1024x1024px)
- [✓] Bundle ID set: `com.mukerji.IRR-Genius`
- [✓] Splash screen implemented
- [✓] All major features working

## What You Need to Do

### Step 1: Apple Developer Account 💳
1. Go to [developer.apple.com](https://developer.apple.com)
2. Sign up for Apple Developer Program ($99/year)
3. Complete enrollment (takes 24-48 hours)
4. Verify your Team ID matches: `7CMB2K99NS`

### Step 2: App Store Connect Setup 🏪
1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Click "My Apps" → "+" → "New App"
3. Fill in app details:
   - **App Name**: "IRR Genius"
   - **Primary Language**: English
   - **Bundle ID**: com.mukerji.IRR-Genius
   - **SKU**: IRRGenius2024 (or similar unique identifier)

### Step 3: Create App Store Listing 📝

#### Required Information:
- **App Name**: IRR Genius
- **Subtitle**: Investment Return Calculator
- **Description**: 
```
IRR Genius is a powerful investment return calculator designed for professionals and investors. Calculate Internal Rate of Return (IRR), future values, and portfolio returns with ease.

Features:
• Calculate IRR from initial and final investment values
• Determine future values based on target IRR
• Portfolio unit investment calculator with fee structures
• Support for follow-on investments and blended IRR
• Professional charts and growth visualization
• Save and manage multiple calculations
• Export calculations to PDF and CSV
• Clean, intuitive interface

Perfect for:
• Investment professionals
• Financial analysts
• Portfolio managers
• Individual investors
• Anyone needing accurate IRR calculations

IRR Genius provides the tools you need to make informed investment decisions with confidence.
```

- **Keywords**: investment, IRR, calculator, finance, portfolio, returns, financial
- **Category**: Finance
- **Content Rating**: 4+ (No objectionable content)

#### Screenshots Needed:
You'll need to take screenshots of:
1. Main calculator screen
2. Portfolio calculator
3. Results with charts
4. Saved calculations list
5. Settings screen

**Screenshot Sizes Required:**
- iPhone 6.7": 1290 x 2796 pixels
- iPhone 6.5": 1242 x 2688 pixels  
- iPhone 5.5": 1242 x 2208 pixels

### Step 4: Build & Archive in Xcode 🔨

1. **Open your project in Xcode**
   ```bash
   open "/Users/raja/code/IRR Genius/ios/IRR Genius.xcodeproj"
   ```

2. **Select "IRR Genius" target** (not the test targets)

3. **Configure Signing**:
   - Go to "Signing & Capabilities" tab
   - Ensure "Automatically manage signing" is checked
   - Select your team: "Raja Mukerji (7CMB2K99NS)"
   - Verify Bundle Identifier: `com.mukerji.IRR-Genius`

4. **Set Build Configuration**:
   - In Xcode toolbar, select: "Any iOS Device (arm64)"
   - Go to Product → Scheme → Edit Scheme
   - Set Build Configuration to "Release"

5. **Archive the App**:
   - Go to Product → Archive
   - Wait for build to complete
   - Xcode Organizer will open automatically

6. **Distribute to App Store**:
   - Click "Distribute App"
   - Select "App Store Connect"
   - Choose "Upload"
   - Select your distribution certificate
   - Click "Upload"

### Step 5: Submit for Review 📋

1. **Return to App Store Connect**
2. **Go to your app** → Version 1.0
3. **Upload Screenshots** (take these from simulator)
4. **Fill in remaining fields**:
   - App Review Information
   - Version Release options
   - Pricing (Free or Paid)
5. **Save and Submit for Review**

### Step 6: Review Process ⏱️

- **Review Time**: Typically 1-7 days
- **Common Rejection Reasons**:
  - Missing privacy policy (if you collect data)
  - App crashes or doesn't work as described
  - Misleading screenshots or description
  - Missing required metadata

## Privacy Considerations 🔒

Your app uses:
- Core Data (local storage only)
- CloudKit (Apple's service, user's own iCloud)

**Privacy Policy**: You may need one if:
- You collect any user data
- You use analytics
- You use third-party services

**Current Status**: IRR Genius appears to only store data locally and in user's iCloud, so you may not need a privacy policy, but check Apple's latest requirements.

## Troubleshooting 🔧

### Common Issues:

1. **"No signing certificate found"**
   - Ensure Apple Developer Account is active
   - Check Xcode → Preferences → Accounts
   - Download certificates if needed

2. **"Bundle ID not available"**
   - Your Bundle ID `com.mukerji.IRR-Genius` should be unique
   - If taken, try `com.mukerji.IRRGenius` or similar

3. **"App Store Connect app not found"**
   - Ensure you created the app in App Store Connect first
   - Bundle IDs must match exactly

4. **Archive fails**
   - Clean build folder (Product → Clean Build Folder)
   - Ensure you're building for "Any iOS Device"
   - Check for Swift compiler errors

## Estimated Timeline 📅

- **Setup Apple Developer Account**: 1-2 days
- **Create App Store Listing**: 2-3 hours  
- **Take Screenshots**: 1 hour
- **Build & Archive**: 30 minutes
- **App Review**: 1-7 days
- **Total Time**: 3-10 days

## Cost 💰

- **Apple Developer Program**: $99/year (required)
- **App Store Listing**: Free
- **Your Time**: ~1 day of work

## Support Resources 📚

- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [App Store Connect Help](https://developer.apple.com/help/app-store-connect/)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)

---

**Ready to Submit?** Run the preparation script:
```bash
cd "/Users/raja/code/IRR Genius/ios"
./scripts/prepare_release.sh
```

Good luck with your App Store submission! 🚀