shader_type canvas_item;

// Mild row-dependent horizontal expansion makes the supplied table read as a
// shallower mobile-game surface. The original PNG remains untouched.
void fragment() {
	float top_weight = 1.0 - smoothstep(0.18, 0.82, UV.y);
	float width_scale = mix(1.0, 1.15, top_weight);
	vec2 table_uv = UV;
	table_uv.x = 0.5 + (UV.x - 0.5) / width_scale;
	COLOR = texture(TEXTURE, table_uv) * COLOR;
}
