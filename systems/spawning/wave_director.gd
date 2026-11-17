class_name WaveDirector
extends Node
## Director de oleadas: mientras está en marcha, saca enemigos en un [EnemySwarm] alrededor de
## [member target] al ritmo de su [WaveData] (con picos), sin pasar del máximo a la vez. Cada enemigo
## aparece en el suelo, a una distancia al azar entre la mínima y la máxima de los datos; si ahí no
## hay suelo (fuera del mapa), prueba otro punto.
##
## Todo depende de la [b]dificultad[/b] ([method get_difficulty]): cuántos salen, cuáles, cuántos
## élites ([method WaveData.elite_chance_at]) y con qué stats ([method WaveData.scaling_at]). Es la
## stat [code]difficulty[/code] de [member difficulty_stats] (el jugador): el director le suma 1 por
## minuto en marcha y los objetos o runas pueden subirla más. Mientras está en marcha, es también el
## reloj de la ronda: avisa del tiempo cada segundo por [code]EventBus.run_clock_changed[/code].
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
## Stats donde vive la dificultad (las del jugador): el director le suma la parte del tiempo. Vacío:
## la dificultad son los minutos en marcha.
@export var difficulty_stats: StatsComponent
## Puntos que prueba para cada enemigo antes de dejarlo para el siguiente tick.
@export_range(1, 32, 1) var placement_attempts: int = 6

## Azar de las oleadas. Si no se asigna antes de entrar en el árbol, el flujo de oleadas de
## [code]Rng[/code].
var rng: RandomNumberGenerator

var _running: bool = false
var _elapsed: float = 0.0
## Enemigos que ya tocaba sacar y aún no han salido (fracción acumulada).
var _pending: float = 0.0
## Parte de la dificultad que sube con el tiempo (1 por minuto), sobre [member difficulty_stats].
var _time_difficulty := StatModifier.create(&"difficulty", StatModifier.Kind.FLAT, 0.0)


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
		_tick_second()
	_pending += data.rate_at(get_difficulty(), _elapsed) * delta
	while _pending >= 1.0:
		if swarm.active_count() >= data.max_alive:
			# En el máximo no se acumulan: al bajar, siguen al ritmo normal.
			_pending = 0.0
			return
		if not _spawn_one():
			return
		_pending -= 1.0


## Empieza (o vuelve a empezar) desde el minuto 0 (la parte del tiempo de la dificultad, también).
func start() -> void:
	_elapsed = 0.0
	_pending = 0.0
	_running = true
	started.emit()
	_tick_second()


## Para. Con [param clear_enemies], retira también a los enemigos en juego.
func stop(clear_enemies: bool = true) -> void:
	_running = false
	if clear_enemies:
		swarm.clear()
	if difficulty_stats:
		difficulty_stats.remove_modifiers_from(self)
	stopped.emit()
	EventBus.run_clock_changed.emit(-1.0, false)


func is_running() -> bool:
	return _running


## Dificultad ahora: la stat [code]difficulty[/code] de [member difficulty_stats] (con la parte del
## tiempo) o, sin ellas, los minutos en marcha.
func get_difficulty() -> float:
	if difficulty_stats:
		return difficulty_stats.get_value(&"difficulty")
	return _elapsed / 60.0


## Segundos desde que empezó.
func get_elapsed() -> float:
	return _elapsed


## Saca de golpe [param count] élites alrededor de [member target] (la maldición de la tragaperras),
## aunque no esté en marcha ni haya sitio en el máximo a la vez. Devuelve cuántos salieron.
func spawn_elites(count: int) -> int:
	if data == null or data.elite == null:
		return 0
	var spawned := 0
	for _elite: int in count:
		var enemy := _spawn_at_difficulty(get_difficulty())
		if enemy == null:
			continue
		enemy.promote(data.elite)
		spawned += 1
	return spawned


func _spawn_one() -> bool:
	var difficulty := get_difficulty()
	var spawned := _spawn_at_difficulty(difficulty)
	if spawned == null:
		return false
	if rng.randf() * 100.0 < data.elite_chance_at(difficulty):
		spawned.promote(data.elite)
	return true


## Un enemigo de los datos en un punto del suelo, con el escalado de [param difficulty], o
## [code]null[/code] si no hay enemigo o sitio.
func _spawn_at_difficulty(difficulty: float) -> Enemy:
	var enemy := data.pick_enemy(difficulty, rng)
	if enemy == null:
		return null
	var feet := _find_spawn_point()
	if not feet.is_finite():
		return null
	var spawned := swarm.spawn(enemy, feet)
	spawned.boost(data.scaling_at(difficulty))
	return spawned


## Cada segundo: sube la parte del tiempo de la dificultad y avisa al HUD del reloj.
func _tick_second() -> void:
	if difficulty_stats:
		difficulty_stats.remove_modifiers_from(self)
		_time_difficulty.value = _elapsed / 60.0
		difficulty_stats.add_modifier(_time_difficulty, self)
	_announce_clock()


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
