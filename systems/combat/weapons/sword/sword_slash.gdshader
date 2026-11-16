shader_type spatial;
// Tajo en arco: una media luna que barre de un lado a otro delante del plano (hacia −Z) y se
// desvanece. Se dibuja en un PlaneMesh centrado en quien golpea; el alcance (radio exterior) es 1.
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

// Cuerpo del tajo y filo (el borde exterior, más brillante).
uniform vec4 body_color : source_color = vec4(1.0, 0.72, 0.28, 1.0);
uniform vec4 edge_color : source_color = vec4(1.0, 0.97, 0.88, 1.0);
uniform float intensity = 1.6;
// Ángulo que barre y largo de la estela, en grados.
uniform float arc_degrees = 160.0;
uniform float trail_degrees = 120.0;
// Radio interior del arco en su parte más gruesa (el exterior es 1).
uniform float inner_radius = 0.35;
// Parte del tajo (0–1) en la que acaba el barrido; el resto se desvanece.
uniform float sweep_end = 0.5;

// 0 → 1 a lo largo del tajo; 1 o −1 según el lado hacia el que barre.
instance uniform float progress = 0.0;
instance uniform float direction = 1.0;

varying vec2 local_xz;

void vertex() {
	local_xz = VERTEX.xz;
}

void fragment() {
	float radius = length(local_xz);
	// 0° = hacia delante (−Z); positivo hacia +X (o al revés si barre al otro lado).
	float angle = degrees(atan(local_xz.x, -local_xz.y)) * direction;
	float half_arc = arc_degrees * 0.5;
	float sweep = 1.0 - pow(1.0 - clamp(progress / sweep_end, 0.0, 1.0), 3.0);
	float lead = mix(-half_arc, half_arc, sweep);
	float behind = lead - angle;
	float inside = step(0.0, behind) * step(-half_arc, angle);
	float trail = pow(clamp(1.0 - behind / trail_degrees, 0.0, 1.0), 1.4);
	// Media luna: gruesa junto al filo que avanza, fina en la cola.
	float inner = mix(0.94, inner_radius, trail);
	float band = smoothstep(inner, inner + 0.15, radius) * (1.0 - smoothstep(0.96, 1.0, radius));
	float rim = smoothstep(0.82, 0.95, radius) * (1.0 - smoothstep(0.97, 1.0, radius));
	float fade = 1.0 - smoothstep(sweep_end, 1.0, progress);
	float alpha = band * trail * inside * fade;
	vec3 color = mix(body_color.rgb, edge_color.rgb, clamp(rim + trail * trail * 0.5, 0.0, 1.0));
	ALBEDO = color * intensity;
	ALPHA = alpha;
}
