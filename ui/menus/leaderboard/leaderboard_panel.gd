class_name LeaderboardPanel
extends PanelContainer
## Récords: las partidas de la clasificación ([code]Save.leaderboard[/code]), de la mejor a la peor,
## con puesto, personaje, enemigos derrotados, tiempo, nivel alcanzado, mapa y resultado. La última
## partida jugada sale resaltada. «Volver» o Esc lo cierran. Lo abre el menú principal.

## Se cerró.
signal closed

## Cabeceras de las columnas, en orden.
const COLUMNS: Array[StringName] = [
	&"RECORDS_RANK", &"RECORDS_CHARACTER", &"RECORDS_KILLS", &"RECORDS_TIME",
	&"RECORDS_LEVEL", &"RECORDS_MAP", &"RECORDS_RESULT",
]
## Texto de una celda sin dato (personaje o mapa desconocidos).
const UNKNOWN := "—"

@onready var _rows: GridContainer = %Rows
@onready var _scroll: ScrollContainer = %Scroll
@onready var _empty: Label = %Empty
@onready var _back: Button = %Back


func _ready() -> void:
	_rows.columns = COLUMNS.size()
	_back.pressed.connect(close)
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(InputActions.PAUSE):
		close()
		get_viewport().set_input_as_handled()


## Muestra la clasificación guardada y deja el foco en «Volver».
func open() -> void:
	var entries: Array[RunRecord] = []
	if Save.leaderboard:
		entries = Save.leaderboard.get_entries()
	_fill(entries)
	visible = true
	_back.grab_focus()


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


## El texto de cada celda, fila a fila (la primera, las cabeceras). Vacío si no hay partidas.
func get_rows() -> Array[PackedStringArray]:
	var rows: Array[PackedStringArray] = []
	var cells := _rows.get_children()
	for start: int in range(0, cells.size(), COLUMNS.size()):
		var row := PackedStringArray()
		for cell: Node in cells.slice(start, start + COLUMNS.size()):
			row.append((cell as Label).text)
		rows.append(row)
	return rows


func _fill(entries: Array[RunRecord]) -> void:
	for cell: Node in _rows.get_children():
		cell.free()
	_empty.visible = entries.is_empty()
	_scroll.visible = not entries.is_empty()
	if entries.is_empty():
		return
	for key: StringName in COLUMNS:
		_add_cell(String(key), &"StatGroupLabel")
	var latest := _latest(entries)
	for index: int in entries.size():
		var record := entries[index]
		var style := &"StatModifiedLabel" if index == latest else &"StatValueLabel"
		_add_cell(str(index + 1), style)
		_add_cell(_key_or_unknown(record.character_name_key), style)
		_add_cell(str(record.kills), style)
		_add_cell(RunClock.format(record.seconds), style)
		_add_cell(str(record.player_level), style)
		_add_cell(_key_or_unknown(record.level_name_key), style)
		_add_cell("RECORDS_WON" if record.won else "RECORDS_LOST", style)


## Puesto de la partida que acabó más tarde.
static func _latest(entries: Array[RunRecord]) -> int:
	var latest := 0
	for index: int in entries.size():
		if entries[index].finished_at > entries[latest].finished_at:
			latest = index
	return latest


## Las claves se traducen solas en la etiqueta.
static func _key_or_unknown(key: StringName) -> String:
	return UNKNOWN if key.is_empty() else String(key)


func _add_cell(text: String, style: StringName) -> void:
	var cell := Label.new()
	cell.theme_type_variation = style
	cell.text = text
	_rows.add_child(cell)
