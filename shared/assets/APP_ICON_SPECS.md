# IRR Genius - App Icon Specifications

## Design Concept

The IRR Genius app icon should convey:
- **Financial Growth**: Upward trending elements
- **Precision**: Clean, mathematical aesthetic  
- **Professional**: Suitable for business users
- **Trust**: Reliable, established appearance

## Color Palette

### Primary Colors
- **Blue**: `#4A90E2` - Trust, stability, financial
- **Green**: `#50E3C2` - Growth, success, money
- **Gold**: `#F5A623` - Premium, value, achievement

### Supporting Colors
- **Dark Blue**: `#2E5C8A` - Depth, reliability
- **Light Blue**: `#7BB3F0` - Accessibility, friendliness

## Icon Elements

### Core Symbol Options

1. **Trending Arrow + Percentage**
   - Upward arrow with % symbol
   - Mathematical and clear

2. **Growth Chart**
   - Simple line chart showing growth
   - Instantly recognizable purpose

3. **IRR Monogram**
   - Stylized "IRR" letters
   - Professional, direct

### Style Guidelines
- **Minimalist**: Clean, uncluttered design
- **Scalable**: Works at all sizes (16px to 512px)
- **Platform Appropriate**: Follows iOS/Android design guidelines

## Platform Requirements

### iOS
- **App Store**: 1024×1024px PNG
- **Device Sizes**: 20px, 29px, 40px, 58px, 60px, 76px, 80px, 87px, 120px, 152px, 167px, 180px
- **Format**: PNG with transparency
- **Corner Radius**: Applied automatically by iOS

### Android
- **Adaptive Icon**: 108×108dp with 72×72dp safe zone
- **Sizes**: 48dp (mdpi), 72dp (hdpi), 96dp (xhdpi), 144dp (xxhdpi), 192dp (xxxhdpi)
- **Formats**: PNG, Vector (recommended)
- **Background**: Optional separate background layer

## Design Assets Needed

### For Both Platforms
1. **Master Icon**: High-resolution vector (SVG)
2. **App Store/Play Store**: 1024×1024px PNG
3. **Brand Guidelines**: Color codes, usage rules

### iOS Specific
- Complete icon set for all required sizes
- Optional dark mode variant

### Android Specific  
- Adaptive icon foreground layer
- Adaptive icon background layer
- Notification icon (monochrome)

## Implementation Notes

### iOS
- Place icon files in `ios/IRR Genius/Assets.xcassets/AppIcon.appiconset/`
- Update `Contents.json` with all size variants
- Test on various devices and iOS versions

### Android
- Place icons in `android/app/src/main/res/mipmap-*/`
- Update `AndroidManifest.xml` icon references
- Consider adaptive icon animations

## Brand Consistency

The app icon should be consistent with:
- App UI color scheme
- Marketing materials
- Website branding
- Business card/letterhead design

## Testing Checklist

- [ ] Visible at 16×16px size
- [ ] Clear at all required platform sizes
- [ ] Looks good on light and dark backgrounds
- [ ] Follows platform design guidelines
- [ ] Passes App Store/Play Store review
- [ ] Consistent across all platforms
- [ ] Professional appearance