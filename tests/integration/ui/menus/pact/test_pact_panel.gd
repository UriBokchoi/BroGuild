extends GutTest
## Pactos del Gremio: el panel se abre con los pactos (una carta por pacto, con el premio y la
## maldición) y pausa; al elegir uno, el premio y la maldición van a las stats del jugador y el HUD lo
## avisa; al rechazarlos, nada cambia. Volver a tirar cuesta oro, cada vez más, y trae otros pactos.

const PanelScene := preload("res://ui/menus/pact/pact_panel.tscn")
const EGO_LIFTING := preload("res://data/pacts/ego_lifting.tres")
const ALL_IN := preload("res://data/pacts/all_in.tres")
const CHEAT_MEAL := preload("res://data/pacts/cheat_meal.tres")
const HERALD := preload("res://data/pacts/herald.tres")
const PLAYER_DATA: Array[String] = [
	"res://data/player/offense.tres",
	"res://data/player/health.tres",
	"res://data/player/movement.tres",
	"res://data/player/stamina.tres",
	"res://data/player/progression.tres",
	"res://data/player/movement_synergy.tres",
]

var _panel: PactPanel
var _stats: StatsComponent
var _wallet: WalletComponent
var _announced: Array = []


func before_each() -> void:
	_stats = StatsComponent.new()
	for path: String in PLAYER_DATA:
		_stats.sources.append(load(path))
	add_child_autofree(_stats)
	_wallet = WalletComponent.new()
	_wallet.stats = _stats
	add_child_autofree(_wallet)
	_panel = PanelScene.instantiate() as PactPanel
	_panel.stats = _stats
	_panel.wallet = _wallet
	_panel.data = HERALD
	_panel.rng = RandomNumberGenerator.new()
	_panel.rng.seed = 3
	add_child_autofree(_panel)
	_announced.clear()
	EventBus.announced.connect(_on_announced)


func after_each() -> void:
	EventBus.announced.disconnect(_on_announced)
	get_tree().paused = false


func test_sealing_a_pact_adds_its_reward_and_its_curse() -> void:
	var pacts: Array[PactData] = [EGO_LIFTING, ALL_IN, CHEAT_MEAL]
	EventBus.pact_offered.emit(pacts)
	assert_true(_panel.is_open())
	assert_true(get_tree().paused)
	var cards := _panel.get_cards()
	assert_eq(cards.size(), 3)
	var damage := _stats.get_value(&"damage")
	var health := _stats.get_value(&"max_health")
	watch_signals(EventBus)
	cards[0].pressed.emit()
	assert_signal_emitted_with_parameters(EventBus, "pact_sealed", [EGO_LIFTING])
	assert_false(_panel.is_open())
	assert_false(get_tree().paused)
	assert_gt(_stats.get_value(&"damage"), damage, "el premio")
	assert_lt(_stats.get_value(&"max_health"), health, "y la maldición")
	assert_eq(_panel.get_sealed().size(), 1)
	assert_eq(_panel.get_sealed()[0], EGO_LIFTING)
	assert_eq(_announced.size(), 1, "el HUD lo avisa")


func test_rejecting_changes_nothing() -> void:
	var pacts: Array[PactData] = [ALL_IN, CHEAT_MEAL]
	EventBus.pact_offered.emit(pacts)
	var luck := _stats.get_value(&"luck")
	var difficulty := _stats.get_value(&"difficulty")
	_panel.reject()
	assert_false(_panel.is_open())
	assert_false(get_tree().paused)
	assert_eq(_stats.get_value(&"luck"), luck)
	assert_eq(_stats.get_value(&"difficulty"), difficulty)
	assert_true(_panel.get_sealed().is_empty())


func test_reroll_costs_more_each_time_and_brings_other_pacts() -> void:
	var first := HERALD.reroll_cost_at(0)
	var second := HERALD.reroll_cost_at(1)
	assert_gt(second, first, "cada vez más caro")
	_wallet.add(float(first + second))
	var pacts: Array[PactData] = [EGO_LIFTING, ALL_IN, CHEAT_MEAL]
	EventBus.pact_offered.emit(pacts)
	assert_eq(_panel.reroll_cost(), first)
	assert_true(_panel.can_reroll())
	assert_true(_panel.reroll())
	assert_almost_eq(_wallet.get_gold(), float(second), 0.01, "cobra")
	var shown: Array[PactData] = []
	for card: PactCard in _panel.get_cards():
		shown.append(card.pact)
	assert_eq(shown.size(), HERALD.choices)
	for pact: PactData in pacts:
		assert_does_not_have(shown, pact, "otros pactos")
	assert_eq(_panel.reroll_cost(), second)
	assert_true(_panel.reroll())
	assert_false(_panel.can_reroll(), "sin oro, no")
	assert_false(_panel.reroll())
	assert_true(_panel.is_open(), "sigue abierto")


func test_cards_show_the_reward_and_the_curse() -> void:
	var card := PactCard.new(EGO_LIFTING, _stats)
	add_child_autofree(card)
	var texts := PackedStringArray()
	for label: Node in card.find_children("*", "Label", true, false):
		texts.append((label as Label).text)
	var joined := " | ".join(texts)
	assert_string_contains(joined, "→", "cuánto cambia cada stat")
	var boons := card.find_children("*", "Label", true, false).filter(
		func(label: Label) -> bool: return label.theme_type_variation == &"BoonLabel"
	)
	var curses := card.find_children("*", "Label", true, false).filter(
		func(label: Label) -> bool: return label.theme_type_variation == &"CurseLabel"
	)
	assert_eq(boons.size(), EGO_LIFTING.rewards.size())
	assert_eq(curses.size(), EGO_LIFTING.curses.size())


func _on_announced(text_key: StringName, args: Array, _color: Color) -> void:
	_announced.append([text_key, args])
