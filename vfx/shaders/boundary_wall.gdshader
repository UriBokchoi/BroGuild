shader_type spatial;
// El borde del mapa: una pared de malla de rombos que solo se ve cerca del jugador. Brilla en un
// círculo alrededor de «reveal_center» (lo pone MapBoundary cada fotograma) y se desvanece con la
// distancia; los rombos suben despacio, abajo hay una franja más marcada y por arriba se apaga. Va en
// un QuadMesh vertical (UV.y: 0 arriba, 1 abajo).
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec4 color : source_color = vec4(0.62, 0.9, 1.0, 1.0);
// Dónde está el jugador y a qué distancia la pared se ve del todo y deja de verse (los tres los pone
// MapBoundary).
uniform vec3 reveal_center = vec3(0.0, -1000.0, 0.0);
uniform float reveal_near = 3.0;
uniform float reveal_far = 11.0;
// Lado de los rombos (m), grosor de sus líneas (en partes del lado) y a qué velocidad suben (m/s).
uniform float cell_size = 1.4;
uniform float line_width = 0.04;
uniform float rise_speed = 0.3;
// Opacidad de las líneas, del velo y de la franja de abajo, del todo cerca.
uniform float line_alpha = 0.7;
uniform float fill_alpha = 0.1;
uniform float base_alpha = 0.55;
// Alto de la pared (lo pone MapBoundary) y de la franja de abajo (m).
uniform float wall_height = 8.0;
uniform float base_height = 0.6;

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float reveal = 1.0 - smoothstep(reveal_near, reveal_far, distance(world_position, reveal_center));
	if (reveal <= 0.001) {
		discard;
	}
	// Cada pared es recta en x o en z: su suma sirve para medir a lo largo de cualquiera de ellas.
	float along = world_position.x + world_position.z;
	float rise = 1.0 - UV.y;
	float y = rise * wall_height - TIME * rise_speed;
	vec2 grid = vec2(along + y, along - y) / cell_size;
	vec2 to_line = min(fract(grid), 1.0 - fract(grid));
	float near_line = min(to_line.x, to_line.y);
	float soft = fwidth(near_line);
	float lines = 1.0 - smoothstep(line_width - soft, line_width + soft, near_line);
	float base = 1.0 - smoothstep(0.0, base_height / wall_height, rise);
	float fade_up = 1.0 - smoothstep(0.35, 1.0, rise);
	ALBEDO = color.rgb;
	ALPHA = clamp(max(max(lines * line_alpha, fill_alpha), base * base_alpha) * fade_up * reveal, 0.0, 1.0);
}
