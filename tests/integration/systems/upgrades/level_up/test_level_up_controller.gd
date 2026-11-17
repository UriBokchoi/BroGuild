extends GutTest
## Elección al subir de nivel con el jugador de verdad: al subir, se pausa y salen las cartas; la
## elegida se aplica; varios niveles de golpe dan varias elecciones; Esc no la salta; las armas
## nuevas necesitan una ranura abierta; sin nada que ofrecer, o muerto, no pregunta.

const PlayerScene := preload("res://entities/player/player.tscn")
const PanelScene := preload("res://ui/menus/level_up/level_up_panel.tscn")
const LEVEL_UP := preload("res://data/progression/level_up.tres")

var _player: Player
var _panel: LevelUpPanel
var _controller: LevelUpController


func before_each() -> void:
	_player = PlayerScene.instantiate() as Player
	add_child_autofree(_player)
	_panel = PanelScene.instantiate() as LevelUpPanel
	add_child_autofree(_panel)
	_controller = LevelUpController.new()
	_controller.data = LEVEL_UP
	_controller.player = _player
	_controller.panel = _panel
	_controller.rng = RandomNumberGenerator.new()
	_controller.rng.seed = 5
	add_child_autofree(_controller)


func after_each() -> void:
	# Nunca dejar el árbol en pausa: GUT se quedaría parado.
	get_tree().paused = false


func test_leveling_up_pauses_and_shows_the_choices() -> void:
	EventBus.player_leveled_up.emit(2)
	assert_true(_panel.is_open())
	assert_true(get_tree().paused)
	assert_eq(_panel.get_cards().size(), LEVEL_UP.choices)


func test_the_chosen_option_is_applied() -> void:
	EventBus.player_leveled_up.emit(2)
	var option := _panel.get_cards()[0].option
	_panel.get_cards()[0].pressed.emit()
	assert_false(_panel.is_open())
	assert_false(get_tree().paused)
	if option.item is WeaponData:
		assert_true(_player.weapons.has(option.item as WeaponData))
	else:
		assert_eq(_player.runes.get_level(option.item as RuneData), 1)


func test_several_levels_give_several_choices() -> void:
	EventBus.player_leveled_up.emit(2)
	EventBus.player_leveled_up.emit(3)
	assert_eq(_controller.pending(), 2)
	_panel.get_cards()[0].pressed.emit()
	await get_tree().process_frame
	assert_true(_panel.is_open(), "queda otra")
	assert_eq(_controller.pending(), 1)
	_panel.get_cards()[0].pressed.emit()
	assert_false(_panel.is_open())


func test_escape_does_not_skip_the_choice() -> void:
	EventBus.player_leveled_up.emit(2)
	var event := InputEventAction.new()
	event.action = InputActions.PAUSE
	event.pressed = true
	_panel._input(event)
	assert_true(_panel.is_open())


func test_nothing_to_offer_asks_nothing() -> void:
	for item: Resource in ResourceDir.load_all(LEVEL_UP.weapons_dir, WeaponData):
		var weapon := _player.weapons.add(item as WeaponData)
		weapon.set_level((item as WeaponData).max_level())
	for item: Resource in ResourceDir.load_all(LEVEL_UP.runes_dir, RuneData):
		_player.runes.set_level(item as RuneData, (item as RuneData).max_level())
	EventBus.player_leveled_up.emit(2)
	assert_false(_panel.is_open())
	assert_eq(_controller.pending(), 0)


func test_a_dead_player_chooses_nothing() -> void:
	_player.health.take_damage(DamageInfo.create(100000.0))
	EventBus.player_leveled_up.emit(2)
	assert_false(_panel.is_open(), "las gemas que aún volaban no abren las cartas")
	assert_eq(_controller.pending(), 0)


func test_new_weapons_need_an_open_slot() -> void:
	# Todas las runas al máximo y tantas armas al máximo como ranuras abiertas: no queda nada que
	# ofrecer hasta que se abre otra ranura de armas.
	for item: Resource in ResourceDir.load_all(LEVEL_UP.runes_dir, RuneData):
		_player.runes.set_level(item as RuneData, (item as RuneData).max_level())
	var weapons := ResourceDir.load_all(LEVEL_UP.weapons_dir, WeaponData)
	for index: int in _player.stats.get_int(&"weapon_slots") - _player.weapons.get_weapons().size():
		_player.weapons.add(weapons[index] as WeaponData)
	for weapon: Weapon in _player.weapons.get_weapons():
		weapon.set_level(weapon.data.max_level())
	EventBus.player_leveled_up.emit(2)
	assert_false(_panel.is_open(), "sin ranura, ninguna arma nueva")
	var extra := StatModifier.new()
	extra.stat = &"weapon_slots"
	extra.value = 1.0
	_player.stats.add_modifier(extra, self)
	EventBus.player_leveled_up.emit(3)
	assert_true(_panel.is_open(), "con otra ranura, sí")
	for card: LevelUpCard in _panel.get_cards():
		assert_true(card.option.is_new() and card.option.item is WeaponData)
