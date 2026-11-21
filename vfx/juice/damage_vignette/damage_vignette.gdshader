shader_type canvas_item;
// Borde de la pantalla teñido de «color», tanto como «strength» (0–1): nada en el centro y más
// hacia los bordes, con forma casi rectangular (como la pantalla).

uniform vec4 color : source_color = vec4(0.62, 0.0, 0.03, 1.0);
uniform float strength : hint_range(0.0, 1.0) = 0.0;
// Dónde empieza el borde (0 = centro, 1 = borde de la pantalla).
uniform float inner : hint_range(0.0, 1.0) = 0.55;
// Lo cuadrado que es (2 = elipse; más, más rectangular).
uniform float squareness : hint_range(2.0, 12.0) = 5.0;

void fragment() {
	vec2 q = abs(UV - 0.5) * 2.0;
	float d = pow(pow(q.x, squareness) + pow(q.y, squareness), 1.0 / squareness);
	float edge = smoothstep(inner, 1.15, d);
	COLOR = vec4(color.rgb, color.a * edge * strength);
}
