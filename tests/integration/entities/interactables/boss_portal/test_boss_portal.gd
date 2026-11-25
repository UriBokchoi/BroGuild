extends GutTest
## Portal del jefe: muestra las llaves que lleva el jugador y, con todas, la columna de luz y el aviso
## de abrirlo; al usarlo pide sacar al jefe donde aparece; al acabar la ronda lo pide aunque falten;
## cuando sale el jefe ya no pide nada. Al vencer al jefe se abre (el remolino se aviva y avisa de
## dónde está la puerta) y cruzarlo, solo el jugador y una vez, pasa el nivel.

const PortalScene := preload("res://entities/interactables/boss_portal/boss_portal.tscn")
const PlayerScene := preload("res://entities/player/player.tscn")

var _portal: BossPortal
var _requests: Array = []
var _opened: Array[Vector3] = []
var _exits: int = 0


func before_each() -> void:
	_requests.clear()
	_opened.clear()
	_exits = 0
	EventBus.boss_summon_requested.connect(_on_request)
	EventBus.boss_portal_opened.connect(_on_opened)
	EventBus.level_exit_reached.connect(_on_exit)
	_portal = PortalScene.instantiate() as BossPortal
	add_child_autofree(_portal)


func after_each() -> void:
	EventBus.boss_summon_requested.disconnect(_on_request)
	EventBus.boss_portal_opened.disconnect(_on_opened)
	EventBus.level_exit_reached.disconnect(_on_exit)


func test_shows_the_keys_the_player_has() -> void:
	EventBus.boss_keys_changed.emit(1, 3)
	assert_eq(_visible_keys(), 1)
	assert_false(_portal.beam.visible)
	assert_eq(String(_portal.interactable.prompt_key), tr(&"BOSS_PORTAL_LOCKED") % [1, 3])
	EventBus.boss_keys_changed.emit(3, 3)
	assert_eq(_visible_keys(), 3)
	assert_true(_portal.beam.visible, "con todas, la columna de luz")
	assert_eq(_portal.interactable.prompt_key, &"BOSS_PORTAL_READY")


func test_using_it_asks_for_the_boss_where_it_appears() -> void:
	_portal.interactable.interact(_portal)
	assert_eq(_requests, [[_portal.boss_spawn.global_position, false]])


func test_at_the_end_of_the_round_it_asks_even_without_keys() -> void:
	EventBus.run_clock_changed.emit(599.0, false)
	assert_eq(_requests.size(), 0)
	EventBus.run_clock_changed.emit(600.0, true)
	assert_eq(_requests, [[_portal.boss_spawn.global_position, true]])


func test_once_the_boss_is_out_it_stops_asking() -> void:
	EventBus.boss_keys_changed.emit(3, 3)
	EventBus.boss_spawned.emit(&"ENEMY_ENT_TRAINER_NAME")
	assert_true(_portal.is_used())
	assert_false(_portal.beam.visible)
	assert_false(_portal.interactable.enabled)
	assert_false(_portal.is_open(), "con el jefe vivo, cerrado")
	EventBus.run_clock_changed.emit(601.0, true)
	assert_eq(_requests.size(), 0)


func test_beating_the_boss_opens_it_and_only_the_player_crosses_it() -> void:
	var player := PlayerScene.instantiate() as Player
	add_child_autofree(player)
	_portal.exit_area.body_entered.emit(player)
	assert_eq(_exits, 0, "cerrado no deja pasar")
	EventBus.boss_spawned.emit(&"ENEMY_ENT_TRAINER_NAME")
	EventBus.boss_defeated.emit(&"BROSQUE_VICTORY", 120.0, 2.0)
	assert_true(_portal.is_open())
	assert_eq(_opened, [_portal.exit_position()] as Array[Vector3], "avisa de dónde está la puerta")
	await wait_seconds(_portal.open_time + 0.1)
	var charge: float = _portal.vortex.get_instance_shader_parameter(&"charge")
	assert_almost_eq(charge, 1.0, 0.01, "remolino a tope")
	_portal.exit_area.body_entered.emit(autofree(StaticBody3D.new()))
	assert_eq(_exits, 0, "solo cuenta el jugador")
	_portal.exit_area.body_entered.emit(player)
	_portal.exit_area.body_entered.emit(player)
	assert_eq(_exits, 1, "una sola vez")


func _visible_keys() -> int:
	return _portal.key_slots.filter(func(slot: Node3D) -> bool: return slot.visible).size()


func _on_request(at: Vector3, forced: bool) -> void:
	_requests.append([at, forced])


func _on_opened(at: Vector3) -> void:
	_opened.append(at)


func _on_exit() -> void:
	_exits += 1
