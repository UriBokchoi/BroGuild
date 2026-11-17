shader_type spatial;
// Columna de luz (teletransporte, altar y llaves del jefe): se desvanece hacia arriba, con franjas
// que suben y bordes suaves (más opaca donde la superficie se ve de canto). Va en un CylinderMesh
// abierto y centrado.
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec4 color : source_color = vec4(0.4, 0.8, 1.0, 1.0);
uniform float intensity = 0.9;
uniform float height = 3.0;
uniform float stripe_count = 6.0;
uniform float stripe_speed = 0.8;

varying float height_fraction;

void vertex() {
	height_fraction = VERTEX.y / height + 0.5;
}

void fragment() {
	float fade = pow(1.0 - clamp(height_fraction, 0.0, 1.0), 2.0);
	float stripes = 0.6 + 0.4 * sin((height_fraction * stripe_count - TIME * stripe_speed) * TAU);
	float edge = pow(1.0 - abs(dot(NORMAL, VIEW)), 2.0);
	ALBEDO = color.rgb * intensity;
	ALPHA = fade * stripes * (0.2 + edge * 0.8) * color.a;
}
