# StyleBoxFancy Complete Documentation

## Overview

**StyleBoxFancy** is a powerful addon for Godot 4 that extends the native `StyleBox` class with advanced visual capabilities. It fills the gap between Godot's `StyleBoxFlat` and `StyleBoxTexture` by combining their features and adding extensive customization options.

- **Version:** 1.3.4
- **Author:** MellowDye
- **Location:** `res://addons/StyleboxFancy/`
- **Plugin:** Registered as custom type `StyleBoxFancy` extending `StyleBox`

---

## Class Hierarchy

```
StyleBox (Godot Core)
  └── StyleBoxFancy (@tool, @icon)
        └── Supports: Textures, Multiple Borders, Corner Shapes, Shadows
```

---

## Complete Class Name

```
StyleBoxFancy
```

---

## Core Properties

### Background & Color

| Property      | Type        | Default                     | Description                                |
| ------------- | ----------- | --------------------------- | ------------------------------------------ |
| `color`       | `Color`     | `Color(1.0, 1.0, 1.0, 1.0)` | Background color; modulates texture if set |
| `draw_center` | `bool`      | `true`                      | Toggles drawing the center of the stylebox |
| `texture`     | `Texture2D` | `null`                      | Background texture                         |

### Layout & Distortion

| Property               | Type      | Default  | Description                    |
| ---------------------- | --------- | -------- | ------------------------------ |
| `skew`                 | `Vector2` | `(0, 0)` | Horizontal/vertical distortion |
| `expand_margin_left`   | `float`   | `0.0`    | Left margin expansion (px)     |
| `expand_margin_top`    | `float`   | `0.0`    | Top margin expansion (px)      |
| `expand_margin_right`  | `float`   | `0.0`    | Right margin expansion (px)    |
| `expand_margin_bottom` | `float`   | `0.0`    | Bottom margin expansion (px)   |

### Corner Radius

| Property                     | Type  | Default | Description                          |
| ---------------------------- | ----- | ------- | ------------------------------------ |
| `corner_radius_top_left`     | `int` | `0`     | Top-left corner radius (px)          |
| `corner_radius_top_right`    | `int` | `0`     | Top-right corner radius (px)         |
| `corner_radius_bottom_right` | `int` | `0`     | Bottom-right corner radius (px)      |
| `corner_radius_bottom_left`  | `int` | `0`     | Bottom-left corner radius (px)       |
| `corner_detail`              | `int` | `8`     | Number of vertices per corner (1-20) |

### Corner Curvature (Advanced Shape Control)

| Property                        | Type    | Default | Description                          |
| ------------------------------- | ------- | ------- | ------------------------------------ |
| `corner_curvature_top_left`     | `float` | `1.0`   | Top-left corner shape (superellipse) |
| `corner_curvature_top_right`    | `float` | `1.0`   | Top-right corner shape               |
| `corner_curvature_bottom_right` | `float` | `1.0`   | Bottom-right corner shape            |
| `corner_curvature_bottom_left`  | `float` | `1.0`   | Bottom-left corner shape             |

**Curvature Presets (Constants):**

```gdscript
StyleBoxFancy.Curvatures = {
    "Round": 1.0,                  # Default: normal circle
    "Squircle": 2.0,               # Between square and circle
    "Bevel": 0.0,                  # Straight line (corner_detail = 1)
    "Scoop": -1.0,                 # Inverse of round
    "Reverse squircle": -2.0,      # Inverse of squircle
    "Notch": -7.0                  # Square cut inside corner
}
```

### Borders

| Property  | Type                 | Default | Description                               |
| --------- | -------------------- | ------- | ----------------------------------------- |
| `borders` | `Array[StyleBorder]` | `[]`    | Array of borders; drawn inside each other |

### Shadow

| Property         | Type        | Default                     | Description                 |
| ---------------- | ----------- | --------------------------- | --------------------------- |
| `shadow_enabled` | `bool`      | `false`                     | Toggle shadow drawing       |
| `shadow_color`   | `Color`     | `Color(0.0, 0.0, 0.0, 0.6)` | Shadow color                |
| `shadow_texture` | `Texture2D` | `null`                      | Shadow texture (optional)   |
| `shadow_blur`    | `int`       | `1`                         | Shadow blur amount (px)     |
| `shadow_offset`  | `Vector2`   | `(0, 0)`                    | Shadow position offset (px) |
| `shadow_spread`  | `Vector2`   | `(0, 0)`                    | Shadow size extension (px)  |

### Texture Rendering

| Property               | Type                 | Default   | Description                          |
| ---------------------- | -------------------- | --------- | ------------------------------------ |
| `texture_stretch_mode` | `TextureStretchMode` | `SCALE`   | How texture scales to fit            |
| `texture_repeat`       | `TextureRepeatMode`  | `INHERIT` | Texture repeat mode                  |
| `texture_scale`        | `float`              | `1.0`     | Texture scale multiplier (0.001-5.0) |

**TextureStretchMode Enum:**

```gdscript
TextureStretchMode {
    SCALE,                  # Scale to fit bounding rect
    KEEP,                   # Original size, top-left corner
    KEEP_CENTERED,          # Original size, centered
    KEEP_ASPECT,            # Scale maintaining aspect ratio
    KEEP_ASPECT_CENTERED,   # Scale maintaining aspect, centered
    KEEP_ASPECT_COVERED     # Scale so shorter side fits
}
```

**TextureRepeatMode Enum:**

```gdscript
TextureRepeatMode {
    INHERIT,                # Inherit from parent CanvasItem
    DISABLED,               # No repeat
    ENABLED,                # Normal repeat
    MIRROR                  # 2×2 mirrored tiling
}
```

### Anti-Aliasing

| Property             | Type    | Default | Description                |
| -------------------- | ------- | ------- | -------------------------- |
| `anti_aliasing`      | `bool`  | `true`  | Smooth edges               |
| `anti_aliasing_size` | `float` | `1.0`   | AA effect size (0.01-10.0) |

### Advanced

| Property   | Type       | Default | Description                                   |
| ---------- | ---------- | ------- | --------------------------------------------- |
| `material` | `Material` | `null`  | Override CanvasItemMaterial or ShaderMaterial |

---

## Public Methods

### Corner Radius Getters/Setters

```gdscript
func get_corner_radius(corner: Corner) -> int
    # Get radius for a specific corner (CORNER_TOP_LEFT, etc.)
    # Returns: Corner radius in pixels

func set_corner_radius(corner: Corner, radius: int) -> void
    # Set radius for a specific corner
    # corner: CORNER_TOP_LEFT, CORNER_TOP_RIGHT, CORNER_BOTTOM_RIGHT, CORNER_BOTTOM_LEFT
    # radius: Radius in pixels

func set_corner_radius_all(radius: int) -> void
    # Set radius for all corners at once
```

### Corner Curvature Getters/Setters

```gdscript
func get_corner_curvature(corner: Corner) -> float
    # Get curvature value for a specific corner

func set_corner_curvature(corner: Corner, curvature: float) -> void
    # Set curvature for a specific corner

func set_corner_curvature_all(curvature: float) -> void
    # Set curvature for all corners at once
```

### Expand Margin Getters/Setters

```gdscript
func get_expand_margin(side: Side) -> float
    # Get expand margin for a specific side (SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM)

func set_expand_margin(side: Side, margin: float) -> void
    # Set expand margin for a specific side

func set_expand_margin_all(margin: float) -> void
    # Set expand margin for all sides
```

---

## Related Class: StyleBorder

`StyleBorder` is a supporting class used within StyleBoxFancy to define individual border layers.

### StyleBorder Properties

| Property       | Type        | Default                     | Description                           |
| -------------- | ----------- | --------------------------- | ------------------------------------- |
| `color`        | `Color`     | `Color(1.0, 1.0, 1.0, 1.0)` | Border color; modulates texture       |
| `blend`        | `bool`      | `false`                     | If true, border fades into background |
| `texture`      | `Texture2D` | `null`                      | Border texture                        |
| `ignore_stack` | `bool`      | `false`                     | If true, draws on top of border stack |

#### Border Width

| Property       | Type  | Default | Description              |
| -------------- | ----- | ------- | ------------------------ |
| `width_left`   | `int` | `0`     | Left border width (px)   |
| `width_top`    | `int` | `0`     | Top border width (px)    |
| `width_right`  | `int` | `0`     | Right border width (px)  |
| `width_bottom` | `int` | `0`     | Bottom border width (px) |

#### Border Inset

| Property       | Type  | Default | Description       |
| -------------- | ----- | ------- | ----------------- |
| `inset_left`   | `int` | `0`     | Left inset (px)   |
| `inset_top`    | `int` | `0`     | Top inset (px)    |
| `inset_right`  | `int` | `0`     | Right inset (px)  |
| `inset_bottom` | `int` | `0`     | Bottom inset (px) |

### StyleBorder Methods

```gdscript
func get_width(side: Side) -> int
    # Get border width for a specific side

func get_width_min() -> int
    # Get minimum border width across all sides

func set_width(side: Side, width: int) -> void
    # Set border width for a specific side

func set_width_all(width: int) -> void
    # Set border width for all sides
```

---

## Usage Examples

### Basic StyleBoxFancy Creation (Code)

```gdscript
# Create a new StyleBoxFancy
var stylebox = StyleBoxFancy.new()
stylebox.color = Color.WHITE
stylebox.corner_radius_top_left = 16
stylebox.corner_radius_top_right = 16
stylebox.corner_radius_bottom_right = 16
stylebox.corner_radius_bottom_left = 16
stylebox.anti_aliasing = true
```

### Adding Borders

```gdscript
# Create a border
var border = StyleBorder.new()
border.color = Color.BLUE
border.width_top = 2
border.width_bottom = 2
border.width_left = 2
border.width_right = 2

# Add to stylebox
stylebox.borders.append(border)
```

### Applying to UI Nodes

```gdscript
# Apply to a PanelContainer
var panel = PanelContainer.new()
panel.add_theme_stylebox_override("panel", stylebox)

# Apply to other UI elements (Button, Control, etc.)
var button = Button.new()
button.add_theme_stylebox_override("normal", stylebox)
```

### Using Curvature Presets

```gdscript
# Apply Squircle corner shape
stylebox.corner_curvature_top_left = StyleBoxFancy.Curvatures["Squircle"]
stylebox.corner_curvature_top_right = StyleBoxFancy.Curvatures["Squircle"]
stylebox.corner_curvature_bottom_right = StyleBoxFancy.Curvatures["Squircle"]
stylebox.corner_curvature_bottom_left = StyleBoxFancy.Curvatures["Squircle"]

# Use Bevel corners
stylebox.set_corner_curvature_all(StyleBoxFancy.Curvatures["Bevel"])
```

### Texture Styling

```gdscript
# Setup textured stylebox
var stylebox = StyleBoxFancy.new()
stylebox.texture = preload("res://assets/background.png")
stylebox.texture_stretch_mode = StyleBoxFancy.TextureStretchMode.KEEP_ASPECT_CENTERED
stylebox.texture_repeat = StyleBoxFancy.TextureRepeatMode.DISABLED
stylebox.texture_scale = 1.5
```

### Shadow Effects

```gdscript
var stylebox = StyleBoxFancy.new()
stylebox.shadow_enabled = true
stylebox.shadow_color = Color(0, 0, 0, 0.5)
stylebox.shadow_blur = 4
stylebox.shadow_offset = Vector2(2, 2)
stylebox.shadow_spread = Vector2(4, 4)
```

### Converter Usage (Editor Only)

StyleBoxFancy includes built-in converters that allow conversion between formats:

```gdscript
# StyleBoxFlat → StyleBoxFancy (automatic in editor)
# Right-click a StyleBoxFlat resource → "Convert StyleBoxFancy"

# StyleBoxFancy → StyleBoxFlat (automatic in editor)
# Right-click a StyleBoxFancy resource → "Convert StyleBoxFlat"

# StyleBoxTexture ↔ StyleBoxFancy (automatic in editor)
```

---

## Addon Structure

```
res://addons/StyleboxFancy/
├── StyleBoxFancy.gd              # Main class (extends StyleBox)
├── StyleBorder.gd                # Border definition class
├── plugin.gd                      # Editor plugin registration
├── plugin.cfg                     # Plugin manifest
├── StyleBoxFancy.svg              # Icon
├── StyleBorder.svg                # Icon
├── converters/                    # Format converters
│   ├── fancy_to_flat.gd          # Convert to StyleBoxFlat
│   ├── fancy_to_texture.gd       # Convert to StyleBoxTexture
│   ├── flat_to_fancy.gd          # Convert from StyleBoxFlat
│   └── texture_to_fancy.gd       # Convert from StyleBoxTexture
└── inspector/                     # Editor inspector UI
    ├── inspector_plugin.gd        # Inspector customization
    ├── corner_editor.gd           # Corner radius/curvature editor
    └── corner editor container/   # Advanced corner UI
        ├── corner_editor_container.gd
        ├── tooltip_button.gd
        ├── tooltip.gd
        ├── link_button.gd
        ├── curvature_preset_button.gd
        └── icons/                 # UI icons
```

---

## Integration with Godot 4

- **Extends:** `StyleBox` (native Godot class)
- **Compatibility:** Godot 4.0+
- **Renderer:** Works with GL Compatibility and Forward+ renderers
- **Property Hints:** Full editor support with @export and @export_subgroup annotations
- **Theme System:** Fully compatible with Godot's theme system

---

## Performance Notes

1. **Corner Geometry Caching:** Corner shapes are cached internally to reduce recalculation
2. **Anti-Aliasing:** Adds slight performance cost; use only where needed
3. **Texture Support:** Multiple texture modes available; choose appropriate mode for use case
4. **Material Override:** Custom materials (CanvasItemMaterial, ShaderMaterial) supported but not required

---

## Best Practices

1. **Set Radius Before Curvature:** Set corner radius values before adjusting curvature
2. **Use Presets:** Leverage `StyleBoxFancy.Curvatures` for consistent corner shapes
3. **Border Stacking:** Multiple borders stack from outer to inner; use `ignore_stack` for layering control
4. **Texture + Color:** When using both texture and color, color will modulate the texture
5. **Anti-Aliasing:** Enable for rounded corners; disable for sharp edges to reduce draw calls
6. **Expand Margins:** Use to create negative space around the stylebox without affecting control size

---

## Current Usage in Project

The game codebase currently uses `StyleBoxFlat` exclusively. StyleBoxFancy is available for enhancement but not actively used in the current implementation. It can be integrated when advanced corner shapes, multiple borders, or shadow effects are needed.

**Key Files Using StyleBox:**

- `res://scripts/ui_design_system.gd` - Centralized UI styling
- `res://scripts/gameplay_hud_layer.gd` - HUD panel styling
- `res://scripts/home_overlay_layer.gd` - Home screen styling
- `res://scripts/result_overlay_layer.gd` - Result screen styling

---

## References

- **Plugin Version:** 1.3.4
- **Author:** MihailJP / MellowDye
- **Godot Version Target:** 4.0+
- **Repository:** Available in `res://addons/StyleboxFancy/`
