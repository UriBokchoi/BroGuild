class_name LeaderboardPanel
extends PanelContainer
## Récords, fijos a la derecha del menú principal: las mejores partidas de Save.leaderboard, de la
## mejor a la peor, con el personaje y los enemigos derrotados; la última jugada, en azul. Al hacer
## clic en una avisa (run_chosen) y el menú abre su detalle en una ventana aparte (RunDetailPanel).

## Se hizo clic en una partida.
signal run_chosen(record: RunRecord)

## Texto de un dato que falta (personaje desconocido).
const UNKNOWN := "—"

## De dónde salen los iconos de los personajes.
@export var catalog: ContentCatalog

var _entries: Array[RunRecord] = []

@onready var _list: VBoxContainer = %List
@onready var _list_scroll: ScrollContainer = %ListScroll
@onready var _empty: Label = %Empty


func _ready() -> void:
	refresh()


## Vuelve a leer los récords guardados.
func refresh() -> void:
	_entries = Save.leaderboard.get_entries() if Save.leaderboard else []
	for child: Node in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	var latest := _latest()
	for index: int in _entries.size():
		_list.add_child(_row(index, index == latest))
	_empty.visible = _entries.is_empty()
	_list_scroll.visible = not _entries.is_empty()


## Elige la partida [param index] (desde 0): avisa para que se abra su detalle.
func choose(index: int) -> void:
	if index >= 0 and index < _entries.size():
		run_chosen.emit(_entries[index])


## El texto de cada partida de la lista, en orden.
func get_row_texts() -> PackedStringArray:
	var texts := PackedStringArray()
	for row: Node in _list.get_children():
		texts.append((row as Button).text)
	return texts


func _row(index: int, latest: bool) -> Button:
	var record := _entries[index]
	var button := Button.new()
	button.theme_type_variation = &"RecordRowLatest" if latest else &"RecordRow"
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	# Que la fila no ensanche la columna: lo que no quepa, con puntos suspensivos.
	button.clip_text = true
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var character := catalog.find(&"characters", record.character_id) if catalog else null
	button.icon = character.get(&"icon") as Texture2D if character else null
	var character_name := UNKNOWN if record.character_name_key.is_empty() else tr(record.character_name_key)
	button.text = tr(&"RECORDS_ROW") % [index + 1, character_name, record.kills]
	button.pressed.connect(choose.bind(index))
	return button


## Puesto de la partida que acabó más tarde (−1 sin partidas).
func _latest() -> int:
	var latest := -1
	for index: int in _entries.size():
		if latest < 0 or _entries[index].finished_at > _entries[latest].finished_at:
			latest = index
	return latest
