class_name LanguagePicker
extends OptionButton
## Selector de idioma: un idioma por cada traducción cargada, con su nombre en su propio idioma (la
## clave [member name_key] de su traducción: «Español», «English»). Al elegir uno, lo pone al
## momento y lo guarda en las opciones ([code]Save[/code]). Un idioma nuevo (su columna en el CSV)
## aparece solo. El icono del nodo (un globo) va junto a cada idioma.

## Clave del nombre de cada idioma en su propia traducción.
@export var name_key: StringName = &""

var _locales: PackedStringArray = PackedStringArray()


func _ready() -> void:
	# Los nombres ya van en su idioma: no se traducen al del juego.
	auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_locales = TranslationServer.get_loaded_locales()
	# El botón enseña el icono del elegido: el globo va en cada uno.
	var globe := icon
	for locale: String in _locales:
		add_icon_item(globe, _native_name(locale))
	var current := _locales.find(TranslationServer.get_locale())
	select(maxi(current, 0))
	item_selected.connect(_on_item_selected)


## Idiomas que ofrece, en orden.
func get_locales() -> PackedStringArray:
	return _locales


func _native_name(locale: String) -> String:
	var translation := TranslationServer.get_translation_object(locale)
	var native := translation.get_message(name_key) if translation else &""
	return locale if native.is_empty() else String(native)


func _on_item_selected(index: int) -> void:
	Save.settings.locale = _locales[index]
	Save.settings.apply_locale()
	Save.save_settings()
