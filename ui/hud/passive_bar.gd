class_name PassiveBar
extends HFlowContainer
## Objetos pasivos del jugador en el HUD, debajo de las runas: el icono de cada uno con el borde del
## color de su rareza y, si lleva más de una copia, cuántas. En el orden en que los consiguió
## ([signal EventBus.player_passive_changed]); al llenar la fila, sigue en la de abajo. Estilo:
## variación [code]PassiveBar[/code] (separaciones) y las de [LoadoutSlot] del Theme global.

## Lado de cada casilla.
@export_range(16.0, 128.0, 1.0, "suffix:px") var slot_size: float = 36.0
## Grosor del borde del color de la rareza.
@export_range(0, 8, 1) var rarity_border: int = 2

## Casilla de cada objeto (por id).
var _slots: Dictionary[StringName, PanelContainer] = {}


func _enter_tree() -> void:
	# En _enter_tree para no perder los avisos que llegan en el _ready del jugador.
	if not EventBus.player_passive_changed.is_connected(show_item):
		EventBus.player_passive_changed.connect(show_item)


## Muestra que lleva [param count] copias de [param item] (0 = lo quita; las demás se corren).
func show_item(item: PassiveItemData, count: int) -> void:
	var slot: PanelContainer = _slots.get(item.id)
	if count <= 0:
		if slot:
			_slots.erase(item.id)
			remove_child(slot)
			slot.queue_free()
		return
	if slot == null:
		slot = _make_slot(item)
		_slots[item.id] = slot
	(slot.get_child(1) as Label).text = "×%d" % count if count > 1 else ""


## Ids de los objetos que se ven, en orden.
func get_shown() -> Array[StringName]:
	var shown: Array[StringName] = []
	for child: Node in get_children():
		shown.append(StringName(child.name))
	return shown


## Lo que pone en la casilla de [param item] (vacío si es una sola copia o no está).
func get_count_text(item: PassiveItemData) -> String:
	var slot: PanelContainer = _slots.get(item.id)
	return (slot.get_child(1) as Label).text if slot else ""


func _make_slot(item: PassiveItemData) -> PanelContainer:
	var slot := PanelContainer.new()
	slot.name = String(item.id)
	slot.theme_type_variation = &"LoadoutSlot"
	slot.custom_minimum_size = Vector2(slot_size, slot_size)
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := TextureRect.new()
	icon.texture = item.icon
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(icon)
	# En una esquina, encima del icono.
	var count := Label.new()
	count.theme_type_variation = &"LoadoutLevelLabel"
	count.size_flags_horizontal = Control.SIZE_SHRINK_END
	count.size_flags_vertical = Control.SIZE_SHRINK_END
	count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(count)
	add_child(slot)
	if item.rarity:
		var box := slot.get_theme_stylebox(&"panel").duplicate() as StyleBoxFlat
		box.border_color = item.rarity.color
		box.set_border_width_all(rarity_border)
		slot.add_theme_stylebox_override(&"panel", box)
	return slot
