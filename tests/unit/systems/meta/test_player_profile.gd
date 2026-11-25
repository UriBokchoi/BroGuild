extends GutTest
## PlayerProfile: guarda y lee las bro-monedas y el nivel de cada mejora; las monedas nunca quedan
## en negativo. Comprar cobra el siguiente nivel (sin monedas o al máximo, no hace nada) y
## reembolsar devuelve todo lo gastado.


func _upgrade() -> MetaUpgradeData:
	var upgrade := MetaUpgradeData.new()
	upgrade.id = &"damage"
	upgrade.stats = [&"damage"]
	upgrade.values = PackedFloat32Array([1.0, 2.0])
	upgrade.costs = PackedInt32Array([5, 10])
	return upgrade


func test_round_trip() -> void:
	var profile := PlayerProfile.new()
	profile.add_bro_coins(7)
	profile.upgrades[&"damage"] = 2
	var config := ConfigFile.new()
	profile.write_to(config)
	var loaded := PlayerProfile.new()
	loaded.read_from(config)
	assert_eq(loaded.bro_coins, 7)
	assert_eq(loaded.level_of(&"damage"), 2)
	assert_eq(loaded.level_of(&"area"), 0)


func test_ignores_negative_amounts() -> void:
	var profile := PlayerProfile.new()
	profile.add_bro_coins(3)
	profile.add_bro_coins(-5)
	assert_eq(profile.bro_coins, 3)


func test_a_broken_file_reads_as_zero() -> void:
	var config := ConfigFile.new()
	config.set_value(PlayerProfile.SECTION, "bro_coins", -40)
	config.set_value(PlayerProfile.SECTION, "upgrades", {"damage": "mucho", "area": -2})
	var loaded := PlayerProfile.new()
	loaded.read_from(config)
	assert_eq(loaded.bro_coins, 0)
	assert_true(loaded.upgrades.is_empty())


func test_buying_charges_the_next_level() -> void:
	var profile := PlayerProfile.new()
	var upgrade := _upgrade()
	assert_false(profile.buy(upgrade), "sin monedas")
	profile.add_bro_coins(20)
	assert_true(profile.buy(upgrade))
	assert_eq(profile.bro_coins, 15)
	assert_true(profile.buy(upgrade))
	assert_eq(profile.bro_coins, 5)
	assert_eq(profile.level_of(&"damage"), 2)
	assert_false(profile.can_buy(upgrade), "al máximo")
	assert_false(profile.buy(upgrade))
	assert_eq(profile.bro_coins, 5)


func test_refund_gives_everything_back() -> void:
	var profile := PlayerProfile.new()
	var upgrade := _upgrade()
	var catalog := MetaUpgradeCatalog.new()
	catalog.upgrades = [upgrade]
	profile.add_bro_coins(16)
	profile.buy(upgrade)
	profile.buy(upgrade)
	assert_eq(profile.refund(catalog), 15)
	assert_eq(profile.bro_coins, 16)
	assert_eq(profile.level_of(&"damage"), 0)
	assert_eq(profile.refund(catalog), 0, "ya no queda nada")
