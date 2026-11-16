class_name WaveDirector
extends Node
## Director de oleadas: mientras está en marcha, saca enemigos en un [EnemySwarm] alrededor de
## [member target] al ritmo de su [WaveData] (que sube con el tiempo y tiene picos), sin pasar del
## máximo a la vez. Cada enemigo aparece en el suelo, a una distancia al azar entre la mínima y la
## máxima de los datos; si ahí no hay suelo (fuera del mapa), prueba otro punto. Cada uno sale con
## las stats de su minuto ([method WaveData.scaling_at]) y puede salir élite con la probabilidad de
## ese minuto ([method WaveData.elite_chance_at]). Mientras está en marcha, es el reloj de la ronda:
## avisa del tiempo cada segundo por [code]EventBus.run_clock_changed[/code].

signal started
signal stopped

@export var data: WaveData
@export var swarm: EnemySwarm
## Alrededor de quién salen (el jugador).
@export var target: Node3D
## Empieza en cuanto entra en el árbol.
@export var autostart: bool = false
## Capas de física que cuentan como suelo para aparecer.
@export_flags_3d_physics var ground_mask: int = 1
## Altura sobre y bajo el objetivo en la que se busca suelo.
@export_range(1.0, 200.0, 1.0, "suffix:m") var probe_height: float = 30.0
## Puntos que prueba para cada enemigo antes de dejarlo para el siguiente tick.
@export_range(1, 32, 1) var placement_attempts: int = 6

## Azar de las oleadas. Si no se asigna antes de entrar en el árbol, el flujo de oleadas de
## [code]Rng[/code].
var rng: RandomNumberGenerator

var _running: bool = false
var _elapsed: float = 0.0
## Enemigos que ya tocaba sacar y aún no han salido (fracción acumulada).
var _pending: float = 0.0


func _ready() -> void:
	if rng == null:
		rng = Rng.stream(Rng.Stream.WAVES)
	if autostart:
		start()


func _physics_process(delta: float) -> void:
	if not _running or target == null:
		return
	var previous := _elapsed
	_elapsed += delta
	if floori(_elapsed) != floori(previous):
		_announce_clock()
	_pending += data.rate_at(_elapsed) * delta
	while _pending >= 1.0:
		if swarm.active_count() >= data.max_alive:
			# En el máximo no se acumulan: al bajar, siguen al ritmo normal.
			_pending = 0.0
			return
		if not _spawn_one():
			return
		_pending -= 1.0


## Empieza (o vuelve a empezar) desde el minuto 0.
func start() -> void:
	_elapsed = 0.0
	_pending = 0.0
	_running = true
	started.emit()
	_announce_clock()


## Para. Con [param clear_enemies], retira también a los enemigos en juego.
func stop(clear_enemies: bool = true) -> void:
	_running = false
	if clear_enemies:
		swarm.clear()
	stopped.emit()
	EventBus.run_clock_changed.emit(-1.0, false)


func is_running() -> bool:
	return _running


## Segundos desde que empezó.
func get_elapsed() -> float:
	return _elapsed


func _spawn_one() -> bool:
	var enemy := data.pick_enemy(_elapsed, rng)
	if enemy == null:
		return false
	var feet := _find_spawn_point()
	if not feet.is_finite():
		return false
	var spawned := swarm.spawn(enemy, feet)
	spawned.boost(data.scaling_at(_elapsed))
	if rng.randf() * 100.0 < data.elite_chance_at(_elapsed):
		spawned.promote(data.elite)
	return true


## Avisa al HUD del tiempo de la ronda (una vez por segundo).
func _announce_clock() -> void:
	EventBus.run_clock_changed.emit(_elapsed, data.is_overtime(_elapsed))


## Un punto en el suelo a la distancia de los datos, o [code]Vector3.INF[/code] si no lo encuentra.
func _find_spawn_point() -> Vector3:
	var center := target.global_position
	var space := target.get_world_3d().direct_space_state
	for _attempt: int in placement_attempts:
		var angle := rng.randf() * TAU
		var distance := rng.randf_range(data.min_spawn_distance, data.max_spawn_distance)
		var spot := center + Vector3(cos(angle), 0.0, sin(angle)) * distance
		var from := spot + Vector3.UP * probe_height
		var to := spot + Vector3.DOWN * probe_height
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(from, to, ground_mask))
		if not hit.is_empty():
			var feet: Vector3 = hit["position"]
			return feet
	return Vector3.INF
