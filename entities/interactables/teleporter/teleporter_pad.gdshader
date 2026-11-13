shader_type spatial;
// Disco del teletransporte: anillos que van hacia el centro, un remolino suave y un borde brillante.
// Va en un PlaneMesh centrado; [radius] es la mitad de su tamaño.
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec4 edge_color : source_color = vec4(0.35, 0.8, 1.0, 1.0);
uniform vec4 core_color : source_color = vec4(0.8, 0.45, 1.0, 1.0);
uniform float intensity = 1.4;
uniform float radius = 1.2;
uniform float ring_count = 4.0;
uniform float ring_speed = 0.6;
uniform float swirl_speed = 2.0;

varying vec2 local_xz;

void vertex() {
	local_xz = VERTEX.xz;
}

void fragment() {
	float r = length(local_xz) / radius;
	float angle = atan(local_xz.y, local_xz.x);
	float rings = fract(r * ring_count + TIME * ring_speed);
	float ring_line = smoothstep(0.0, 0.08, rings) * (1.0 - smoothstep(0.12, 0.3, rings));
	float swirl = 0.5 + 0.5 * sin(angle * 3.0 + r * 18.0 - TIME * swirl_speed);
	float rim = smoothstep(0.84, 0.94, r) * (1.0 - smoothstep(0.96, 1.0, r));
	float disc = 1.0 - smoothstep(0.94, 1.0, r);
	float glow = (ring_line * 0.6 + swirl * 0.25) * disc * (1.0 - r * 0.5) + rim * 1.2;
	ALBEDO = mix(core_color.rgb, edge_color.rgb, r) * intensity;
	ALPHA = clamp(glow, 0.0, 1.0);
}
