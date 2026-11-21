extends GutTest
## Doble o nada en el panel de subir de nivel: al elegir una mejora que puede subir, se decide si
## quedársela o apostarla; la apuesta gira y cae en la carta ganadora (más rara) o se pierde (en
## gris, sin opción). Las míticas y los objetos nuevos no se apuestan.

const PanelScene := preload("res://ui/menus/level_up/level_up_panel.tscn")
const SWORD := preload("res://data/weapons/sword.tres")
const RARE := preload("res://data/rarities/rare.tres")
const IMPROBABLE := preload("res://data/rarities/improbable.tres")
const MYTHIC := preload("res://data/rarities/mythic.tres")

var _panel: LevelUpPanel
var _rng := RandomNumberGenerator.new()


func before_each() -> void:
	_panel = PanelScene.instantiate() as LevelUpPanel
	add_child_autofree(_panel)


func after_each() -> void:
	get_tree().paused = false


func test_choosing_an_upgrade_asks_keep_or_bet() -> void:
	var card := _open([_upgrade(RARE)])[0]
	watch_signals(_panel)
	card.pressed.emit()
	assert_eq(_panel.get_phase(), LevelUpPanel.Phase.BETTING)
	assert_true((_panel.get_node(^"%Bet") as Control).visible)
	assert_signal_not_emitted(_panel, "chosen", "aún no")
	(_panel.get_node(^"%Keep") as Button).pressed.emit()
	assert_signal_emitted_with_parameters(_panel, "chosen", [card.option])


func test_betting_asks_for_the_result() -> void:
	var card := _open([_upgrade(RARE)])[0]
	card.pressed.emit()
	watch_signals(_panel)
	(_panel.get_node(^"%Double") as Button).pressed.emit()
	assert_signal_emitted_with_parameters(_panel, "double_requested", [card.option])


func test_a_won_bet_lands_on_the_better_card() -> void:
	var card := _open([_upgrade(RARE)])[0]
	card.pressed.emit()
	watch_signals(_panel)
	watch_signals(EventBus)
	var better := _upgrade(IMPROBABLE)
	_panel.resolve_double(better)
	assert_eq(_panel.get_cards()[0].option, better, "la ganadora en su sitio")
	await _wait_result()
	assert_signal_emitted_with_parameters(EventBus, "double_or_nothing_resolved", [true])
	assert_signal_emitted_with_parameters(_panel, "chosen", [better])


func test_a_lost_bet_greys_the_card_and_gives_nothing() -> void:
	var card := _open([_upgrade(RARE)])[0]
	card.pressed.emit()
	watch_signals(_panel)
	_panel.resolve_double(null)
	await _wait_result()
	assert_true(card.is_lost())
	assert_signal_emitted_with_parameters(_panel, "chosen", [null])


func test_mythics_and_new_items_are_chosen_straight_away() -> void:
	var cards := _open([_upgrade(MYTHIC), LevelUpOption.create(SWORD, 1)])
	watch_signals(_panel)
	cards[0].pressed.emit()
	assert_signal_emitted_with_parameters(_panel, "chosen", [cards[0].option])
	assert_eq(_panel.get_phase(), LevelUpPanel.Phase.CHOOSING)
	assert_false(_panel.can_double(cards[1].option), "un objeto nuevo no tiene rareza")


func _open(options: Array[LevelUpOption]) -> Array[LevelUpCard]:
	_panel.open(options, 3, &"", 10, true, 0.5)
	_panel.stop_spins()
	return _panel.get_cards()


func _upgrade(rarity: Rarity) -> LevelUpOption:
	return LevelUpOption.create_upgrade(SWORD, 2, SWORD.roll_upgrade(rarity, _rng))


## Lo que tarda en girar la apuesta y verse el resultado (el panel pausa: temporizador en pausa).
func _wait_result() -> void:
	var data := _panel.data
	await get_tree().create_timer(data.double_spin_time + data.double_result_time + 0.2, true).timeout
