class_name LoadoutSlot
extends PanelContainer
## Una ranura del HUD de armas y runas ([LoadoutBar]): vacía, cerrada (con un candado: aún no se ha
## desbloqueado) o con el icono de lo que lleva y su nivel. Estilo: variaciones
## [code]LoadoutSlot[/code], [code]LoadoutSlotEmpty[/code], [code]LoadoutSlotLocked[/code],
## [code]LoadoutLevelLabel[/code] y [code]LoadoutLevelMaxLabel[/code] del Theme global.

## Qué muestra.
enum Content { EMPTY, LOCKED, ITEM }

var _icon: TextureRect
var _level: Label
var _content: Content = Content.EMPTY
var _item: ItemData


func _init(side: float) -> void:
	custom_minimum_size = Vector2(side, side)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon = TextureRect.new()
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_icon)
	# En una esquina, encima del icono.
	_level = Label.new()
	_level.size_flags_horizontal = Control.SIZE_SHRINK_END
	_level.size_flags_vertical = Control.SIZE_SHRINK_END
	_level.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_level)
	show_empty()


## Muestra [param item] a [param level].
func show_item(item: ItemData, level: int) -> void:
	_show(Content.ITEM, item, &"LoadoutSlot")
	_icon.texture = item.icon
	var maxed := level >= item.max_level()
	_level.text = tr(&"LOADOUT_MAX") if maxed else str(level)
	_level.theme_type_variation = &"LoadoutLevelMaxLabel" if maxed else &"LoadoutLevelLabel"


## Ranura abierta sin nada.
func show_empty() -> void:
	_show(Content.EMPTY, null, &"LoadoutSlotEmpty")
	_icon.texture = null


## Ranura cerrada, con [param lock] de icono.
func show_locked(lock: Texture2D) -> void:
	_show(Content.LOCKED, null, &"LoadoutSlotLocked")
	_icon.texture = lock


func get_content() -> Content:
	return _content


## Lo que lleva (o [code]null[/code]).
func get_item() -> ItemData:
	return _item


## Texto del nivel (vacío si no lleva nada).
func get_level_text() -> String:
	return _level.text


func _show(content: Content, item: ItemData, variation: StringName) -> void:
	_content = content
	_item = item
	theme_type_variation = variation
	_level.text = ""
