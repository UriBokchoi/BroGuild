shader_type spatial;
// Remolino del portal del jefe: un disco en un plano de 2 × 2 (el aro de piedra lo enmarca) con brazos
// en espiral que giran y un núcleo que brilla. «charge» dice en qué punto está: 0 apagado (violeta y
// tenue), 0,5 vivo y 1 abierto (dorado, brillante y girando más deprisa).
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec4 closed_color : source_color = vec4(0.5, 0.38, 0.85, 1.0);
uniform vec4 open_color : source_color = vec4(1.0, 0.78, 0.32, 1.0);
// Vueltas por segundo con el portal apagado (abierto, el doble).
uniform float swirl_speed = 0.3;
// Brazos de la espiral.
uniform float arms = 3.0;
// Cuánto se retuercen los brazos hacia el centro.
uniform float twist = 7.0;
instance uniform float charge = 0.0;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float radius = length(p);
	float angle = atan(p.y, p.x);
	float turn = TIME * swirl_speed * TAU * (1.0 + charge);
	float spiral = sin(angle * arms + radius * twist - turn) * 0.5 + 0.5;
	float core = 1.0 - smoothstep(0.0, 0.9, radius);
	// Se apaga en el borde del disco (y nada fuera de él).
	float inside = 1.0 - smoothstep(0.82, 1.0, radius);
	vec3 color = mix(closed_color.rgb, open_color.rgb, charge);
	ALBEDO = color * (0.6 + charge * 1.6);
	ALPHA = clamp((spiral * 0.6 + core * 0.8) * inside * (0.25 + charge * 0.75), 0.0, 1.0);
}
