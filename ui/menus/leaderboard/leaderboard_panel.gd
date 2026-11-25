class_name LeaderboardPanel
extends PanelContainer
## Récords, fijos a la derecha del menú principal: las mejores partidas de Save.leaderboard, de la
## mejor a la peor, con el personaje y los enemigos derrotados; la última jugada, en azul. Al hacer
## clic en una, debajo sale su detalle: mapa y tier, resultado, tiempo, nivel, enemigos, oro, daño,
## fecha y la build con la que acabó (armas, runas, objetos y pactos).

## Texto de un dato que falta (personaje o mapa desconocidos).
const UNKNOWN := "—"

## De dónde salen el nombre y el icono de personajes, armas, runas y objetos.
@export var catalog: ContentCatalog
## Una pieza de la build (icono y nivel o copias).
@export var chip: PackedScene

var _entries: Array[RunRecord] = []
var _selected: int = -1
var _group := ButtonGroup.new()

@onready var _list: VBoxContainer = %List
@onready var _list_scroll: ScrollContainer = %ListScroll
@onready var _empty: Label = %Empty
@onready var _detail: ScrollContainer = %Detail
@onready var _detail_title: Label = %DetailTitle
@onready var _detail_rows: GridContainer = %DetailRows
@onready var _build: VBoxContainer = %Build


func _ready() -> void:
	refresh()


## Vuelve a leer los récords guardados, sin ninguno marcado.
func refresh() -> void:
	_entries = Save.leaderboard.get_entries() if Save.leaderboard else []
	_clear(_list)
	var latest := _latest()
	for index: int in _entries.size():
		_list.add_child(_row(index, index == latest))
	_empty.visible = _entries.is_empty()
	_list_scroll.visible = not _entries.is_empty()
	select(-1)


## Marca la partida [param index] (desde 0; −1, ninguna) y enseña su detalle debajo.
func select(index: int) -> void:
	_selected = index if index >= 0 and index < _entries.size() else -1
	for row: int in _list.get_child_count():
		(_list.get_child(row) as Button).set_pressed_no_signal(row == _selected)
	_detail.visible = _selected >= 0
	if _selected >= 0:
		_show_detail(_entries[_selected])


## La partida marcada (−1: ninguna).
func get_selected() -> int:
	return _selected


## El texto de cada partida de la lista, en orden.
func get_row_texts() -> PackedStringArray:
	var texts := PackedStringArray()
	for row: Node in _list.get_children():
		texts.append((row as Button).text)
	return texts


## Los datos del detalle (nombre → valor, ya traducidos).
func get_detail_rows() -> Dictionary[String, String]:
	var rows: Dictionary[String, String] = {}
	var cells := _detail_rows.get_children()
	for start: int in range(0, cells.size() - 1, 2):
		rows[tr((cells[start] as Label).text)] = (cells[start + 1] as Label).text
	return rows


## Las piezas de la build que enseña el detalle (sus nombres).
func get_build_names() -> PackedStringArray:
	var names := PackedStringArray()
	for flow: Node in _build.get_children():
		for piece: Node in flow.get_children():
			names.append((piece as Control).tooltip_text)
	return names


func _row(index: int, latest: bool) -> Button:
	var record := _entries[index]
	var button := Button.new()
	button.theme_type_variation = &"RecordRowLatest" if latest else &"RecordRow"
	button.toggle_mode = true
	button.button_group = _group
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	# Que la fila no ensanche la columna: lo que no quepa, con puntos suspensivos.
	button.clip_text = true
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.icon = _icon(&"characters", record.character_id)
	button.text = tr(&"RECORDS_ROW") % [index + 1, _name(record.character_name_key), record.kills]
	button.pressed.connect(select.bind(index))
	return button


func _show_detail(record: RunRecord) -> void:
	_detail_title.text = _name(record.character_name_key)
	_clear(_detail_rows)
	_add_row(&"RECORDS_MAP", _level_text(record))
	if not record.stage_key.is_empty():
		_add_row(&"RESULTS_STAGE", tr(record.stage_key))
	_add_row(&"RECORDS_RESULT", tr(&"RECORDS_WON" if record.won else &"RECORDS_LOST"))
	_add_row(&"RESULTS_TIME", RunClock.format(record.seconds))
	_add_row(&"RESULTS_LEVEL", str(record.player_level))
	_add_row(&"RESULTS_KILLS", str(record.kills))
	_add_row(&"RESULTS_ELITE_KILLS", str(record.elite_kills))
	if record.has_build():
		_add_row(&"RESULTS_GOLD", str(floori(record.gold_earned)))
		_add_row(&"RESULTS_DAMAGE", str(floori(record.damage_dealt)))
	_add_row(&"RECORDS_DATE", _date_text(record.finished_at))
	_show_build(record)


## Armas, runas y objetos con su icono y su nivel o copias, y los pactos por su nombre. Una partida
## de antes de que se guardara la build lo dice.
func _show_build(record: RunRecord) -> void:
	_clear(_build)
	if not record.has_build():
		_build.add_child(_label(tr(&"RECORDS_NO_BUILD"), &"StatBaseLabel"))
		return
	_add_group(&"weapons", record.weapons)
	_add_group(&"runes", record.runes)
	_add_group(&"items", record.items)
	if not record.pacts.is_empty():
		_build.add_child(_label(tr(&"RECORDS_PACTS"), &"StatGroupLabel"))
		var pacts := PackedStringArray()
		for pact: String in record.pacts:
			pacts.append(tr(pact))
		_build.add_child(_label(", ".join(pacts), &"StatValueLabel"))


func _add_group(category_id: StringName, counts: Dictionary[String, int]) -> void:
	if counts.is_empty():
		return
	var category := _category(category_id)
	_build.add_child(_label(tr(category.name_key) if category else String(category_id), &"StatGroupLabel"))
	var flow := HFlowContainer.new()
	flow.theme_type_variation = &"BuildFlow"
	for id: String in counts:
		var entry := catalog.find(category_id, StringName(id)) if catalog else null
		var piece := chip.instantiate() as Control
		(piece.get_node(^"Icon") as TextureRect).texture = _icon(category_id, StringName(id))
		(piece.get_node(^"Count") as Label).text = str(counts[id])
		piece.tooltip_text = tr(entry.get(&"name_key") as StringName) if entry else id
		flow.add_child(piece)
	_build.add_child(flow)


func _add_row(name_key: StringName, value: String) -> void:
	_detail_rows.add_child(_label(tr(name_key), &"StatNameLabel"))
	_detail_rows.add_child(_label(value, &"StatValueLabel"))


## Una etiqueta con [param text] ya traducido (no se vuelve a traducir: los números y nombres
## propios no son claves).
func _label(text: String, variation: StringName) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = variation
	label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label


func _category(category_id: StringName) -> ContentCategory:
	if catalog == null:
		return null
	for category: ContentCategory in catalog.categories:
		if category.id == category_id:
			return category
	return null


func _icon(category_id: StringName, id: StringName) -> Texture2D:
	var entry := catalog.find(category_id, id) if catalog else null
	return entry.get(&"icon") as Texture2D if entry else null


## Puesto de la partida que acabó más tarde (−1 sin partidas).
func _latest() -> int:
	var latest := -1
	for index: int in _entries.size():
		if latest < 0 or _entries[index].finished_at > _entries[latest].finished_at:
			latest = index
	return latest


## El mapa de [param record] y, si tiene, su tier («Brosque · T2»).
func _level_text(record: RunRecord) -> String:
	if record.level_name_key.is_empty():
		return UNKNOWN
	var level := tr(record.level_name_key)
	return tr(&"RECORDS_LEVEL_TIER") % [level, record.tier] if record.tier > 0 else level


func _name(key: StringName) -> String:
	return UNKNOWN if key.is_empty() else tr(key)


## La fecha y hora (de este equipo) de [param unix_time].
func _date_text(unix_time: float) -> String:
	var bias: int = Time.get_time_zone_from_system().get("bias", 0)
	var date := Time.get_datetime_dict_from_unix_time(floori(unix_time) + bias * 60)
	return tr(&"RECORDS_DATE_VALUE") % [date["day"], date["month"], date["year"], date["hour"], date["minute"]]


static func _clear(container: Node) -> void:
	for child: Node in container.get_children():
		container.remove_child(child)
		child.queue_free()
