extends GutTest
## MetaUpgradeData y MetaUpgradeCatalog: niveles, precios, lo gastado (el reembolso), los
## modificadores de cada nivel (el total del nivel, no la suma) y el conjunto que va a la base del
## jugador.


func _upgrade() -> MetaUpgradeData:
	var upgrade := MetaUpgradeData.new()
	upgrade.id = &"damage"
	upgrade.stats = [&"damage", &"area"]
	upgrade.kind = StatModifier.Kind.PERCENT
	upgrade.values = PackedFloat32Array([0.01, 0.02, 0.03])
	upgrade.costs = PackedInt32Array([5, 10, 15])
	upgrade.value_key = &"UPGRADE_VALUE_PERCENT"
	upgrade.display_scale = 100.0
	return upgrade


func test_levels_and_costs() -> void:
	var upgrade := _upgrade()
	assert_eq(upgrade.max_level(), 3)
	assert_eq(upgrade.cost_of(1), 5)
	assert_eq(upgrade.cost_of(3), 15)
	assert_eq(upgrade.cost_of(4), 0, "no hay nivel 4")
	assert_eq(upgrade.spent_up_to(0), 0)
	assert_eq(upgrade.spent_up_to(2), 15)
	assert_eq(upgrade.spent_up_to(9), 30, "nunca más que todo")


func test_each_level_is_a_total() -> void:
	var upgrade := _upgrade()
	assert_eq(upgrade.modifiers_at(0).size(), 0, "sin comprar, nada")
	var modifiers := upgrade.modifiers_at(2)
	assert_eq(modifiers.size(), 2, "uno por stat")
	assert_eq(modifiers[0].stat, &"damage")
	assert_eq(modifiers[1].stat, &"area")
	assert_eq(modifiers[0].kind, StatModifier.Kind.PERCENT)
	assert_almost_eq(modifiers[0].value, 0.02, 0.0001)


func test_value_text() -> void:
	TranslationServer.set_locale("es")
	assert_eq(_upgrade().value_text(3), "+3 %")


func test_the_catalog_builds_the_base_set() -> void:
	var catalog := MetaUpgradeCatalog.new()
	catalog.upgrades = [_upgrade()]
	assert_eq(catalog.find(&"damage"), catalog.upgrades[0])
	assert_null(catalog.find(&"nope"))
	var levels: Dictionary[StringName, int] = {&"damage": 1}
	var bonuses := catalog.build_set(levels)
	assert_eq(bonuses.stat_modifiers.size(), 2)
	assert_almost_eq(bonuses.stat_modifiers[0].value, 0.01, 0.0001)
	assert_eq(catalog.build_set({}).stat_modifiers.size(), 0)
