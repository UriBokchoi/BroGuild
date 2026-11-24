class_name Crosshair
extends Control
## La mira en el centro de la pantalla: un círculo con un punto, solo mientras se apunta con el clic
## derecho.

## Radio del círculo y grosor de la línea, en píxeles.
@export_range(2.0, 64.0, 1.0, "suffix:px") var radius: float = 11.0
@export_range(1.0, 8.0, 0.5, "suffix:px") var width: float = 2.0
@export var color: Color = Color(1.0, 1.0, 1.0, 0.9)
## El borde oscuro, para que se vea sobre cualquier fondo.
@export var outline: Color = Color(0.0, 0.0, 0.0, 0.55)


func _enter_tree() -> void:
	if not EventBus.aim_changed.is_connected(_on_aim_changed):
		EventBus.aim_changed.connect(_on_aim_changed)


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, outline, width + 2.0, true)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, color, width, true)
	draw_circle(Vector2.ZERO, width + 1.0, outline)
	draw_circle(Vector2.ZERO, width, color)


func _on_aim_changed(aiming: bool) -> void:
	visible = aiming
