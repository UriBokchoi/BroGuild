class_name Compass
extends Control
## Brújula del HUD, abajo a la izquierda: un disco con N, E, S y O que gira con la cámara (arriba, hacia
## donde mira). El norte es −Z del mundo. Solo dibuja; lee la cámara activa en cada fotograma.

## Letras de los puntos cardinales, de N a O en el sentido de las agujas del reloj (claves de
## traducción).
@export var cardinal_keys: Array[StringName] = [&"COMPASS_N", &"COMPASS_E", &"COMPASS_S", &"COMPASS_W"]
@export var disc_color: Color = Color(0.09, 0.1, 0.13, 0.7)
@export var ring_color: Color = Color(0.93, 0.9, 0.85, 0.85)
@export var letter_color: Color = Color(0.93, 0.9, 0.85, 1.0)
## Color de la N.
@export var north_color: Color = Color(0.93, 0.42, 0.42, 1.0)
@export_range(8, 48, 1) var font_size: int = 16
## Grosor del aro.
@export_range(0.5, 8.0, 0.5) var ring_width: float = 2.0

## Rumbo de la cámara (radianes, de 0 = norte en el sentido de las agujas del reloj).
var _heading: float = 0.0


func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var heading := heading_of(-camera.global_basis.z)
	if not is_equal_approx(heading, _heading):
		_heading = heading
		queue_redraw()


## Rumbo hacia el que apunta [param forward] en el suelo (0 = norte, −Z; π/2 = este, +X).
static func heading_of(forward: Vector3) -> float:
	return atan2(forward.x, -forward.z)


## Rumbo que enseña ahora.
func get_heading() -> float:
	return _heading


func _draw() -> void:
	var center := size / 2.0
	var radius := minf(size.x, size.y) / 2.0
	draw_circle(center, radius, disc_color)
	draw_arc(center, radius - ring_width, 0.0, TAU, 48, ring_color, ring_width, true)
	# El triángulo de arriba: hacia donde mira la cámara.
	var tip := center + Vector2(0.0, -radius + ring_width * 2.0)
	draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-5.0, 8.0), tip + Vector2(5.0, 8.0)]), ring_color)
	var font := get_theme_default_font()
	for index: int in cardinal_keys.size():
		var angle := TAU * index / cardinal_keys.size() - _heading
		var at := center + Vector2(sin(angle), -cos(angle)) * (radius * 0.62)
		var text := tr(cardinal_keys[index])
		var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var color := north_color if index == 0 else letter_color
		draw_string(font, at + Vector2(-text_size.x / 2.0, text_size.y / 3.0), text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
