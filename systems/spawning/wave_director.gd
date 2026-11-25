class_name WaveDirector
extends Node
## Saca enemigos alrededor del jugador al ritmo de su WaveData, sin pasar del máximo a la vez, y
## siempre sobre suelo de verdad. Mientras está en marcha es también el reloj de la ronda: avisa
## cada segundo y suma 1 de dificultad por minuto.
##
## La dificultad lo decide casi todo: cuántos salen, cuáles, cuántos son élites y lo fuertes que son.
## Las hordas salen a su minuto, avisadas unos segundos antes, y no cuentan para el máximo.

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
## Zona del suelo (x, z) donde pueden salir (dentro de las paredes del nivel). Vacía: en cualquier
## sitio con suelo.
@export var play_area: Rect2 = Rect2()
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
## Siguiente horda de [member WaveData.hordes] por avisar o sacar, y si ya se avisó.
var _horde_index: int = 0
var _horde_warned: bool = false
## Horda que está saliendo: enemigos y élites que le quedan y la fracción acumulada.
var _horde: HordeData
var _horde_left: int = 0
var _horde_elites_left: int = 0
var _horde_pending: float = 0.0


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
	_update_hordes(delta)
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
	_horde_index = 0
	_horde_warned = false
	_horde_left = 0
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


## Saca [param count] enemigos de [param enemy] en el suelo alrededor de [param center], entre
## [param min_distance] y [param max_distance], con el escalado de la dificultad de ahora, aunque no
## esté en marcha ni haya sitio en el máximo a la vez (los refuerzos de un jefe). Devuelve cuántos
## salieron.
func spawn_around(enemy: EnemyData, center: Vector3, count: int, min_distance: float, max_distance: float) -> int:
	if enemy == null:
		return 0
	var modifiers := data.scaling_at(get_difficulty()) if data else null
	var spawned := 0
	for _index: int in count:
		if spawn_one_around(enemy, center, min_distance, max_distance, modifiers):
			spawned += 1
	return spawned


## Saca un [param enemy] en el suelo alrededor de [param center], entre [param min_distance] y
## [param max_distance], con las mejoras [param modifiers] (o sin ellas), aunque no esté en marcha ni
## haya sitio en el máximo a la vez (un miniboss). Devuelve el enemigo, o [code]null[/code] si no
## encontró suelo.
func spawn_one_around(
	enemy: EnemyData, center: Vector3, min_distance: float, max_distance: float, modifiers: StatModifierSet = null
) -> Enemy:
	var feet := _find_ground(center, min_distance, max_distance)
	if not feet.is_finite():
		return null
	var spawned := swarm.spawn(enemy, feet)
	spawned.boost(modifiers)
	return spawned


## Avisa de la siguiente horda a su hora y la saca repartida en su tiempo.
func _update_hordes(delta: float) -> void:
	if _horde_index < data.hordes.size():
		var next := data.hordes[_horde_index]
		if not _horde_warned and _elapsed >= next.at_seconds() - next.warning_seconds:
			_horde_warned = true
			EventBus.horde_incoming.emit(next, maxf(next.at_seconds() - _elapsed, 0.0))
			if not next.announce_key.is_empty():
				EventBus.announced.emit(next.announce_key, [], next.announce_color)
		if _elapsed >= next.at_seconds():
			_horde = next
			_horde_left = next.count
			_horde_elites_left = mini(next.elites, next.count)
			_horde_pending = 0.0
			_horde_index += 1
			_horde_warned = false
	if _horde_left <= 0:
		return
	# Sin tiempo de salida, sale entera en este tick.
	var rate := _horde.count / _horde.spawn_seconds if _horde.spawn_seconds > 0.0 else INF
	_horde_pending = minf(_horde_pending + rate * delta, _horde_left)
	while _horde_pending >= 1.0 and _horde_left > 0:
		_horde_pending -= 1.0
		_horde_left -= 1
		var enemy := _spawn_at_difficulty(get_difficulty())
		if enemy and _horde_elites_left > 0 and data.elite:
			enemy.promote(data.elite)
			_horde_elites_left -= 1


## Enemigos de la horda que aún no han salido.
func horde_left() -> int:
	return _horde_left


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
	var feet := _find_ground(target.global_position, data.min_spawn_distance, data.max_spawn_distance)
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


## Un punto en el suelo alrededor de [param center], entre [param min_distance] y [param max_distance]
## (dentro de [member play_area]), o [code]Vector3.INF[/code] si no lo encuentra.
func _find_ground(center: Vector3, min_distance: float, max_distance: float) -> Vector3:
	var space := target.get_world_3d().direct_space_state
	for _attempt: int in placement_attempts:
		var angle := rng.randf() * TAU
		var distance := rng.randf_range(min_distance, max_distance)
		var spot := center + Vector3(cos(angle), 0.0, sin(angle)) * distance
		if play_area.has_area() and not play_area.has_point(Vector2(spot.x, spot.z)):
			continue
		var from := spot + Vector3.UP * probe_height
		var to := spot + Vector3.DOWN * probe_height
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(from, to, ground_mask))
		if not hit.is_empty():
			var feet: Vector3 = hit["position"]
			return feet
	return Vector3.INF
