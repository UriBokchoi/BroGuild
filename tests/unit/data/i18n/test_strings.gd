extends GutTest
## data/i18n/strings.csv: cada texto está en todos los idiomas y cada stat del jugador (y su
## grupo) tiene nombre traducido. Las stats salen de las fuentes de la escena del jugador, así
## que un dato nuevo queda cubierto solo.

const STRINGS_PATH := "res://data/i18n/strings.csv"
const PlayerScene := preload("res://entities/player/player.tscn")

var _translations: Dictionary[String, PackedStringArray] = {}
var _locales := PackedStringArray()


func before_all() -> void:
	var file := FileAccess.open(STRINGS_PATH, FileAccess.READ)
	var header := file.get_csv_line()
	_locales = header.slice(1)
	while not file.eof_reached():
		var line := file.get_csv_line()
		if line.size() > 1:
			_translations[line[0]] = line.slice(1)


func test_has_spanish_and_english() -> void:
	assert_has(_locales, "es")
	assert_has(_locales, "en")


func test_every_text_is_in_every_language() -> void:
	for key: String in _translations:
		var texts := _translations[key]
		assert_eq(texts.size(), _locales.size(), "«%s» no tiene todas las columnas" % key)
		for text: String in texts:
			assert_false(text.strip_edges().is_empty(), "«%s» tiene un idioma vacío" % key)


func test_every_player_stat_and_group_has_a_name() -> void:
	var player := PlayerScene.instantiate() as Player
	for source: Resource in player.stats.sources:
		_assert_stat_names(source)
	player.free()


func _assert_stat_names(data: Resource) -> void:
	var group := ""
	for property: Dictionary in data.get_property_list():
		var usage: int = property["usage"]
		var property_name: String = property["name"]
		if usage & PROPERTY_USAGE_GROUP:
			group = property_name
		elif usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			# Solo cuentan los grupos con stats: los Resources traen grupos propios sin ellas.
			if not group.is_empty():
				_assert_key(StatFormat.group_key(group))
			_assert_key(StatFormat.name_key(property_name))


func _assert_key(key: String) -> void:
	assert_true(_translations.has(key), "Falta «%s» en %s" % [key, STRINGS_PATH])
