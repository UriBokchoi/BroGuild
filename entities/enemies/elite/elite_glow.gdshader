shader_type spatial;
// Brillo de élite: un borde de luz que late, sumado encima del modelo (material_overlay).
render_mode unshaded, blend_add, depth_draw_never;

uniform vec4 color : source_color = vec4(1.0, 0.78, 0.25, 1.0);
// Lo fino del borde: más alto, más fino.
uniform float rim_power = 2.2;
// Luz que suma también en el centro (0 = solo el borde).
uniform float base = 0.12;
uniform float pulse_speed = 4.0;

void fragment() {
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), rim_power);
	float pulse = 0.8 + 0.2 * sin(TIME * pulse_speed);
	ALBEDO = color.rgb * (rim * 1.6 + base) * pulse;
}
