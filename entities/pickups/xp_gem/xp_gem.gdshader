shader_type spatial;
// Gema de experiencia: gira y flota sola (en el shader, sin coste por nodo), cada una con su desfase
// según dónde está, y brilla.

// De instancia: cada gema toma el color de su nivel (PickupTier) sin material propio.
instance uniform vec4 color : source_color = vec4(0.3, 0.75, 1.0, 1.0);
uniform float glow = 1.6;
uniform float spin_speed = 2.0;
uniform float bob_height = 0.08;
uniform float bob_speed = 3.0;

void vertex() {
	float phase = NODE_POSITION_WORLD.x * 1.7 + NODE_POSITION_WORLD.z * 2.3;
	float angle = TIME * spin_speed + phase;
	mat2 spin = mat2(vec2(cos(angle), -sin(angle)), vec2(sin(angle), cos(angle)));
	VERTEX.xz = spin * VERTEX.xz;
	NORMAL.xz = spin * NORMAL.xz;
	VERTEX.y += sin(TIME * bob_speed + phase) * bob_height;
}

void fragment() {
	ALBEDO = color.rgb;
	EMISSION = color.rgb * glow;
	ROUGHNESS = 0.25;
	METALLIC = 0.3;
}
