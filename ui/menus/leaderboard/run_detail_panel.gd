class_name RunDetailPanel
extends PanelContainer
## El detalle de una partida de los récords, en una ventana aparte en el centro del menú: personaje,
## mapa y tier, hasta dónde llegó, resultado, tiempo, nivel, enemigos, oro, daño, fecha y la build con
## la que acabó (armas, runas, objetos y pactos). «Volver» o Esc la cierran.

## Se cerró.
signal closed

## Texto de un dato que falta (personaje o mapa desconocidos).
const UNKNOWN := "—"

## De dónde salen el nombre y el icono de armas, runas y objetos.
@export var catalog: ContentCatalog
## Una pieza de la build (icono y nivel o copias).
@export var chip: PackedScene

@onready var _title: Label = %Title
@onready var _rows: GridContainer = %Rows
@onready var _build: VBoxContainer = %Build
@onready var _scroll: ScrollContainer = %Scroll
@onready var _back: Button = %Back


func _ready() -> void:
	_back.pressed.connect(close)
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(InputActions.PAUSE):
		close()
		get_viewport().set_input_as_handled()


## Enseña [param record] y deja el foco en «Volver».
func open(record: RunRecord) -> void:
	_title.text = _name(record.character_name_key)
	_clear(_rows)
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
	_scroll.scroll_vertical = 0
	UiMotion.reveal(self)
	_back.grab_focus()


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


## Los datos que enseña (nombre → valor, ya traducidos).
func get_rows() -> Dictionary[String, String]:
	var rows: Dictionary[String, String] = {}
	var cells := _rows.get_children()
	for start: int in range(0, cells.size() - 1, 2):
		rows[(cells[start] as Label).text] = (cells[start + 1] as Label).text
	return rows


## Las piezas de la build que enseña (sus nombres).
func get_build_names() -> PackedStringArray:
	var names := PackedStringArray()
	for flow: Node in _build.get_children():
		for piece: Node in flow.get_children():
			names.append((piece as Control).tooltip_text)
	return names


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
		(piece.get_node(^"Icon") as TextureRect).texture = entry.get(&"icon") as Texture2D if entry else null
		(piece.get_node(^"Count") as Label).text = str(counts[id])
		piece.tooltip_text = tr(entry.get(&"name_key") as StringName) if entry else id
		flow.add_child(piece)
	_build.add_child(flow)


func _add_row(name_key: StringName, value: String) -> void:
	_rows.add_child(_label(tr(name_key), &"StatNameLabel"))
	_rows.add_child(_label(value, &"StatValueLabel"))


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
