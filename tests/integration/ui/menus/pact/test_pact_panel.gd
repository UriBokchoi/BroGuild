extends GutTest
## Pactos del Gremio: el panel se abre con los pactos (una carta por pacto, con el premio y la
## maldición) y pausa; al elegir uno, el premio y la maldición van a las stats del jugador y el HUD lo
## avisa; al rechazarlos, nada cambia.

const PanelScene := preload("res://ui/menus/pact/pact_panel.tscn")
const EGO_LIFTING := preload("res://data/pacts/ego_lifting.tres")
const ALL_IN := preload("res://data/pacts/all_in.tres")
const CHEAT_MEAL := preload("res://data/pacts/cheat_meal.tres")
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
var _announced: Array = []


func before_each() -> void:
	_stats = StatsComponent.new()
	for path: String in PLAYER_DATA:
		_stats.sources.append(load(path))
	add_child_autofree(_stats)
	_panel = PanelScene.instantiate() as PactPanel
	_panel.stats = _stats
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
	cards[0].pressed.emit()
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
