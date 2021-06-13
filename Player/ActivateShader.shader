shader_type canvas_item;

render_mode blend_mix;
uniform vec4 modulate: hint_color;
uniform bool active;
uniform float time_scale = 20;

void fragment() {
	if (!active) {
		COLOR = texture(TEXTURE,UV);
	} else {
		COLOR = vec4(modulate.rgb, texture(TEXTURE, UV).a * modulate.a);
	}
}