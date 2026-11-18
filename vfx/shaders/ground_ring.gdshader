shader_type spatial;
// Aro en el suelo: la onda del salto del jefe (que se abre), el aviso de dónde va a caer y el brillo
// de los power-ups. Va en un PlaneMesh de 2 × 2 escalado al radio: el aro está a «progress» del
// centro al borde (0–1), tiene «band» de ancho (en la misma escala) y brilla más en el centro de ese
// ancho.
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec4 color : source_color = vec4(1.0, 0.55, 0.2, 1.0);
uniform float intensity = 1.5;
// Pulsos por segundo (el aviso); 0 = fijo.
uniform float pulse_rate = 0.0;
instance uniform float progress = 1.0;
instance uniform float band = 0.1;
instance uniform float fade = 1.0;

void fragment() {
	float d = length(UV - vec2(0.5)) * 2.0;
	float ring = 1.0 - smoothstep(0.0, band * 0.5, abs(d - progress));
	float pulse = pulse_rate > 0.0 ? 0.65 + 0.35 * sin(TIME * pulse_rate * TAU) : 1.0;
	ALBEDO = color.rgb * intensity;
	ALPHA = ring * fade * pulse * color.a;
}
