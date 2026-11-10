class_name CameraRig
extends Node3D
## Cámara en tercera persona: orbita alrededor de [member target] con el ratón y se aleja un
## poco con [member level] (curva en [CameraData]). Su [SpringArm3D] solo choca con el mundo,
## para no meterse en paredes ni suelo.
##
## Va con [code]top_level[/code] y sin interpolación de física: se mueve cada frame en
## [code]_process[/code] siguiendo la posición interpolada del objetivo, así que va fluida a
## cualquier tasa de refresco.

## Parámetros de la cámara ([code]data/player/camera.tres[/code]).
@export var data: CameraData
## Nodo al que sigue (el jugador). Sin objetivo, orbita alrededor de donde esté.
@export var target: Node3D
## Nivel del personaje. Para probar la curva, cámbialo en vivo desde el inspector remoto.
@export_range(1, 100, 1, "or_greater") var level: int = 1:
	set(value):
		level = value
		if is_node_ready() and data != null:
			_apply_distance()

var _yaw: float = 0.0
var _pitch: float = 0.0

@onready var _spring_arm: SpringArm3D = %SpringArm3D
@onready var _camera: Camera3D = %Camera3D


func _ready() -> void:
	if data == null:
		push_error("CameraRig: falta 'data' (CameraData).")
		set_process(false)
		set_process_unhandled_input(false)
		return
	_camera.fov = data.fov
	_yaw = target.global_rotation.y if target else rotation.y
	_pitch = data.initial_pitch
	_apply_rotation()
	_apply_distance()
	_follow_target()


func _process(delta: float) -> void:
	_follow_target()
	_update_fov(delta)


func _unhandled_input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if motion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# screen_relative no depende del escalado de la ventana: misma sensibilidad a cualquier resolución.
		rotate_view(motion.screen_relative)


## Gira la vista según un movimiento de ratón en píxeles (x: giro, y: inclinación).
func rotate_view(pixels: Vector2) -> void:
	var radians_per_pixel := deg_to_rad(data.mouse_sensitivity)
	_yaw = wrapf(_yaw - pixels.x * radians_per_pixel, -PI, PI)
	_pitch = clampf(_pitch - pixels.y * radians_per_pixel, data.pitch_min, data.pitch_max)
	_apply_rotation()


## Giro horizontal de la cámara en radianes: define el «adelante» del movimiento.
func get_yaw() -> float:
	return _yaw


func _apply_rotation() -> void:
	rotation = Vector3(_pitch, _yaw, 0.0)


func _apply_distance() -> void:
	_spring_arm.spring_length = data.distance_at(level)


## Abre el FOV con la velocidad horizontal del objetivo (si es un cuerpo que se mueve), suavizado.
func _update_fov(delta: float) -> void:
	var body := target as CharacterBody3D
	var speed := Vector2(body.velocity.x, body.velocity.z).length() if body else 0.0
	var weight := 1.0 - exp(-data.fov_smoothing * delta)
	_camera.fov = lerpf(_camera.fov, data.fov_at(speed), weight)


func _follow_target() -> void:
	if target == null:
		return
	var feet := target.get_global_transform_interpolated().origin
	global_position = feet + Vector3.UP * data.pivot_height
