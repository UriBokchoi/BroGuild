shader_type canvas_item;
// Filtro del tiempo parado: la pantalla, desaturada y teñida de azul, tanto como «strength» (0–1).

uniform sampler2D screen : hint_screen_texture, filter_linear_mipmap;
uniform vec4 tint : source_color = vec4(0.4, 0.62, 1.0, 1.0);
// Cuánto gris antes de teñir (0 = colores tal cual).
uniform float desaturation : hint_range(0.0, 1.0) = 0.7;
// Brillo del tinte (el gris teñido se oscurece).
uniform float brightness = 1.3;
uniform float strength : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec3 color = texture(screen, SCREEN_UV).rgb;
	float grey = dot(color, vec3(0.299, 0.587, 0.114));
	vec3 tinted = mix(color, vec3(grey), desaturation) * tint.rgb * brightness;
	COLOR = vec4(mix(color, tinted, strength), 1.0);
}
