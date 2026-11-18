shader_type spatial;
// Gema de experiencia: gira y flota sola (en el shader, sin coste por nodo), cada una con su desfase
// según dónde está, y brilla: su brillo late y sus bordes destellan en blanco, para que se vea entre
// la horda.

// De instancia: cada gema toma el color de su nivel (PickupTier) sin material propio.
instance uniform vec4 color : source_color = vec4(0.3, 0.75, 1.0, 1.0);
uniform float glow = 1.6;
uniform float spin_speed = 2.0;
uniform float bob_height = 0.08;
uniform float bob_speed = 3.0;
// Cuánto late el brillo (0 = fijo) y a qué ritmo.
uniform float pulse = 0.5;
uniform float pulse_speed = 4.0;
// Destello blanco de los bordes.
uniform float sparkle = 1.2;
uniform float sparkle_power = 3.0;

varying float phase;

void vertex() {
	phase = NODE_POSITION_WORLD.x * 1.7 + NODE_POSITION_WORLD.z * 2.3;
	float angle = TIME * spin_speed + phase;
	mat2 spin = mat2(vec2(cos(angle), -sin(angle)), vec2(sin(angle), cos(angle)));
	VERTEX.xz = spin * VERTEX.xz;
	NORMAL.xz = spin * NORMAL.xz;
	VERTEX.y += sin(TIME * bob_speed + phase) * bob_height;
}

void fragment() {
	float beat = 1.0 + pulse * sin(TIME * pulse_speed + phase);
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), sparkle_power);
	ALBEDO = color.rgb;
	EMISSION = color.rgb * glow * beat + vec3(1.0) * rim * sparkle;
	ROUGHNESS = 0.25;
	METALLIC = 0.3;
}
