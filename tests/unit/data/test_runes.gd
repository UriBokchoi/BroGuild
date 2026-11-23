extends GutTest
## Runas de data/runes: están las cinco iniciales, cada una con id único, nombre y descripción
## traducidos, icono, nivel máximo 20 y stats que mejorar que el jugador tiene.

const RUNES_DIR := "res://data/runes"
const STRINGS_PATH := "res://data/i18n/strings.csv"
const PlayerScene := preload("res://entities/player/player.tscn")
## Nivel máximo de partida de las runas (GDD §6).
const MAX_LEVEL := 20
const RARITIES := preload("res://data/rarities/rarities.tres")

var _keys := PackedStringArray()
var _runes: Array[RuneData] = []


func before_all() -> void:
	var file := FileAccess.open(STRINGS_PATH, FileAccess.READ)
	while not file.eof_reached():
		var line := file.get_csv_line()
		if not line.is_empty():
			_keys.append(line[0])
	_runes.assign(ResourceDir.load_all(RUNES_DIR, RuneData))


func test_the_five_starting_runes_exist() -> void:
	var ids: Array[StringName] = []
	for rune: RuneData in _runes:
		ids.append(rune.id)
	for id: StringName in [&"strength", &"amplitude", &"haste", &"vigor", &"multiplicity"]:
		assert_has(ids, id)


func test_ids_are_unique_and_texts_translated() -> void:
	var ids: Array[StringName] = []
	for rune: RuneData in _runes:
		assert_does_not_have(ids, rune.id, "id repetido: %s" % rune.id)
		ids.append(rune.id)
		assert_has(_keys, String(rune.name_key), "%s: falta su nombre" % rune.id)
		assert_has(_keys, String(rune.description_key), "%s: falta su descripción" % rune.id)
		assert_not_null(rune.icon, "%s: sin icono" % rune.id)


func test_upgrades_touch_player_stats_up_to_level_20() -> void:
	var player := PlayerScene.instantiate() as Player
	add_child_autofree(player)
	for rune: RuneData in _runes:
		assert_eq(rune.max_level(), MAX_LEVEL, "%s: nivel máximo" % rune.id)
		assert_false(rune.upgrade_stats.is_empty(), "%s: sin stats que mejorar" % rune.id)
		for upgrade_stat: UpgradeStat in rune.upgrade_stats:
			assert_true(player.stats.has_stat(upgrade_stat.stat), "%s: «%s» no es una stat" % [rune.id, upgrade_stat.stat])


func test_multiplicity_gives_one_on_a_common_card_and_up_to_two_point_two() -> void:
	var multiplicity: RuneData = load("res://data/runes/multiplicity.tres")
	var upgrade_stat := multiplicity.upgrade_stats[0]
	var expected: Dictionary[StringName, float] = {&"common": 1.0, &"rare": 1.2, &"improbable": 1.5, &"legendary": 1.8, &"mythic": 2.2}
	for entry: WeightedEntry in RARITIES.entries:
		var rarity := entry as Rarity
		var amount := upgrade_stat.modifier(rarity.power).value
		assert_almost_eq(amount, expected[rarity.id], 1e-4, "%s" % rarity.id)


func test_the_three_movement_synergy_runes_raise_their_damage() -> void:
	var expected: Dictionary[StringName, StringName] = {
		&"embers": &"fire_trail_damage", &"gale": &"dash_wave_damage", &"quake": &"slam_damage"
	}
	for rune: RuneData in _runes:
		if expected.has(rune.id):
			assert_eq(rune.upgrade_stats[0].stat, expected[rune.id], "%s" % rune.id)
			assert_gt(rune.upgrade_stats[0].modifier(0.6).value, 0.0, "%s: la común ya daña" % rune.id)
			expected.erase(rune.id)
	assert_true(expected.is_empty(), "faltan: %s" % [expected.keys()])
