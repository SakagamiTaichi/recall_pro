# Liquid Glass Design - Implementation Examples

## Example 1: Dialog Transformation

### Before (Standard AlertDialog)

```dart
AlertDialog(
  title: Text('My Dialog'),
  content: Column(
    children: [
      TextField(
        decoration: InputDecoration(
          labelText: 'Name',
          border: OutlineInputBorder(),
        ),
      ),
    ],
  ),
  actions: [
    TextButton(
      onPressed: () => Navigator.pop(context),
      child: Text('Cancel'),
    ),
    ElevatedButton(
      onPressed: () => handleSave(),
      child: Text('Save'),
    ),
  ],
)
```

### After (Liquid Glass Dialog)

```dart
Dialog(
  backgroundColor: Colors.transparent,
  elevation: 0,
  child: Stack(
    children: [
      // Background gradient
      Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade300.withValues(alpha: 0.3),
              Colors.purple.shade300.withValues(alpha: 0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      // Liquid glass layer
      LiquidGlassLayer(
        settings: const LiquidGlassSettings(
          thickness: 25,
          blur: 15,
          glassColor: Color(0x22FFFFFF),
          lightIntensity: 0.8,
        ),
        child: LiquidGlass(
          shape: LiquidRoundedSuperellipse(borderRadius: 28),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'My Dialog',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 24),
                _LiquidGlassTextField(
                  labelText: 'Name',
                  hintText: 'Enter your name',
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _LiquidGlassButton(
                      onPressed: () => Navigator.pop(context),
                      label: 'Cancel',
                      isPrimary: false,
                    ),
                    const SizedBox(width: 12),
                    _LiquidGlassButton(
                      onPressed: () => handleSave(),
                      label: 'Save',
                      isPrimary: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  ),
)
```

## Example 2: Button Component

```dart
class _LiquidGlassButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final bool isPrimary;
  final bool isLoading;

  const _LiquidGlassButton({
    required this.onPressed,
    required this.label,
    this.isPrimary = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlassLayer(
      settings: LiquidGlassSettings(
        thickness: isPrimary ? 20 : 15,
        blur: isPrimary ? 12 : 8,
        glassColor: isPrimary
            ? const Color(0x33FFFFFF)
            : const Color(0x22FFFFFF),
        lightIntensity: isPrimary ? 1.0 : 0.7,
      ),
      child: LiquidGlass(
        shape: LiquidRoundedSuperellipse(borderRadius: 20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      label,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
```

## Example 3: TextField Component

```dart
class _LiquidGlassTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String labelText;
  final String hintText;
  final String? Function(String?)? validator;
  final int maxLines;

  const _LiquidGlassTextField({
    this.controller,
    required this.labelText,
    required this.hintText,
    this.validator,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlassLayer(
      settings: const LiquidGlassSettings(
        thickness: 15,
        blur: 8,
        glassColor: Color(0x11FFFFFF),
        lightIntensity: 0.6,
      ),
      child: LiquidGlass(
        shape: LiquidRoundedSuperellipse(borderRadius: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: labelText,
              labelStyle: const TextStyle(color: Colors.white70),
              hintText: hintText,
              hintStyle: const TextStyle(color: Colors.white38),
              border: InputBorder.none,
              errorStyle: const TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: const TextStyle(color: Colors.white),
            validator: validator,
            maxLines: maxLines,
          ),
        ),
      ),
    );
  }
}
```

## Example 4: Card List with Blending

```dart
class LiquidGlassCardList extends StatelessWidget {
  final List<CardModel> cards;

  const LiquidGlassCardList({required this.cards});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.indigo.shade300.withValues(alpha: 0.3),
            Colors.purple.shade300.withValues(alpha: 0.3),
          ],
        ),
      ),
      child: LiquidGlassLayer(
        settings: const LiquidGlassSettings(
          thickness: 20,
          blur: 12,
          glassColor: Color(0x22FFFFFF),
        ),
        child: LiquidGlassBlendGroup(
          blend: 20.0,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: cards.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return LiquidGlass.grouped(
                shape: LiquidRoundedSuperellipse(borderRadius: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cards[index].title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cards[index].description,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
```

## Example 5: Simple Glass Card (withOwnLayer)

```dart
class SimpleGlassCard extends StatelessWidget {
  final String title;
  final String description;

  const SimpleGlassCard({
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlass.withOwnLayer(
      settings: const LiquidGlassSettings(
        thickness: 18,
        blur: 10,
        glassColor: Color(0x22FFFFFF),
        lightIntensity: 0.8,
      ),
      shape: LiquidRoundedSuperellipse(borderRadius: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Color Palette Reference

### Gradient Combinations

**Blue-Purple:**
```dart
[
  Colors.blue.shade300.withValues(alpha: 0.3),
  Colors.purple.shade300.withValues(alpha: 0.3),
]
```

**Purple-Pink:**
```dart
[
  Colors.purple.shade300.withValues(alpha: 0.3),
  Colors.pink.shade300.withValues(alpha: 0.3),
]
```

**Indigo-Cyan:**
```dart
[
  Colors.indigo.shade300.withValues(alpha: 0.3),
  Colors.cyan.shade300.withValues(alpha: 0.3),
]
```

**Multi-color:**
```dart
[
  Colors.blue.shade300.withValues(alpha: 0.3),
  Colors.purple.shade300.withValues(alpha: 0.3),
  Colors.pink.shade300.withValues(alpha: 0.3),
]
```

### Glass Color Values

- `0x11FFFFFF` - Very subtle (7% opacity)
- `0x22FFFFFF` - Light (13% opacity)
- `0x33FFFFFF` - Medium (20% opacity)
- `0x44FFFFFF` - Strong (27% opacity)

## Settings Presets

### Subtle Glass
```dart
LiquidGlassSettings(
  thickness: 12,
  blur: 6,
  glassColor: Color(0x11FFFFFF),
  lightIntensity: 0.5,
)
```

### Standard Glass
```dart
LiquidGlassSettings(
  thickness: 20,
  blur: 10,
  glassColor: Color(0x22FFFFFF),
  lightIntensity: 0.7,
)
```

### Strong Glass
```dart
LiquidGlassSettings(
  thickness: 30,
  blur: 15,
  glassColor: Color(0x33FFFFFF),
  lightIntensity: 1.0,
)
```
