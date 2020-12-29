shader_type canvas_item;

uniform vec4 core_fire_color : hint_color;
uniform vec4 outer_fire_color : hint_color;
uniform bool narrow = true;
uniform bool default_fire_color = true;
uniform sampler2D noise;

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	vec4 n = texture(noise, vec2(UV.x, UV.y + TIME));

	if (narrow) {
		base.r += 0.4f - distance(vec2(0.5, UV.y), UV);
	}
	base.r = (base.r * 0.3) + (n.r * 0.4);

	if (default_fire_color) {
		COLOR = vec4(float(base.r > 0.4), float(base.r > 0.5), float(base.r > 0.6), float(base.r > 0.4));
	} else {
		if (base.r > 0.5) {
			COLOR = vec4(core_fire_color.r, core_fire_color.g, core_fire_color.b, 1);
		}else if (base.r > 0.4) {
			COLOR = vec4(outer_fire_color.r, outer_fire_color.g, outer_fire_color.b, 1);
		} else {
			COLOR = vec4(0, 0, 0, 0);
		}
	}
}