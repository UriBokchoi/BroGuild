extends GutTest
## UpgradableStats: las stats que algún dato del juego puede cambiar (modificadores de objetos,
## personajes y power-ups, mejoras de armas y runas) y la dificultad; las fijas, no.


func test_stats_from_items_weapons_and_runes() -> void:
	for stat: StringName in [&"damage", &"max_health", &"luck", &"projectiles", &"area", &"difficulty"]:
		assert_true(UpgradableStats.has(stat), "%s" % stat)


func test_fixed_stats_are_not_there() -> void:
	for stat: StringName in [&"coyote_time", &"mantle_reach", &"stat_que_no_existe"]:
		assert_false(UpgradableStats.has(stat), "%s" % stat)


func test_no_folder_that_changes_the_player_is_missing() -> void:
	# Lento a propósito: carga todos los datos, también los niveles.
	var everything := UpgradableStats.found_in(["res://data"] as Array[String])
	var player := (load("res://entities/player/player.tscn") as PackedScene).instantiate() as Player
	add_child_autofree(player)
	for stat: StringName in player.stats.get_stats():
		if everything.has(stat):
			assert_true(UpgradableStats.has(stat), "%s cambia en datos fuera de UpgradableStats.DIRS" % stat)


func test_every_item_stat_is_there() -> void:
	for item: Resource in ResourceDir.load_all("res://data/items", PassiveItemData):
		for modifier: StatModifier in (item as PassiveItemData).stat_modifiers:
			assert_true(UpgradableStats.has(modifier.stat), "%s de %s" % [modifier.stat, item.resource_path])
