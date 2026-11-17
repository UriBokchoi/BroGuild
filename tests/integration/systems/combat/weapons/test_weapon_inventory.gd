extends GutTest
## Inventario de armas: avisa del nivel de cada arma al añadirla (1), al subirla y al quitarla (0).

const SWORD := preload("res://data/weapons/sword.tres")
const OFFENSE := preload("res://data/player/offense.tres")

var _inventory: WeaponInventory


func before_each() -> void:
	var stats := StatsComponent.new()
	stats.sources.append(OFFENSE)
	add_child_autofree(stats)
	_inventory = WeaponInventory.new()
	_inventory.wielder_stats = stats
	add_child_autofree(_inventory)
	watch_signals(_inventory)


func test_adding_announces_level_one() -> void:
	_inventory.add(SWORD)
	assert_signal_emitted_with_parameters(_inventory, "weapon_changed", [SWORD, 1])


func test_leveling_up_announces_the_new_level() -> void:
	_inventory.add(SWORD).set_level(3)
	assert_signal_emitted_with_parameters(_inventory, "weapon_changed", [SWORD, 3])


func test_removing_announces_level_zero() -> void:
	_inventory.add(SWORD)
	_inventory.remove(SWORD)
	assert_signal_emitted_with_parameters(_inventory, "weapon_changed", [SWORD, 0])
