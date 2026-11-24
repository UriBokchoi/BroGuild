extends GutTest
## Elegir una mejora de stats: se abre con las ofertas (una carta por oferta, con su rareza y cuánto
## cambia la stat), pausa y, al elegir, la mejora va a las stats del jugador y el juego sigue.

const PanelScene := preload("res://ui/menus/stat_choice/stat_choice_panel.tscn")
const SHRINE := preload("res://data/shrines/dumbbell.tres")
const RARE := preload("res://data/rarities/rare.tres")

var _panel: StatChoicePanel
var _stats: StatsComponent


func before_each() -> void:
	_stats = StatsComponent.new()
	for source: Resource in [OffenseData.new(), HealthData.new(), MovementData.new(), StaminaData.new(), ProgressionData.new(), MovementSynergyData.new()]:
		_stats.sources.append(source)
	add_child_autofree(_stats)
	_panel = PanelScene.instantiate() as StatChoicePanel
	_panel.stats = _stats
	add_child_autofree(_panel)


func after_each() -> void:
	get_tree().paused = false


func test_choosing_adds_the_upgrade_to_the_stats() -> void:
	# La primera, la vida máxima: suma aunque la base de prueba valga 0.
	var health: Array[UpgradeStat] = SHRINE.stats.filter(func(entry: UpgradeStat) -> bool: return entry.stat == &"max_health")
	var offers: Array[StatOffer] = []
	for upgrade_stat: UpgradeStat in [health[0], SHRINE.stats[0], SHRINE.stats[1]]:
		var offer := StatOffer.new()
		offer.stat = upgrade_stat
		offer.rarity = RARE
		offers.append(offer)
	EventBus.stat_choice_offered.emit(offers)
	assert_true(_panel.is_open())
	assert_true(get_tree().paused)
	var cards := _panel.get_cards()
	assert_eq(cards.size(), 3)
	var stat := offers[0].stat.stat
	var before := _stats.get_value(stat)
	cards[0].pressed.emit()
	assert_false(_panel.is_open())
	assert_false(get_tree().paused)
	assert_gt(_stats.get_value(stat), before, "la mejora se queda en las stats")
