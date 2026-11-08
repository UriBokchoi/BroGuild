// Fondo de los menús: difumina lo que hay detrás (mipmaps de la pantalla) y lo tiñe.
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
// Nivel de mipmap: cuanto más alto, más difuminado.
uniform float blur_lod : hint_range(0.0, 8.0) = 2.5;
// Color del tinte; su alfa es cuánto tapa la imagen.
uniform vec4 tint : source_color = vec4(0.05, 0.06, 0.09, 0.55);

void fragment() {
	vec3 background = textureLod(screen_texture, SCREEN_UV, blur_lod).rgb;
	COLOR = vec4(mix(background, tint.rgb, tint.a), 1.0);
}
