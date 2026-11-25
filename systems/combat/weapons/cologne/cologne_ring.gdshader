shader_type spatial;
// El alcance de la nube de colonia, dibujado en el suelo (como en Megabonk): un disco de radio 1 en un
// plano de 2 × 2 con un aro de trazos en el borde, otro aro fino un poco más dentro con marcas y un
// velo muy tenue que se aclara hacia el centro. El nodo lo hace girar despacio. Se aviva con «pulse»
// (1 = un pulso recién soltado, 0 = en reposo).
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec4 color : source_color = vec4(0.45, 0.85, 0.95, 1.0);
// Trazos del aro de fuera y cuánto de cada hueco ocupan.
uniform float dashes = 28.0;
uniform float dash_fill = 0.62;
// Ancho del aro de fuera y del de dentro (en radio: 1 = todo el disco).
uniform float outer_width = 0.045;
uniform float inner_width = 0.012;
// Dónde va el aro de dentro y cuántas marcas lleva.
uniform float inner_radius = 0.86;
uniform float ticks = 8.0;
// Opacidad del aro de fuera, del de dentro y del velo, en reposo.
uniform float outer_alpha = 0.75;
uniform float inner_alpha = 0.4;
uniform float fill_alpha = 0.07;
// Cuánto más se ve todo con un pulso.
uniform float pulse_boost = 0.6;
instance uniform float pulse = 0.0;

// Una banda de [from, to] en «value», con el borde suavizado a un píxel.
float band(float value, float from, float to) {
	float soft = fwidth(value);
	return smoothstep(from - soft, from + soft, value) * (1.0 - smoothstep(to - soft, to + soft, value));
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float radius = length(p);
	float turn = atan(p.y, p.x) / TAU + 0.5;
	float dash = band(fract(turn * dashes), 0.0, dash_fill);
	float outer = band(radius, 1.0 - outer_width, 1.0) * dash;
	// Marcas: trocitos cortos hacia dentro desde el aro de dentro.
	float tick = band(fract(turn * ticks + 0.5 / ticks), 0.0, 0.012 * ticks) * band(radius, inner_radius - 0.07, inner_radius);
	float inner = max(band(radius, inner_radius - inner_width, inner_radius), tick);
	float fill = fill_alpha * smoothstep(0.15, 1.0, radius) * step(radius, 1.0);
	float boost = 1.0 + pulse * pulse_boost;
	ALBEDO = color.rgb * (1.0 + pulse * 0.5);
	ALPHA = clamp(max(max(outer * outer_alpha, inner * inner_alpha), fill * (1.0 + pulse * 3.0)) * boost, 0.0, 1.0);
}
