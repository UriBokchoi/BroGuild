shader_type spatial;
// Rejilla en espacio de mundo para el greybox: permite medir distancias y alturas
// a ojo. Proyección triplanar, así que se ve igual en suelos, rampas y paredes.

uniform vec3 base_color : source_color = vec3(0.5);
uniform vec3 line_color : source_color = vec3(0.35);
uniform vec3 major_line_color : source_color = vec3(0.2);
uniform float cell_size : hint_range(0.1, 10.0) = 1.0;
uniform int major_every : hint_range(1, 20) = 5;
uniform float line_width : hint_range(0.5, 4.0) = 1.0;
uniform float blend_sharpness : hint_range(1.0, 16.0) = 4.0;
uniform float surface_roughness : hint_range(0.0, 1.0) = 0.9;

varying vec3 world_pos;
varying vec3 world_normal;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

// 1.0 sobre una línea de la rejilla, 0.0 fuera. Ancho constante en píxeles.
float grid_line(vec2 coord) {
	vec2 dist = abs(fract(coord - 0.5) - 0.5) / fwidth(coord);
	return 1.0 - min(min(dist.x, dist.y) / line_width, 1.0);
}

float triplanar_grid(float spacing, vec3 weights) {
	vec3 coord = world_pos / spacing;
	return grid_line(coord.zy) * weights.x
		+ grid_line(coord.xz) * weights.y
		+ grid_line(coord.xy) * weights.z;
}

void fragment() {
	vec3 weights = pow(abs(world_normal), vec3(blend_sharpness));
	weights /= weights.x + weights.y + weights.z;
	float minor = triplanar_grid(cell_size, weights);
	float major = triplanar_grid(cell_size * float(major_every), weights);
	vec3 color = mix(base_color, line_color, minor);
	ALBEDO = mix(color, major_line_color, major);
	ROUGHNESS = surface_roughness;
}
