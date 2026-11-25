shader_type spatial;
// Mancha de fuego en el suelo (el rastro ardiente del slide). Va en un PlaneMesh de 2 × 2 escalado al
// radio: un disco de borde irregular con lenguas de fuego que se mueven. El ruido va por la posición
// en el mundo, así las manchas que se pisan dibujan las mismas llamas y el rastro se ve de una pieza
// (y, al mezclarse en vez de sumarse, no se satura). Se apaga con «fade» (1 = encendida, 0 = apagada).
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec4 hot_color : source_color = vec4(1.0, 0.86, 0.35, 1.0);
uniform vec4 flame_color : source_color = vec4(1.0, 0.42, 0.08, 1.0);
uniform vec4 ember_color : source_color = vec4(0.55, 0.08, 0.02, 1.0);
uniform float intensity = 1.25;
// Velocidad a la que se mueven las llamas.
uniform float flicker_rate = 2.2;
// Tamaño del grano de las llamas: a más, llamas más pequeñas.
uniform float grain = 1.6;
// Opacidad máxima.
uniform float opacity = 0.85;
instance uniform float fade = 1.0;

varying vec2 world_xz;

// Hash sin seno (el seno pierde precisión lejos del origen y el fuego salía a cuadros).
float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float value_noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(cell);
	float b = hash(cell + vec2(1.0, 0.0));
	float c = hash(cell + vec2(0.0, 1.0));
	float d = hash(cell + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Tres capas de ruido que se mueven en direcciones distintas: lenguas de fuego.
float flames(vec2 p, float t) {
	float value = value_noise(p + vec2(t * 0.5, -t * 0.9)) * 0.5;
	value += value_noise(p * 2.1 - vec2(t * 1.1, t * 0.4)) * 0.3;
	value += value_noise(p * 4.3 + vec2(-t * 0.7, t * 1.6)) * 0.2;
	return value;
}

void vertex() {
	world_xz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	float distance_to_center = length(UV - vec2(0.5)) * 2.0;
	float heat = flames(world_xz * grain, TIME * flicker_rate);
	// El borde del disco se come por donde las llamas son flojas, y nunca llega al borde del plano
	// (si no, se vería un corte recto).
	float disc = 1.0 - smoothstep(0.45, 0.95, distance_to_center + (0.5 - heat) * 0.5);
	disc *= 1.0 - smoothstep(0.8, 1.0, distance_to_center);
	float body = smoothstep(0.3, 0.62, heat);
	vec3 color = mix(ember_color.rgb, flame_color.rgb, smoothstep(0.3, 0.55, heat));
	color = mix(color, hot_color.rgb, smoothstep(0.6, 0.78, heat));
	ALBEDO = color * intensity;
	ALPHA = disc * mix(0.25, 1.0, body) * opacity * fade;
}
