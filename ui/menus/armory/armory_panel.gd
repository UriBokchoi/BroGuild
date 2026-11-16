class_name ArmoryPanel
extends CanvasLayer
## Panel de la armería de práctica: lista todas las armas y runas del juego para equiparlas,
## quitarlas y subirlas o bajarlas de nivel. A la derecha muestra las stats del objeto por el que
## pasa el ratón: las propias de un arma (sin las del personaje) o, para una runa, todas las del
## jugador con lo que cambian sus runas resaltado. Pausa el juego y pide el cursor mientras está
## abierto; se cierra con Esc, con «interactuar» o con su botón.

var _player: Player
var _rows: Array[ArmoryRow] = []

@onready var _list: VBoxContainer = %WeaponList
@onready var _selected_name: Label = %SelectedName
@onready var _stats_view: StatsView = %StatsView
@onready var _equip_hint: Label = %EquipHint
@onready var _close: Button = %Close


func _ready() -> void:
	_close.pressed.connect(close)
	visible = false


func _input(event: InputEvent) -> void:
	# En _input, antes que el menú de pausa: Esc cierra este panel sin abrir la pausa.
	if not visible:
		return
	if event.is_action_pressed(InputActions.PAUSE) or event.is_action_pressed(InputActions.INTERACT):
		get_viewport().set_input_as_handled()
		close()


func _exit_tree() -> void:
	if visible:
		_set_open(false)


## Abre el panel para [param player] con las armas de [param weapons] y las runas de [param runes].
func open(player: Player, weapons: Array[WeaponData], runes: Array[RuneData]) -> void:
	_player = player
	_clear_list()
	_add_section(&"ARMORY_WEAPONS", weapons)
	_add_section(&"ARMORY_RUNES", runes)
	if not _rows.is_empty():
		_select(_rows[0].data)
	_set_open(true)


func close() -> void:
	get_viewport().gui_release_focus()
	_set_open(false)


func is_open() -> bool:
	return visible


## Filas del panel, una por objeto (para tests).
func get_rows() -> Array[ArmoryRow]:
	return _rows.duplicate()


func _set_open(open_panel: bool) -> void:
	visible = open_panel
	get_tree().paused = open_panel
	EventBus.cursor_requested.emit(self, open_panel)


func _clear_list() -> void:
	for child: Node in _list.get_children():
		child.free()
	_rows.clear()


func _add_section(title_key: StringName, items: Array) -> void:
	if items.is_empty():
		return
	var title := Label.new()
	title.theme_type_variation = &"StatGroupLabel"
	title.text = title_key
	_list.add_child(title)
	for index: int in items.size():
		var row := ArmoryRow.new(items[index] as ItemData, index % 2 == 1)
		row.equip_toggled.connect(_on_equip_toggled)
		row.level_stepped.connect(_on_level_stepped)
		row.hovered.connect(_select)
		_list.add_child(row)
		_rows.append(row)
		row.refresh(_level_of(row.data))


func _on_equip_toggled(data: ItemData) -> void:
	var equipped := _level_of(data) > 0
	if data is WeaponData:
		if equipped:
			_player.weapons.remove(data as WeaponData)
		else:
			_player.weapons.add(data as WeaponData)
	elif data is RuneData:
		_player.runes.set_level(data as RuneData, 0 if equipped else 1)
	_refresh(data)


func _on_level_stepped(data: ItemData, step: int) -> void:
	var level := _level_of(data)
	if level == 0:
		return
	if data is WeaponData:
		_player.weapons.get_weapon(data as WeaponData).set_level(level + step)
	elif data is RuneData:
		_player.runes.set_level(data as RuneData, level + step)
	_refresh(data)


## Nivel que tiene el jugador de [param data] (0 si no lo lleva).
func _level_of(data: ItemData) -> int:
	if data is WeaponData:
		var weapon := _player.weapons.get_weapon(data as WeaponData)
		return weapon.level if weapon else 0
	if data is RuneData:
		return _player.runes.get_level(data as RuneData)
	return 0


func _refresh(data: ItemData) -> void:
	for row: ArmoryRow in _rows:
		if row.data == data:
			row.refresh(_level_of(data))
	_select(data)


func _select(data: ItemData) -> void:
	_selected_name.text = data.name_key
	var stats: StatsComponent = null
	if data is WeaponData:
		var weapon := _player.weapons.get_weapon(data as WeaponData)
		stats = weapon.stats if weapon else null
	elif data is RuneData:
		stats = _player.stats
	_equip_hint.visible = stats == null
	_stats_view.visible = stats != null
	if stats:
		_stats_view.show_stats(stats)
