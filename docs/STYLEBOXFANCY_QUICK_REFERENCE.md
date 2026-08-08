# StyleBoxFancy Quick Reference

## Class Name

```
StyleBoxFancy
```

## Essential Properties (Most Used)

### Corners & Shape

```gdscript
corner_radius_top_left: int
corner_radius_top_right: int
corner_radius_bottom_right: int
corner_radius_bottom_left: int
corner_detail: int = 8              # Vertices per corner (1-20)

# Corner shape (default: 1.0 = round)
corner_curvature_top_left: float = 1.0
corner_curvature_top_right: float = 1.0
corner_curvature_bottom_right: float = 1.0
corner_curvature_bottom_left: float = 1.0
```

### Colors & Appearance

```gdscript
color: Color = Color(1, 1, 1, 1)          # Main background color
draw_center: bool = true                  # Draw the center fill

anti_aliasing: bool = true                # Smooth edges
anti_aliasing_size: float = 1.0           # AA intensity
```

### Shadows

```gdscript
shadow_enabled: bool = false
shadow_color: Color = Color(0, 0, 0, 0.6)
shadow_blur: int = 1                      # Blur amount
shadow_offset: Vector2 = Vector2(0, 0)    # Position offset
shadow_spread: Vector2 = Vector2(0, 0)    # Size expansion
shadow_texture: Texture2D                 # Optional texture
```

### Textures

```gdscript
texture: Texture2D                        # Background texture
texture_scale: float = 1.0                # Texture scale (0.001-5.0)
texture_stretch_mode: TextureStretchMode  # How to scale
texture_repeat: TextureRepeatMode         # Repeat behavior
```

### Borders & Margins

```gdscript
borders: Array[StyleBorder]               # Array of border layers

expand_margin_left: float = 0.0
expand_margin_top: float = 0.0
expand_margin_right: float = 0.0
expand_margin_bottom: float = 0.0

skew: Vector2 = Vector2(0, 0)             # Distortion
```

---

## Curvature Presets

Access via `StyleBoxFancy.Curvatures`:

```gdscript
{
    "Round": 1.0,
    "Squircle": 2.0,
    "Bevel": 0.0,
    "Scoop": -1.0,
    "Reverse squircle": -2.0,
    "Notch": -7.0
}
```

---

## TextureStretchMode Enum

```gdscript
TextureStretchMode.SCALE                 # Default: fill rect
TextureStretchMode.KEEP                  # Original size, top-left
TextureStretchMode.KEEP_CENTERED         # Original size, centered
TextureStretchMode.KEEP_ASPECT           # Scale, maintain ratio
TextureStretchMode.KEEP_ASPECT_CENTERED  # Scale, ratio, centered
TextureStretchMode.KEEP_ASPECT_COVERED   # Scale, ratio, covered
```

---

## TextureRepeatMode Enum

```gdscript
TextureRepeatMode.INHERIT                # Use parent CanvasItem setting
TextureRepeatMode.DISABLED               # No repeat
TextureRepeatMode.ENABLED                # Normal repeat
TextureRepeatMode.MIRROR                 # 2x2 mirrored tiling
```

---

## Essential Methods

### Batch Setters (Convenient for All 4 Corners/Sides)

```gdscript
set_corner_radius_all(radius: int)
set_corner_curvature_all(curvature: float)
set_expand_margin_all(margin: float)
```

### Individual Getters/Setters

```gdscript
get_corner_radius(corner: Corner) -> int
set_corner_radius(corner: Corner, radius: int)

get_corner_curvature(corner: Corner) -> float
set_corner_curvature(corner: Corner, curvature: float)

get_expand_margin(side: Side) -> float
set_expand_margin(side: Side, margin: float)

# Corner enum: CORNER_TOP_LEFT, CORNER_TOP_RIGHT, CORNER_BOTTOM_RIGHT, CORNER_BOTTOM_LEFT
# Side enum: SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM
```

---

## Common Patterns

### Rounded Box (Simple)

```gdscript
var box = StyleBoxFancy.new()
box.color = Color.WHITE
box.set_corner_radius_all(16)
box.anti_aliasing = true
```

### Rounded Box with Border

```gdscript
var box = StyleBoxFancy.new()
box.color = Color.WHITE
box.set_corner_radius_all(16)

var border = StyleBorder.new()
border.color = Color.BLUE
border.set_width_all(2)
box.borders.append(border)
```

### Squircle Shape

```gdscript
var box = StyleBoxFancy.new()
box.color = Color.WHITE
box.set_corner_radius_all(20)
box.set_corner_curvature_all(StyleBoxFancy.Curvatures["Squircle"])
```

### Textured Box

```gdscript
var box = StyleBoxFancy.new()
box.texture = preload("res://my_texture.png")
box.texture_stretch_mode = StyleBoxFancy.TextureStretchMode.KEEP_ASPECT_CENTERED
box.texture_repeat = StyleBoxFancy.TextureRepeatMode.DISABLED
box.set_corner_radius_all(12)
```

### Box with Shadow

```gdscript
var box = StyleBoxFancy.new()
box.color = Color.WHITE
box.shadow_enabled = true
box.shadow_blur = 4
box.shadow_offset = Vector2(2, 2)
box.shadow_spread = Vector2(4, 4)
```

### Apply to UI Node

```gdscript
var panel = PanelContainer.new()
panel.add_theme_stylebox_override("panel", stylebox_fancy)

var button = Button.new()
button.add_theme_stylebox_override("normal", stylebox_fancy)
```

---

## StyleBorder Properties & Methods

### Properties

```gdscript
color: Color = Color(1, 1, 1, 1)
blend: bool = false                 # Fade into background
texture: Texture2D                  # Border texture
ignore_stack: bool = false          # Draw on top of stack

# Width (individual sides)
width_left: int = 0
width_top: int = 0
width_right: int = 0
width_bottom: int = 0

# Inset (move border inward/outward)
inset_left: int = 0
inset_top: int = 0
inset_right: int = 0
inset_bottom: int = 0
```

### Methods

```gdscript
get_width(side: Side) -> int
set_width(side: Side, width: int)
set_width_all(width: int)
get_width_min() -> int
```

---

## File Locations

- **Main Class:** `res://addons/StyleboxFancy/StyleBoxFancy.gd`
- **Border Class:** `res://addons/StyleboxFancy/StyleBorder.gd`
- **Converters:** `res://addons/StyleboxFancy/converters/`
- **Inspector UI:** `res://addons/StyleboxFancy/inspector/`
- **Full Docs:** `res://docs/STYLEBOXFANCY_DOCUMENTATION.md`

---

## Version Info

- **Version:** 1.3.4
- **Author:** MellowDye
- **Status:** Production-Ready
- **Godot:** 4.0+
