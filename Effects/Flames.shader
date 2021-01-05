shader_type canvas_item;

uniform vec4 core_fire_color : hint_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 inner_fire_color : hint_color = vec4(1.0, 1.0, 0, 1.0);
uniform vec4 outer_fire_color : hint_color = vec4(1.0, 0, 0, 1.0);
uniform bool narrow = true;
uniform bool leftToRight = false;
uniform float speed : hint_range(0, 5.0) = 1.0;
uniform float scale : hint_range(0.6, 1) = 1.0;
uniform sampler2D noise;


void fragment() {
	vec4 base = texture(TEXTURE, UV);
	vec4 n;
	if (leftToRight) {
		n = texture(noise, vec2(UV.x + (TIME * -speed), UV.y));
	} else {
		n = texture(noise, vec2(UV.x, UV.y + (TIME * speed)));
	}

	if (narrow) {
		base.r += 0.4f - distance(vec2(0.5, UV.y), UV);
	}
	base.r = (base.r * 0.3) + (n.r * 0.4);

	if (base.r > (0.6 / scale)) {
		COLOR = vec4(core_fire_color.r, core_fire_color.g, core_fire_color.b, 1)
	}else if (base.r > (0.5 / scale)) {
		COLOR = vec4(inner_fire_color.r, inner_fire_color.g, inner_fire_color.b, 1);
	}else if (base.r > (0.4 / scale)) {
		COLOR = vec4(outer_fire_color.r, outer_fire_color.g, outer_fire_color.b, 1);
	} else {
		COLOR = vec4(0, 0, 0, 0);
	}
}