shader_type canvas_item;

uniform sampler2D dissolve_texture : source_color;
uniform float dissolve_value : hint_range(0,1);
uniform float burn_size: hint_range(0.0, 1.0, 0.01);
uniform vec4 burn_color: source_color;
uniform bool use_screen_space_dissolve = false;
uniform float screen_space_noise_scale : hint_range(0.001, 0.05, 0.001) = 0.01;
uniform vec2 screen_space_noise_offset = vec2(0.0, 0.0);

void fragment(){
	vec4 base_color = COLOR * texture(TEXTURE, UV);
	vec2 dissolve_uv = UV;
	if (use_screen_space_dissolve) {
		dissolve_uv = fract((FRAGCOORD.xy + screen_space_noise_offset) * screen_space_noise_scale);
	}
	vec4 noise_texture = texture(dissolve_texture, dissolve_uv);

	// This avoids keeping a small burn-color dot when dissolve is exactly 0 or 1.
	float burn_size_step = burn_size * step(0.001, dissolve_value) * step(dissolve_value, 0.999);
	float threshold = smoothstep(noise_texture.x - burn_size_step, noise_texture.x, dissolve_value);
	float border = smoothstep(noise_texture.x, noise_texture.x + burn_size_step, dissolve_value);

	COLOR.a = base_color.a * threshold;
	COLOR.rgb = mix(burn_color.rgb, base_color.rgb, border);
}
