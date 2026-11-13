extends GutTest
## Armería: al interactuar abre su panel con todas las armas de data/weapons; el panel equipa,
## quita y cambia de nivel las armas del jugador, pausa el juego y se cierra con Esc.

const PlayerScene := preload("res://entities/player/player.tscn")
const ArmoryScene := preload("res://entities/interactables/armory/armory.tscn")
const SWORD := preload("res://data/weapons/sword.tres")

var _player: Player
var _armory: Armory


func before_each() -> void:
	_player = PlayerScene.instantiate() as Player
	add_child_autofree(_player)
	_armory = ArmoryScene.instantiate() as Armory
	add_child_autofree(_armory)


func after_each() -> void:
	# Nunca dejar el árbol en pausa: GUT se quedaría parado.
	get_tree().paused = false


func test_interacting_opens_the_panel_with_every_weapon() -> void:
	_armory.interactable.interact(_player)
	assert_true(_armory.panel.is_open())
	assert_true(get_tree().paused)
	var weapon_count := ResourceDir.load_all("res://data/weapons", WeaponData).size()
	assert_eq(_armory.panel.get_rows().size(), weapon_count)


func test_rows_equip_level_and_remove_weapons() -> void:
	_armory.interactable.interact(_player)
	var row := _sword_row()
	row.equip_toggled.emit(SWORD)
	var sword := _player.weapons.get_weapon(SWORD)
	assert_not_null(sword, "equipada")
	row.level_stepped.emit(SWORD, 1)
	assert_eq(sword.level, 2)
	row.level_stepped.emit(SWORD, -1)
	assert_eq(sword.level, 1)
	row.equip_toggled.emit(SWORD)
	assert_false(_player.weapons.has(SWORD), "quitada")


func test_escape_closes_without_opening_the_pause() -> void:
	_armory.interactable.interact(_player)
	var event := InputEventAction.new()
	event.action = InputActions.PAUSE
	event.pressed = true
	_armory.panel._input(event)
	assert_false(_armory.panel.is_open())
	assert_false(get_tree().paused)


func _sword_row() -> ArmoryRow:
	for row: ArmoryRow in _armory.panel.get_rows():
		if row.data.id == SWORD.id:
			return row
	return null
