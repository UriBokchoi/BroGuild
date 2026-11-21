class_name ScreenShake
extends Node
## Temblor de cámara al recibir daño. Cada golpe a [member health] suma «trauma» según la parte de
## la vida que quita (con un mínimo, para que hasta un roce se note) y el trauma baja solo. La cámara
## se desplaza ([member Camera3D.h_offset], [member Camera3D.v_offset]) y se inclina tanto como el
## trauma al cuadrado, con ruido suave: un roce apenas la mueve y un golpe fuerte la sacude. Solo
## visual.

## Cámara que tiembla.
@export var camera: Camera3D
## Vida cuyos golpes la hacen temblar.
@export var health: HealthComponent
## Trauma de un golpe que quitara toda la vida (los demás, en proporción).
@export_range(0.0, 5.0, 0.05) var trauma_per_health: float = 0.0
## Trauma mínimo de un golpe.
@export_range(0.0, 1.0, 0.01) var min_trauma: float = 0.0
## Trauma que se pierde por segundo.
@export_range(0.1, 10.0, 0.1, "suffix:1/s") var decay: float = 1.0
## Desplazamiento con trauma 1.
@export_range(0.0, 1.0, 0.01, "suffix:m") var max_offset: float = 0.0
## Inclinación con trauma 1.
@export_range(0.0, 10.0, 0.1, "radians_as_degrees") var max_roll: float = 0.0
## Rapidez del ruido: más, temblor más nervioso.
@export_range(1.0, 60.0, 0.5, "suffix:Hz") var frequency: float = 1.0

var _trauma: float = 0.0
var _time: float = 0.0
var _noise := FastNoiseLite.new()


func _ready() -> void:
	_noise.frequency = 1.0
	if health:
		health.damaged.connect(_on_damaged)
	set_process(false)


## Suma [param amount] de trauma (entre 0 y 1 en total), por el temblor que haya elegido el jugador
## en las opciones ([member GameSettings.screen_shake]; a 0, nada).
func add_trauma(amount: float) -> void:
	var intensity := Save.settings.screen_shake if Save.settings else 1.0
	_trauma = clampf(_trauma + amount * intensity, 0.0, 1.0)
	if _trauma <= 0.0:
		return
	set_process(true)


## Trauma ahora (0–1).
func get_trauma() -> float:
	return _trauma


func _process(delta: float) -> void:
	_time += delta
	_trauma = maxf(_trauma - decay * delta, 0.0)
	var shake := _trauma * _trauma
	var at := _time * frequency
	camera.h_offset = max_offset * shake * _noise.get_noise_2d(at, 0.0)
	camera.v_offset = max_offset * shake * _noise.get_noise_2d(at, 100.0)
	camera.rotation.z = max_roll * shake * _noise.get_noise_2d(at, 200.0)
	if _trauma <= 0.0:
		# Exactamente a cero (el ruido por cero deja un -0).
		camera.h_offset = 0.0
		camera.v_offset = 0.0
		camera.rotation.z = 0.0
		set_process(false)


func _on_damaged(amount: float, _info: DamageInfo) -> void:
	var maximum := health.get_maximum()
	var share := amount / maximum if maximum > 0.0 else 1.0
	add_trauma(maxf(min_trauma, share * trauma_per_health))
