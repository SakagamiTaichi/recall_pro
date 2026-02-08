---
name: liquid-glass
description: Transform Flutter widgets into liquid glass design using liquid_glass_renderer package. Use when converting dialogs, buttons, cards, text fields, or any UI components to modern glassmorphism style.
argument-hint: "[file-path]"
disable-model-invocation: true
allowed-tools: Read, Edit, Write, Grep, Glob, WebSearch, WebFetch
---

# Liquid Glass Design Transformation

Transform Flutter UI components to stunning liquid glass (glassmorphism) design using the `liquid_glass_renderer` package.

## Task

Convert the specified Flutter file ($ARGUMENTS) to liquid glass design:

1. **Read the target file** - Understand the current UI structure
2. **Check package availability** - Verify `liquid_glass_renderer` is in pubspec.yaml
3. **Apply liquid glass effects** to:
   - Dialogs and modals
   - Buttons (primary and secondary)
   - Cards and containers
   - Text fields and input components
   - Lists and scrollable content

## Implementation Guidelines

### 1. Package Import

```dart
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
```

### 2. Core Components

#### Dialog Transformation
- Replace `AlertDialog` with `Dialog` (backgroundColor: Colors.transparent)
- Add gradient background with `Stack`
- Wrap content in `LiquidGlassLayer` + `LiquidGlass`
- Use `LiquidRoundedSuperellipse` for rounded corners

**Settings:**
```dart
LiquidGlassSettings(
  thickness: 25,
  blur: 15,
  glassColor: Color(0x22FFFFFF),
  lightIntensity: 0.8,
)
```

#### Button Component
- Create separate components for primary/secondary buttons
- Primary: stronger glass effect (thickness: 20, blur: 12)
- Secondary: subtle effect (thickness: 15, blur: 8)
- Add `InkWell` for tap effects

#### Text Field Component
- Wrap in `LiquidGlassLayer` + `LiquidGlass`
- Remove default borders (border: InputBorder.none)
- Use white/translucent text colors
- Settings: thickness: 15, blur: 8

#### Card Component
- Use `LiquidGlassBlendGroup` for multiple cards
- Apply consistent border radius
- Add subtle background gradients

### 3. Color Guidelines

**Background Gradients:**
```dart
LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Colors.blue.shade300.withValues(alpha: 0.3),
    Colors.purple.shade300.withValues(alpha: 0.3),
    Colors.pink.shade300.withValues(alpha: 0.3),
  ],
)
```

**Text Colors:**
- Primary text: `Colors.white`
- Secondary text: `Colors.white70`
- Hint text: `Colors.white38`

**Glass Colors:**
- Light glass: `Color(0x11FFFFFF)` - `Color(0x22FFFFFF)`
- Medium glass: `Color(0x22FFFFFF)` - `Color(0x33FFFFFF)`
- Strong glass: `Color(0x33FFFFFF)` - `Color(0x44FFFFFF)`

### 4. Performance Considerations

⚠️ **Important Notes:**
- Limit the number of `LiquidGlass` widgets (max 16 in one `LiquidGlassBlendGroup`)
- Use `FakeGlass` for non-critical elements (lighter performance)
- Test on actual devices before production deployment
- Only works with Impeller (no Web, Windows, Linux support)

### 5. Design Patterns

**Pattern 1: Simple Glass Effect**
```dart
LiquidGlass.withOwnLayer(
  settings: const LiquidGlassSettings(thickness: 15),
  shape: LiquidRoundedSuperellipse(borderRadius: 20),
  child: YourWidget(),
)
```

**Pattern 2: Blended Multiple Shapes**
```dart
LiquidGlassLayer(
  settings: const LiquidGlassSettings(...),
  child: LiquidGlassBlendGroup(
    blend: 20.0,
    child: Column(
      children: [
        LiquidGlass.grouped(...),
        LiquidGlass.grouped(...),
      ],
    ),
  ),
)
```

**Pattern 3: Custom Components**
- Extract reusable components (e.g., `_LiquidGlassButton`, `_LiquidGlassTextField`)
- Keep components focused and simple
- Use private classes for file-scoped components

## Execution Steps

1. **Read the target file** specified in $ARGUMENTS
2. **Verify dependencies:**
   - Check if `liquid_glass_renderer` is in `pubspec.yaml`
   - If missing, ask user to add it
3. **Identify UI components:**
   - Dialogs → Stack with LiquidGlassLayer
   - Buttons → _LiquidGlassButton component
   - TextFields → _LiquidGlassTextField component
   - Cards → LiquidGlass wrapped containers
4. **Apply transformations:**
   - Add gradient backgrounds
   - Wrap in appropriate LiquidGlass widgets
   - Adjust colors for white-on-glass aesthetic
   - Create reusable components
5. **Fix deprecations:**
   - Use `.withValues(alpha: X)` instead of `.withOpacity(X)`
6. **Test and verify:**
   - Ensure no import errors
   - Check for proper nesting
   - Validate component structure

## Output

Provide:
1. ✅ **Modified file** with liquid glass design applied
2. 📝 **Summary of changes** (components transformed, new classes added)
3. ⚠️ **Performance notes** (number of glass widgets, optimization suggestions)
4. 🎨 **Design details** (color scheme, glass settings used)

## Example Reference

See the transformation of `CardSetDialog` as a reference:
- Original: Standard `AlertDialog` with `TextFormField` and `ElevatedButton`
- Transformed: `Dialog` with gradient background, `LiquidGlassLayer`, custom `_LiquidGlassTextField` and `_LiquidGlassButton` components

---

**Important:** Always maintain the original functionality while enhancing the visual design. Do not modify business logic or behavior.
