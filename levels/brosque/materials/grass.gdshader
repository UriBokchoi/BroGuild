shader_type spatial;
// Hierba del Brosque: el verde de siempre, pero con manchas grandes más claras y más oscuras, calvas
// de hierba seca y un grano fino, todo por la posición en el mundo (el suelo y lo alto de las mesetas
// casan sin costuras). Sin texturas: ruido de valores en el propio shader.

uniform vec3 base_color : source_color = vec3(0.36, 0.6, 0.28);
uniform vec3 dark_color : source_color = vec3(0.24, 0.47, 0.22);
uniform vec3 light_color : source_color = vec3(0.47, 0.68, 0.3);
uniform vec3 dry_color : source_color = vec3(0.68, 0.64, 0.32);
// Tamaño de las manchas grandes y de las calvas secas (metros por celda de ruido).
uniform float patch_size = 14.0;
uniform float dry_size = 23.0;
// Cuánta parte del suelo es hierba seca (0 = nada).
uniform float dry_amount = 0.3;
// Grano fino: tamaño (m) y cuánto se nota.
uniform float grain_size = 1.3;
uniform float grain_strength = 0.06;
uniform float roughness_value = 0.95;

varying vec2 world_xz;

float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float value_noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash(cell), hash(cell + vec2(1.0, 0.0)), f.x),
		mix(hash(cell + vec2(0.0, 1.0)), hash(cell + vec2(1.0, 1.0)), f.x),
		f.y
	);
}

// Dos octavas: manchas con borde irregular.
float patches(vec2 p) {
	return value_noise(p) * 0.7 + value_noise(p * 2.7 + vec2(17.0, 5.0)) * 0.3;
}

void vertex() {
	world_xz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	float shade = patches(world_xz / patch_size);
	vec3 color = mix(dark_color, light_color, smoothstep(0.25, 0.75, shade));
	color = mix(base_color, color, 0.75);
	float dry = smoothstep(1.0 - dry_amount, 1.0 - dry_amount + 0.12, patches(world_xz / dry_size + vec2(40.0, 9.0)));
	color = mix(color, dry_color, dry * 0.7);
	float grain = value_noise(world_xz / grain_size) - 0.5;
	color *= 1.0 + grain * grain_strength * 2.0;
	ALBEDO = color;
	ROUGHNESS = roughness_value;
}
