shader_type spatial;
// La nube de colonia: una esfera alrededor del jugador, casi transparente por dentro y más densa en
// los bordes (como una pompa de vaho), con jirones que giran despacio. Se aviva con «pulse» (1 = un
// pulso recién soltado, 0 = en reposo). Se ve también desde dentro (la cámara puede quedar dentro si
// el aura es grande).
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec4 color : source_color = vec4(0.45, 0.85, 0.95, 1.0);
// Brillo en reposo y con un pulso.
uniform float rest_alpha = 0.07;
uniform float pulse_alpha = 0.4;
// Cuánto se concentra en los bordes (más = borde más fino).
uniform float rim_power = 3.0;
// Vueltas por segundo de los jirones.
uniform float swirl_speed = 0.15;
instance uniform float pulse = 0.0;

varying vec3 local_position;

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

void vertex() {
	local_position = VERTEX;
}

void fragment() {
	float facing = abs(dot(NORMAL, VIEW));
	float rim = pow(1.0 - facing, rim_power);
	float angle = atan(local_position.z, local_position.x) + TIME * swirl_speed * TAU;
	float wisps = value_noise(vec2(angle * 1.6, local_position.y * 3.0 + TIME * 0.4));
	float strength = mix(rest_alpha, pulse_alpha, pulse);
	ALBEDO = color.rgb;
	ALPHA = clamp(rim * (0.55 + 0.45 * wisps) * strength * 2.0, 0.0, 1.0);
}
