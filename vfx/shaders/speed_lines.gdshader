// Líneas de velocidad: rayas radiales en los bordes de la pantalla que parpadean. Su intensidad la
// pone SpeedLines según la velocidad (0 = no se ven).
shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 line_color : source_color = vec4(1.0, 0.96, 0.88, 0.35);
// Número de rayas posibles alrededor de la pantalla.
uniform float line_count = 120.0;
// Parte de las rayas que se ve a la vez (0–1).
uniform float density : hint_range(0.0, 1.0) = 0.3;
// Grosor de cada raya (fracción de su hueco).
uniform float thickness : hint_range(0.0, 0.5) = 0.07;
// Distancia al centro (0 = centro, 1 = borde) a partir de la que empiezan.
uniform float inner_radius : hint_range(0.0, 1.0) = 0.75;
// Cambios de rayas por segundo.
uniform float flicker = 12.0;

float hash(float n) {
	return fract(sin(n) * 43758.5453);
}

void fragment() {
	vec2 centered = SCREEN_UV - vec2(0.5);
	// Corrige la proporción de la pantalla para que las rayas salgan del centro en línea recta.
	centered.x *= SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	float radius = length(centered) * 2.0;
	float cell = (atan(centered.y, centered.x) / TAU + 0.5) * line_count;
	float line = 1.0 - smoothstep(thickness * 0.5, thickness, abs(fract(cell) - 0.5));
	float alive = step(1.0 - density, hash(floor(cell) + floor(TIME * flicker) * 17.0));
	float edge = smoothstep(inner_radius, inner_radius + 0.4, radius);
	COLOR = vec4(line_color.rgb, line_color.a * line * alive * edge * intensity);
}
