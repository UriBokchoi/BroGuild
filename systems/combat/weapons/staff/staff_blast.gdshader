shader_type spatial;
// Explosión del orbe del bastón: una esfera que brilla más en el borde y se desvanece.
render_mode unshaded, blend_add, depth_draw_never, cull_back, shadows_disabled;

uniform vec4 core_color : source_color = vec4(1.0, 0.75, 1.0, 1.0);
uniform vec4 rim_color : source_color = vec4(0.65, 0.3, 1.0, 1.0);
uniform float intensity = 1.6;

// 0 → 1 a lo largo de la explosión.
instance uniform float progress = 0.0;

void fragment() {
	float rim = pow(1.0 - abs(dot(NORMAL, VIEW)), 2.0);
	float fade = 1.0 - smoothstep(0.3, 1.0, progress);
	ALBEDO = mix(core_color.rgb, rim_color.rgb, rim) * intensity;
	ALPHA = (0.25 + rim * 0.75) * fade;
}
