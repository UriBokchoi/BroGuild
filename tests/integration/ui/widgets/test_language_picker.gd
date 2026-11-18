extends GutTest
## Selector de idioma: ofrece cada idioma traducido con su nombre en su propio idioma, marca el de
## ahora y, al elegir otro, lo pone y lo guarda en las opciones.

const PATH := "user://test_language_settings.cfg"

var _real_path: String = ""
var _real_locale: String = ""
var _picker: LanguagePicker


func before_each() -> void:
	_real_path = Save.settings_path
	_real_locale = Save.settings.locale
	Save.settings_path = PATH
	_picker = LanguagePicker.new()
	_picker.name_key = &"LANGUAGE_NAME"
	add_child_autofree(_picker)


func after_each() -> void:
	Save.settings_path = _real_path
	Save.settings.locale = _real_locale
	Save.settings.apply_locale()
	DirAccess.remove_absolute(PATH)


func test_offers_each_language_by_its_own_name() -> void:
	var locales := _picker.get_locales()
	assert_has(locales, "es")
	assert_has(locales, "en")
	var names: Array[String] = []
	for index: int in _picker.item_count:
		names.append(_picker.get_item_text(index))
	assert_has(names, "Español")
	assert_has(names, "English", "cada uno en su idioma")
	assert_eq(locales[_picker.selected], TranslationServer.get_locale(), "marca el de ahora")


func test_choosing_one_applies_and_saves_it() -> void:
	var english := _picker.get_locales().find("en")
	_picker.select(english)
	_picker.item_selected.emit(english)
	assert_eq(TranslationServer.get_locale(), "en")
	assert_eq(Save.settings.locale, "en")
	var config := ConfigFile.new()
	assert_eq(config.load(PATH), OK)
	var saved: String = config.get_value(GameSettings.SECTION_GENERAL, "locale")
	assert_eq(saved, "en", "guardado")
