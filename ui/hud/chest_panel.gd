class_name ChestPanel
extends PanelContainer
## El revelado de un objeto pasivo en el HUD, sin pausar el juego (GDD §5.2, «case opening»): al
## salir uno ([signal EventBus.item_revealed]: un cofre, el premio del jefe) una luz recorre las
## rarezas, cada vez más despacio, y se para en la del objeto; entonces lo muestra (icono, nombre del
## color de su rareza, lo que hace según sus modificadores y su frase) un rato y se oculta. Si falta
## oro para un cofre ([signal EventBus.chest_denied]), solo el aviso. Estilo: variaciones
## [code]ChestPanel[/code], [code]ChestTile[/code], [code]ChestItemLabel[/code],
## [code]ChestEffectLabel[/code] y [code]ChestDescriptionLabel[/code].

## Rarezas, en el orden de las casillas (la de cada una, de su color).
@export var rarities: WeightedTable
## Vueltas enteras que da la luz antes de pararse.
@export_range(0, 10, 1) var loops: int = 3
## Segundos que se queda el objeto (o el aviso) a la vista.
@export_range(0.1, 10.0, 0.1, "suffix:s") var linger: float = 3.0
## Lado de cada casilla.
@export_range(8.0, 128.0, 1.0, "suffix:px") var tile_size: float = 34.0
## Opacidad de las casillas apagadas.
@export_range(0.0, 1.0, 0.05) var dim: float = 0.25
## Clave del aviso de que falta oro (con un [code]%d[/code]: el coste).
@export var denied_key: StringName = &""
## Stats del jugador, para decir cuánto cambia cada una («+10 % Daño (18 → 22)»). Sin ellas, solo lo
## que hace el objeto.
@export var stats: StatsComponent

var _item: PassiveItemData
## Lo que hace el objeto, ya escrito al empezar el revelado: al acabar, puede que ya lo lleve y el
## «antes» saldría con él.
var _item_effects: String = ""
var _reveal_time: float = 0.0
var _elapsed: float = 0.0
var _steps: int = 0
var _lit: int = -1
var _revealing: bool = false
var _hide_left: float = 0.0

@onready var _tiles: HBoxContainer = %ChestTiles
@onready var _result: HBoxContainer = %ChestResult
@onready var _icon: TextureRect = %ChestIcon
@onready var _name: Label = %ChestItemName
@onready var _effects: Label = %ChestItemEffects
@onready var _description: Label = %ChestItemDescription
@onready var _message: Label = %ChestMessage


func _enter_tree() -> void:
	if not EventBus.item_revealed.is_connected(show_opening):
		EventBus.item_revealed.connect(show_opening)
		EventBus.chest_denied.connect(show_denied)


func _ready() -> void:
	visible = false
	set_process(false)


## Empieza a revelar [param item]: la luz tarda [param reveal_time] segundos en pararse en su rareza.
func show_opening(item: PassiveItemData, reveal_time: float) -> void:
	_item = item
	_item_effects = _describe(item)
	_reveal_time = maxf(reveal_time, 0.01)
	_elapsed = 0.0
	_build_tiles()
	_steps = loops * _tiles.get_child_count() + _rarity_index(item)
	_light(0)
	_tiles.visible = true
	_result.visible = false
	_message.visible = false
	_revealing = true
	_hide_left = 0.0
	UiMotion.reveal(self)
	set_process(true)


## Avisa de que falta oro para un cofre de [param cost]. Si hay un revelado en marcha, no lo tapa.
func show_denied(cost: int) -> void:
	if _revealing:
		return
	_message.text = tr(denied_key) % cost
	_message.visible = true
	_tiles.visible = false
	_result.visible = false
	UiMotion.reveal(self)
	_hide_left = linger
	set_process(true)


## ¿La luz aún no se ha parado?
func is_revealing() -> bool:
	return _revealing


## Casilla iluminada ahora (el índice de su rareza; −1 = ninguna).
func get_lit() -> int:
	return _lit


func _process(delta: float) -> void:
	if _revealing:
		_elapsed += delta
		var progress := clampf(_elapsed / _reveal_time, 0.0, 1.0)
		# Frena al final: avanza rápido al principio y cada vez más despacio.
		_light(floori(_steps * (1.0 - pow(1.0 - progress, 2.0))) % _tiles.get_child_count())
		if progress >= 1.0:
			_show_item()
	elif _hide_left > 0.0:
		_hide_left -= delta
		if _hide_left <= 0.0:
			visible = false
			set_process(false)


func _show_item() -> void:
	_revealing = false
	_light(_steps % _tiles.get_child_count())
	_icon.texture = _item.icon
	_name.text = tr(_item.name_key)
	if _item.rarity:
		_name.add_theme_color_override(&"font_color", _item.rarity.color)
	_effects.text = _item_effects
	_description.text = tr(_item.description_key)
	_result.visible = true
	_hide_left = linger


## Una línea por modificador de [param item], con cuánto cambia su stat si se sabe.
func _describe(item: PassiveItemData) -> String:
	var lines := ModifierFormat.describe_all(item.stat_modifiers)
	var changes := ModifierFormat.changes(item.stat_modifiers, stats if is_instance_valid(stats) else null)
	for index: int in lines.size():
		if not changes[index].is_empty():
			lines[index] += " (%s)" % changes[index]
	lines.append_array(item.effect_lines())
	return "\n".join(lines)


func _light(index: int) -> void:
	_lit = index
	for tile_index: int in _tiles.get_child_count():
		(_tiles.get_child(tile_index) as Control).modulate.a = 1.0 if tile_index == index else dim


func _rarity_index(item: PassiveItemData) -> int:
	if item == null or item.rarity == null:
		return 0
	for index: int in rarities.entries.size():
		if (rarities.entries[index] as Rarity).id == item.rarity.id:
			return index
	return 0


func _build_tiles() -> void:
	if _tiles.get_child_count() == rarities.entries.size():
		return
	for child: Node in _tiles.get_children():
		_tiles.remove_child(child)
		child.queue_free()
	for entry: WeightedEntry in rarities.entries:
		var tile := Panel.new()
		tile.theme_type_variation = &"ChestTile"
		tile.custom_minimum_size = Vector2(tile_size, tile_size)
		tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_tiles.add_child(tile)
		var box := tile.get_theme_stylebox(&"panel").duplicate() as StyleBoxFlat
		box.bg_color = (entry as Rarity).color
		tile.add_theme_stylebox_override(&"panel", box)
