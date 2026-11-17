shader_type spatial;
// Destello de lo que se puede usar con «interactuar», encima de sus mallas (material_overlay): un
// borde de luz suave y, cada tanto, una franja que lo recorre de abajo arriba. La franja es un plano
// algo inclinado que barre el mundo hacia arriba: las piezas de un objeto destellan a la vez y cada
// objeto, a su momento.
render_mode unshaded, blend_add, depth_draw_never, cull_back, shadows_disabled;

uniform vec4 color : source_color = vec4(1.0, 0.92, 0.7, 1.0);
// Brillo del borde (0 = sin borde) y lo pegado al borde que queda.
uniform float rim = 0.15;
uniform float rim_power = 3.0;
// Franja: segundos entre una y la siguiente (en un mismo sitio), su velocidad hacia arriba, ancho y
// brillo.
uniform float sweep_period = 3.5;
uniform float sweep_speed = 2.0;
uniform float sweep_width = 0.18;
uniform float sweep = 0.5;
// Inclinación de la franja (metros de altura por metro en x y en z).
uniform vec2 tilt = vec2(0.3, 0.2);

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float edge = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), rim_power) * rim;
	float spacing = sweep_period * sweep_speed;
	float height = world_position.y + dot(world_position.xz, tilt);
	float behind = fract((height - TIME * sweep_speed) / spacing) * spacing;
	float distance_to_band = min(behind, spacing - behind);
	float band = (1.0 - smoothstep(0.0, sweep_width, distance_to_band)) * sweep;
	ALBEDO = color.rgb;
	ALPHA = clamp(edge + band, 0.0, 1.0) * color.a;
}
