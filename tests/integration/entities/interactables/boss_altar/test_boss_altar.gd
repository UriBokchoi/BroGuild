extends GutTest
## Altar del jefe: muestra las llaves que lleva el jugador y, con todas, la columna de luz y el aviso
## de invocar; al usarlo pide sacar al jefe donde aparece; al acabar la ronda lo pide aunque falten;
## cuando sale el jefe se apaga y ya no pide nada.

const AltarScene := preload("res://entities/interactables/boss_altar/boss_altar.tscn")

var _altar: BossAltar
var _requests: Array = []


func before_each() -> void:
	_requests.clear()
	EventBus.boss_summon_requested.connect(_on_request)
	_altar = AltarScene.instantiate() as BossAltar
	add_child_autofree(_altar)


func after_each() -> void:
	EventBus.boss_summon_requested.disconnect(_on_request)


func test_shows_the_keys_the_player_has() -> void:
	EventBus.boss_keys_changed.emit(1, 3)
	assert_eq(_visible_keys(), 1)
	assert_false(_altar.beam.visible)
	assert_eq(String(_altar.interactable.prompt_key), tr(&"BOSS_ALTAR_LOCKED") % [1, 3])
	EventBus.boss_keys_changed.emit(3, 3)
	assert_eq(_visible_keys(), 3)
	assert_true(_altar.beam.visible, "con todas, la columna de luz")
	assert_eq(_altar.interactable.prompt_key, &"BOSS_ALTAR_READY")


func test_using_it_asks_for_the_boss_where_it_appears() -> void:
	_altar.interactable.interact(_altar)
	assert_eq(_requests, [[_altar.boss_spawn.global_position, false]])


func test_at_the_end_of_the_round_it_asks_even_without_keys() -> void:
	EventBus.run_clock_changed.emit(599.0, false)
	assert_eq(_requests.size(), 0)
	EventBus.run_clock_changed.emit(600.0, true)
	assert_eq(_requests, [[_altar.boss_spawn.global_position, true]])


func test_once_the_boss_is_out_it_goes_off() -> void:
	EventBus.boss_keys_changed.emit(3, 3)
	EventBus.boss_spawned.emit(&"ENEMY_ENT_TRAINER_NAME")
	assert_true(_altar.is_used())
	assert_false(_altar.beam.visible)
	assert_false(_altar.interactable.enabled)
	EventBus.run_clock_changed.emit(601.0, true)
	assert_eq(_requests.size(), 0)


func _visible_keys() -> int:
	return _altar.key_slots.filter(func(slot: Node3D) -> bool: return slot.visible).size()


func _on_request(at: Vector3, forced: bool) -> void:
	_requests.append([at, forced])
