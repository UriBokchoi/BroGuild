shader_type spatial;
// Moneda de oro: de pie, gira sobre sí misma y brilla (en el shader, sin coste por nodo), cada una
// con su desfase según dónde está. Destella cuando se pone de cara (al girar) y su brillo late.

uniform vec4 color : source_color = vec4(1.0, 0.78, 0.25, 1.0);
uniform float glow = 0.9;
uniform float spin_speed = 5.0;
// Cuánto late el brillo y a qué ritmo.
uniform float pulse = 0.4;
uniform float pulse_speed = 3.0;
// Destello al ponerse de cara a la cámara.
uniform float flash = 1.2;
uniform float flash_power = 8.0;

varying float phase;

void vertex() {
	// El cilindro de la malla tiene su eje en Y: se pone de pie (eje en Z) para que se vea la cara.
	VERTEX = vec3(VERTEX.x, -VERTEX.z, VERTEX.y);
	NORMAL = vec3(NORMAL.x, -NORMAL.z, NORMAL.y);
	phase = NODE_POSITION_WORLD.x * 1.7 + NODE_POSITION_WORLD.z * 2.3;
	float angle = TIME * spin_speed + phase;
	mat2 spin = mat2(vec2(cos(angle), -sin(angle)), vec2(sin(angle), cos(angle)));
	VERTEX.xz = spin * VERTEX.xz;
	NORMAL.xz = spin * NORMAL.xz;
}

void fragment() {
	ALBEDO = color.rgb;
	float beat = 1.0 + pulse * sin(TIME * pulse_speed + phase);
	float facing = pow(clamp(dot(NORMAL, VIEW), 0.0, 1.0), flash_power);
	EMISSION = color.rgb * glow * beat + vec3(1.0, 0.95, 0.8) * facing * flash;
	ROUGHNESS = 0.3;
	METALLIC = 0.8;
}
