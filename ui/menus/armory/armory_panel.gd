class_name ArmoryPanel
extends CanvasLayer
## Panel de la armería de práctica: lista todas las armas del juego para equiparlas, quitarlas y
## subirlas o bajarlas de nivel, y a la derecha muestra las stats propias del arma por la que pasa
## el ratón (sin las del personaje). Pausa el juego y pide el cursor mientras está abierto; se
## cierra con Esc, con «interactuar» o con su botón.

var _inventory: WeaponInventory
var _catalog: Array[WeaponData] = []
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


## Abre el panel con las armas de [param catalog] para el inventario [param inventory].
func open(inventory: WeaponInventory, catalog: Array[WeaponData]) -> void:
	_inventory = inventory
	_catalog = catalog
	_build_rows()
	if not _catalog.is_empty():
		_select(_catalog[0])
	_set_open(true)


func close() -> void:
	get_viewport().gui_release_focus()
	_set_open(false)


func is_open() -> bool:
	return visible


## Filas del panel, una por arma (para tests).
func get_rows() -> Array[ArmoryRow]:
	return _rows.duplicate()


func _set_open(open_panel: bool) -> void:
	visible = open_panel
	get_tree().paused = open_panel
	EventBus.cursor_requested.emit(self, open_panel)


func _build_rows() -> void:
	for row: ArmoryRow in _rows:
		row.free()
	_rows.clear()
	for index: int in _catalog.size():
		var row := ArmoryRow.new(_catalog[index], index % 2 == 1)
		row.equip_toggled.connect(_on_equip_toggled)
		row.level_stepped.connect(_on_level_stepped)
		row.hovered.connect(_select)
		_list.add_child(row)
		_rows.append(row)
		row.refresh(_inventory.get_weapon(row.data))


func _on_equip_toggled(data: WeaponData) -> void:
	if _inventory.has(data):
		_inventory.remove(data)
	else:
		_inventory.add(data)
	_refresh(data)


func _on_level_stepped(data: WeaponData, step: int) -> void:
	var weapon := _inventory.get_weapon(data)
	if weapon:
		weapon.set_level(weapon.level + step)
	_refresh(data)


func _refresh(data: WeaponData) -> void:
	for row: ArmoryRow in _rows:
		if row.data == data:
			row.refresh(_inventory.get_weapon(data))
	_select(data)


func _select(data: WeaponData) -> void:
	_selected_name.text = data.name_key
	var weapon := _inventory.get_weapon(data)
	_equip_hint.visible = weapon == null
	_stats_view.visible = weapon != null
	if weapon:
		_stats_view.show_stats(weapon.stats)
