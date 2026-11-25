class_name LevelStages
extends Node3D
## Las fases de una partida en un nivel con tiers: juega los tiers en orden hasta el elegido y, tras
## el último tier del nivel, la arena del jefe final. Al cruzar el portal de una fase que no es la
## última, funde a negro y cambia el mapa: el jugador sigue con todo lo suyo (nivel, armas, objetos,
## oro y pactos), el reloj vuelve a 0 y la dificultad sube.
##
## Va antes que RunSystems en la escena del nivel: le pone las oleadas, el jefe y el punto de
## aparición del primer mapa antes de que arranque.

## Grupo donde está (el panel de depuración lo busca ahí).
const GROUP := &"level_stages"
## Los sistemas de la partida (jugador, oleadas, jefe…).
@export var systems: RunSystems
## Tiers del nivel, en orden.
@export var tiers: Array[StageData] = []
## La arena del jefe final, tras el último tier (vacío: no hay).
@export var final_stage: StageData
## Tier hasta el que se juega si no se eligió ninguno (al ejecutar el nivel solo).
@export_range(1, 10, 1) var default_tier: int = 1
## Negro del fundido entre fases.
@export var fade: CanvasItem
## Segundos del fundido (de ida y de vuelta).
@export_range(0.05, 3.0, 0.05, "suffix:s") var fade_time: float = 0.0
## Al cruzar el portal: segundos antes de fundir a negro, mientras el jugador entra en él (encoge) y
## los enemigos se hunden en el suelo.
@export_range(0.0, 3.0, 0.05, "suffix:s") var enter_time: float = 0.0
## Tamaño al que encoge el jugador al entrar en el portal.
@export_range(0.01, 1.0, 0.01) var enter_scale: float = 1.0

## Las fases de esta partida, en orden.
var _plan: Array[StageData] = []
var _index: int = -1
var _map: LevelMap
var _changing: bool = false
## Dificultad de la fase, sobre las stats del jugador.
var _difficulty := StatModifier.create(&"difficulty", StatModifier.Kind.FLAT, 0.0)


func _enter_tree() -> void:
	add_to_group(GROUP)
	# Antes que RunSystems: el primer mapa tiene que estar para que el jugador aparezca en él.
	if _index >= 0:
		return
	_plan = plan_for(chosen_tier())
	if _plan.is_empty():
		return
	_index = 0
	_build_map(_plan[0])
	_configure_systems()


func _ready() -> void:
	if fade:
		fade.visible = false
	if _map == null:
		return
	systems.encounter.stage_cleared.connect(advance)
	EventBus.run_won.connect(_on_run_won)
	# Las stats del jugador están listas cuando lo está todo RunSystems.
	if systems.is_node_ready():
		_start_stage()
	else:
		systems.ready.connect(_start_stage, CONNECT_ONE_SHOT)


## Tier elegido para esta partida (el de RunState, o [member default_tier] sin nivel elegido).
func chosen_tier() -> int:
	return clampi(RunState.tier if RunState.level else default_tier, 1, maxi(tiers.size(), 1))


## Fases de una partida hasta el tier [param tier]: los tiers del 1 a ese y, si es el último del
## nivel, la arena final.
func plan_for(tier: int) -> Array[StageData]:
	var plan: Array[StageData] = tiers.slice(0, clampi(tier, 0, tiers.size()))
	if final_stage and tier >= tiers.size() and not tiers.is_empty():
		plan.append(final_stage)
	return plan


## Fase en juego (desde 0), o −1 si no hay.
func get_index_playing() -> int:
	return _index


## Cuántas fases tiene esta partida.
func get_stage_count() -> int:
	return _plan.size()


## El mapa en juego.
func get_map() -> LevelMap:
	return _map


## Pasa a la fase siguiente con un fundido a negro (si la hay y no está ya cambiando).
func advance() -> void:
	if _changing or _index + 1 >= _plan.size():
		return
	_changing = true
	# Diferido: se cruza el portal en plena física, y retirar cuerpos ahí no se puede.
	_retire_stage.call_deferred(enter_time + fade_time)
	if fade == null or fade_time <= 0.0:
		# Después de retirar lo de ahora (también diferido).
		_finish_advance.call_deferred()
		return
	_enter_portal()
	fade.modulate.a = 0.0
	fade.visible = true
	var tween := create_tween()
	tween.tween_interval(enter_time)
	tween.tween_property(fade, ^"modulate:a", 1.0, fade_time)
	tween.tween_callback(_finish_advance)
	tween.tween_property(fade, ^"modulate:a", 0.0, fade_time)
	tween.tween_callback(func() -> void: fade.visible = false)


## Depuración: pasa a la fase siguiente de todo el nivel, aunque la partida acabara en esta.
func skip() -> void:
	var full := plan_for(tiers.size())
	if _plan.size() < full.size():
		_plan = full
		systems.encounter.ends_run = _index == _plan.size() - 1
	advance()


## Cambia ya a la fase siguiente, sin fundido (los tests).
func advance_now() -> void:
	if _changing or _index + 1 >= _plan.size():
		return
	_changing = true
	_retire_stage(0.0)
	_finish_advance()


## Retira lo de la fase que acaba: los enemigos se hunden en el suelo en [param vanish_time] (sin
## botín), y se van los minibosses, el heraldo y los recogibles (la experiencia y el oro del suelo se
## dan).
func _retire_stage(vanish_time: float) -> void:
	systems.director.stop(false)
	systems.director.swarm.vanish_all(vanish_time)
	systems.mini_bosses.reset()
	systems.herald.dismiss()
	systems.pickups.collect_all(&"experience")
	systems.pickups.collect_all(&"gold")
	systems.pickups.clear()


func _finish_advance() -> void:
	_index += 1
	# Los que aún no hubieran acabado de hundirse.
	systems.director.swarm.clear()
	remove_child(_map)
	_map.free()
	_build_map(_plan[_index])
	_configure_systems()
	systems.apply_map_settings()
	systems.player.teleport_to(_map.spawn_point.global_position)
	_leave_portal()
	_start_stage()
	_changing = false


## El jugador entra en el portal: se queda quieto (sin control) y encoge mientras la pantalla funde.
func _enter_portal() -> void:
	var player := systems.player
	player.process_mode = Node.PROCESS_MODE_DISABLED
	if player.model:
		var tween := create_tween()
		tween.tween_property(player.model, ^"scale", Vector3.ONE * enter_scale, enter_time + fade_time) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)


## Sale del portal en el mapa nuevo: vuelve su tamaño y su control.
func _leave_portal() -> void:
	var player := systems.player
	player.process_mode = Node.PROCESS_MODE_INHERIT
	if player.model:
		player.model.scale = Vector3.ONE


func _build_map(stage: StageData) -> void:
	_map = stage.map.instantiate() as LevelMap
	_map.attach(systems.player)
	add_child(_map)


## Le pasa a RunSystems lo del mapa: oleadas, jefe, zona de juego, punto de aparición y mensajes.
func _configure_systems() -> void:
	var stage := _plan[_index]
	systems.waves = _map.waves
	systems.autostart_waves = _map.autostart_waves and not _map.waves_after_boss
	systems.play_area = _map.play_area
	systems.play_radius = _map.play_radius
	systems.spawn_point = _map.spawn_point
	systems.boss = _map.boss
	var keys: Array[StringName] = [stage.name_key]
	keys.append_array(_map.intro_keys)
	systems.intro_keys = keys
	# Lo que sale durante la fase (cofres de élite, el heraldo) es del mapa y se va con él.
	systems.loot.chest_parent = _map
	systems.herald.parent = _map
	var encounter := systems.encounter
	encounter.ends_run = _index == _plan.size() - 1
	encounter.death_wins = _map.death_wins_after_boss


## Arranca la fase: su dificultad, el jefe y las oleadas si tocan y el aviso de que empezó.
func _start_stage() -> void:
	var stats := systems.player.stats
	stats.remove_modifiers_from(self)
	_difficulty.value = _plan[_index].difficulty
	if _difficulty.value != 0.0:
		stats.add_modifier(_difficulty, self)
	# Antes de que arranque su reloj: quien cuenta el tiempo de la partida suma la fase nueva.
	EventBus.stage_started.emit(_plan[_index].name_key, _index, _plan.size())
	if _index > 0:
		systems.encounter.reset(_map.boss)
		if systems.autostart_waves:
			systems.director.start()
		if not systems.intro_keys.is_empty():
			EventBus.level_intro.emit(systems.intro_keys)
	if _map.waves_after_boss and not EventBus.boss_defeated.is_connected(_on_boss_defeated):
		EventBus.boss_defeated.connect(_on_boss_defeated, CONNECT_ONE_SHOT)
	if _map.boss_spawn:
		systems.encounter.summon(_map.boss_spawn.global_position)


## La oleada infinita de la arena final: empieza al vencer al jefe.
func _on_boss_defeated(_victory_key: StringName, _seconds: float, _bonus: float) -> void:
	systems.director.start()


## Ganar la partida en un nivel con tiers desbloquea el siguiente.
func _on_run_won(_victory_key: StringName, _seconds: float, _bonus: float) -> void:
	if RunState.level:
		Save.complete_tier(RunState.level.id, chosen_tier())
