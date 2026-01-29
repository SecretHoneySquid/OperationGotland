shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// Water colors
uniform vec4 shallow_color : source_color = vec4(0.15, 0.35, 0.45, 0.85);
uniform vec4 deep_color : source_color = vec4(0.05, 0.12, 0.2, 0.95);
uniform float color_depth_factor : hint_range(0.0, 1.0) = 0.5;

// Wave parameters
uniform float wave_speed : hint_range(0.0, 2.0) = 0.3;
uniform float wave_scale : hint_range(0.001, 0.1) = 0.02;
uniform float wave_height : hint_range(0.0, 5.0) = 0.8;

// Surface parameters
uniform float roughness : hint_range(0.0, 1.0) = 0.1;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float fresnel_power : hint_range(0.0, 10.0) = 4.0;

// Foam/edge parameters
uniform vec4 foam_color : source_color = vec4(0.9, 0.95, 1.0, 0.8);
uniform float foam_amount : hint_range(0.0, 1.0) = 0.2;

varying vec3 world_pos;
varying float wave_offset;

float wave(vec2 pos, float time) {
	float w1 = sin(pos.x * wave_scale * 1.0 + time * wave_speed) * 0.5;
	float w2 = sin(pos.y * wave_scale * 1.3 + time * wave_speed * 0.8) * 0.3;
	float w3 = sin((pos.x + pos.y) * wave_scale * 0.7 + time * wave_speed * 1.2) * 0.2;
	return (w1 + w2 + w3) * wave_height;
}

vec3 calculate_normal(vec2 pos, float time) {
	float delta = 1.0;
	float h_center = wave(pos, time);
	float h_right = wave(pos + vec2(delta, 0.0), time);
	float h_forward = wave(pos + vec2(0.0, delta), time);

	vec3 tangent = normalize(vec3(delta, h_right - h_center, 0.0));
	vec3 bitangent = normalize(vec3(0.0, h_forward - h_center, delta));

	return normalize(cross(bitangent, tangent));
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wave_offset = wave(world_pos.xz, TIME);
	VERTEX.y += wave_offset;

	// Calculate wave normal
	vec3 wave_normal = calculate_normal(world_pos.xz, TIME);
	NORMAL = normalize(mix(NORMAL, wave_normal, 0.5));
}

void fragment() {
	// Base color with depth variation
	float depth_factor = clamp(wave_offset * 0.5 + color_depth_factor, 0.0, 1.0);
	vec4 water_color = mix(deep_color, shallow_color, depth_factor);

	// Fresnel effect for edge highlighting
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), fresnel_power);

	// Add subtle foam on wave peaks
	float foam_factor = smoothstep(wave_height * 0.6, wave_height, wave_offset) * foam_amount;
	vec4 final_color = mix(water_color, foam_color, foam_factor);

	// Apply fresnel to brighten edges
	final_color.rgb = mix(final_color.rgb, vec3(0.6, 0.75, 0.85), fresnel * 0.3);

	ALBEDO = final_color.rgb;
	ALPHA = final_color.a;
	ROUGHNESS = roughness;
	METALLIC = metallic;
	SPECULAR = 0.5;
}
