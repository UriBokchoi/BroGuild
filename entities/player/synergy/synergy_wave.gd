class_name SynergyWave
extends Node
## Mejora de movimiento que suelta una [Shockwave] desde los pies del jugador: al entrar en
## [member enter_state] (la onda del dash) o al aterrizar de [member slam_state] (la explosión de la
## caída rápida). Daña [member damage_stat] (0 sin su objeto: entonces no sale nada) con el daño % y
## el crítico del jugador, y su radio crece con el área %. Tiene [member pool_size] ondas, por si se
## encadenan; si todas están en marcha, reinicia la primera. Al soltarla lo avisa por
## [signal EventBus.synergy_released] (el sonido) y por [signal released] (el temblor de pantalla).

## Se soltó una onda desde [param at], que hace temblar la pantalla [param trauma].
signal released(at: Vector3, trauma: float)

## Stats del jugador (su [MovementSynergyData] y su [OffenseData]).
@export var stats: StatsComponent
## Stat de [MovementSynergyData] con el daño de la onda.
@export var damage_stat: StringName = &""
## De dónde sale (los pies del jugador).
@export var body: Node3D
## Máquina del movimiento, para [member enter_state].
@export var machine: StateMachine
## Estado que la suelta al entrar (el dash). Vacío si la suelta [member slam_state].
@export var enter_state: State
## Caída rápida que la suelta al aterrizar. Vacío si la suelta [member enter_state].
@export var slam_state: FastFallState
## La onda (una escena con [Shockwave]: su radio, duración, empuje y color).
@export var wave_scene: PackedScene
## Ondas a la vez como mucho.
@export_range(1, 8, 1) var pool_size: int = 2
## Temblor de pantalla al soltarla ([ScreenShake]; 0 = ninguno).
@export_range(0.0, 1.0, 0.01) var trauma: float = 0.0

var _waves: Array[Shockwave] = []


func _ready() -> void:
	for index: int in pool_size:
		var wave := wave_scene.instantiate() as Shockwave
		add_child(wave)
		_waves.append(wave)
	if machine and enter_state:
		machine.state_changed.connect(_on_state_changed)
	if slam_state:
		slam_state.slammed.connect(_on_slammed)


## Suelta una onda desde los pies de [member body] si la mejora tiene daño. Devuelve si salió.
func release() -> bool:
	var damage := stats.get_value(damage_stat)
	if damage <= 0.0:
		return false
	var offense := stats.find_resolved(OffenseData) as OffenseData
	var size := offense.area / 100.0 if offense else 1.0
	var at := body.global_position
	_free_wave().start(at, damage, offense, size)
	released.emit(at, trauma)
	EventBus.synergy_released.emit(damage_stat, at)
	return true


## Ondas en marcha ahora mismo.
func running() -> int:
	var count := 0
	for wave: Shockwave in _waves:
		if wave.is_running():
			count += 1
	return count


## Las ondas de la reserva (para los tests).
func waves() -> Array[Shockwave]:
	return _waves.duplicate()


func _free_wave() -> Shockwave:
	for wave: Shockwave in _waves:
		if not wave.is_running():
			return wave
	return _waves[0]


func _on_state_changed(_previous: State, current: State) -> void:
	if current == enter_state:
		release()


func _on_slammed(_impact_speed: float) -> void:
	release()
