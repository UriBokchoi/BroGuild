class_name LoadoutBar
extends VBoxContainer
## Armas y runas del jugador en el HUD, debajo del oro: una fila de ranuras por tipo con el icono y
## el nivel de lo que lleva, en el orden en que lo consiguió. Las ranuras abiertas sin nada se ven
## vacías y las que aún no se han desbloqueado, cerradas con un candado. Cuántas hay sale de
## [LevelUpData]; cuántas están abiertas y qué lleva, de [signal EventBus.player_slots_changed] y
## [signal EventBus.player_item_changed]. Estilo: variaciones [code]LoadoutBar[/code] y
## [code]LoadoutRow[/code] (y las de [LoadoutSlot]) del Theme global.

## Cuántas ranuras hay de cada tipo.
@export var level_up: LevelUpData
## Icono de las ranuras cerradas.
@export var lock_icon: Texture2D
## Lado de cada ranura.
@export_range(16.0, 128.0, 1.0, "suffix:px") var slot_size: float = 44.0

var _weapons: Array[ItemData] = []
var _runes: Array[ItemData] = []
var _levels: Dictionary[StringName, int] = {}
var _open_weapons: int = 0
var _open_runes: int = 0


func _enter_tree() -> void:
	# En _enter_tree para no perder los primeros avisos, que llegan en el _ready del jugador.
	if not EventBus.player_item_changed.is_connected(show_item):
		EventBus.player_item_changed.connect(show_item)
		EventBus.player_slots_changed.connect(show_slots)


func _ready() -> void:
	_refresh()


## Muestra [param item] a [param level]; a nivel 0, lo quita (las demás se corren).
func show_item(item: ItemData, level: int) -> void:
	var row := _weapons if item is WeaponData else _runes
	var index := row.find_custom(func(owned: ItemData) -> bool: return owned.id == item.id)
	if level <= 0:
		if index >= 0:
			row.remove_at(index)
		_levels.erase(item.id)
	else:
		if index < 0:
			row.append(item)
		_levels[item.id] = level
	_refresh()


## Abre [param weapon_slots] ranuras de armas y [param rune_slots] de runas (nunca más de las que
## hay).
func show_slots(weapon_slots: int, rune_slots: int) -> void:
	_open_weapons = level_up.clamp_weapon_slots(weapon_slots)
	_open_runes = level_up.clamp_rune_slots(rune_slots)
	_refresh()


## Ranuras de armas, de izquierda a derecha.
func get_weapon_slots() -> Array[LoadoutSlot]:
	return _slots(%WeaponSlots as HBoxContainer)


## Ranuras de runas, de izquierda a derecha.
func get_rune_slots() -> Array[LoadoutSlot]:
	return _slots(%RuneSlots as HBoxContainer)


func _refresh() -> void:
	_fill(%WeaponSlots as HBoxContainer, _weapons, _open_weapons, level_up.max_weapon_slots)
	_fill(%RuneSlots as HBoxContainer, _runes, _open_runes, level_up.max_rune_slots)


func _fill(row: HBoxContainer, items: Array[ItemData], open: int, total: int) -> void:
	while row.get_child_count() < total:
		row.add_child(LoadoutSlot.new(slot_size))
	for index: int in total:
		var slot := row.get_child(index) as LoadoutSlot
		if index < items.size():
			slot.show_item(items[index], _levels[items[index].id])
		elif index < open:
			slot.show_empty()
		else:
			slot.show_locked(lock_icon)


func _slots(row: HBoxContainer) -> Array[LoadoutSlot]:
	var slots: Array[LoadoutSlot] = []
	for child: Node in row.get_children():
		slots.append(child as LoadoutSlot)
	return slots
