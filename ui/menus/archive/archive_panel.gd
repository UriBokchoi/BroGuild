class_name ArchivePanel
extends PanelContainer
## El Archivo: lo que hay en el juego ([ContentCatalog]), una pestaña por tipo con cuántas entradas
## se han descubierto ([code]Save.discoveries[/code]). Cada entrada es una casilla con su icono; lo
## no descubierto sale como «?». Al pasar el ratón o el foco, su ficha: nombre, frase y lo que hace
## (stats, modificadores, arma inicial y pasiva, mejoras); lo no descubierto, «???» y cómo
## descubrirlo. «Volver» o Esc lo cierran. Lo abre el menú principal.

## Se cerró.
signal closed

## Texto de una casilla sin descubrir.
const LOCKED_TILE := "?"

## Lo que hay.
@export var catalog: ContentCatalog
## Lado de cada casilla.
@export_range(32.0, 160.0, 1.0, "suffix:px") var tile_size: float = 76.0

var _category: ContentCategory
var _tab_group := ButtonGroup.new()
var _tile_group := ButtonGroup.new()

@onready var _tabs: HBoxContainer = %Tabs
@onready var _grid: GridContainer = %Grid
@onready var _icon: TextureRect = %DetailIcon
@onready var _name: Label = %DetailName
@onready var _description: Label = %DetailDescription
@onready var _lines: VBoxContainer = %DetailLines
@onready var _back: Button = %Back


func _ready() -> void:
	_back.pressed.connect(close)
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(InputActions.PAUSE):
		close()
		get_viewport().set_input_as_handled()


## Muestra el Archivo con lo descubierto hasta ahora, en la primera pestaña.
func open() -> void:
	_build_tabs()
	if not catalog.categories.is_empty():
		show_category(catalog.categories[0])
	visible = true
	_back.grab_focus()


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


## Enseña las entradas de [param category] y la ficha de la primera.
func show_category(category: ContentCategory) -> void:
	_category = category
	for tab: Button in get_tabs():
		var tab_category: ContentCategory = tab.get_meta(&"category")
		tab.set_pressed_no_signal(tab_category == category)
	for tile: Node in _grid.get_children():
		_grid.remove_child(tile)
		tile.queue_free()
	for entry: Resource in category.entries:
		_grid.add_child(_make_tile(entry))
	if not category.entries.is_empty():
		show_entry(category.entries[0])


## Enseña la ficha de [param entry] (de la pestaña abierta).
func show_entry(entry: Resource) -> void:
	for child: Node in _lines.get_children():
		_lines.remove_child(child)
		child.queue_free()
	_name.remove_theme_color_override(&"font_color")
	if not is_discovered(entry):
		_icon.texture = null
		_name.text = "ARCHIVE_LOCKED"
		_description.text = _category.hint_key
		return
	_icon.texture = entry.get(&"icon")
	_name.text = entry.get(&"name_key")
	_description.text = entry.get(&"description_key")
	if entry is CharacterData:
		_show_character(entry as CharacterData)
	elif entry is PassiveItemData:
		_show_item(entry as PassiveItemData)
	elif entry is RuneData:
		_show_rune(entry as RuneData)
	for stat: StringName in _category.shown_stats:
		_show_stat(entry, stat)


## ¿Se ha descubierto [param entry] (de la pestaña abierta)?
func is_discovered(entry: Resource) -> bool:
	var id: StringName = entry.get(&"id")
	return Save.discoveries != null and Save.discoveries.has(_category.id, id)


## Los textos de la ficha que se ve ahora, de arriba abajo (sin el nombre ni la frase).
func get_detail_lines() -> PackedStringArray:
	var lines := PackedStringArray()
	for line: Node in _lines.get_children():
		lines.append((line as Label).text)
	return lines


## Las casillas de la pestaña abierta, en orden.
func get_tiles() -> Array[Button]:
	var tiles: Array[Button] = []
	tiles.assign(_grid.get_children())
	return tiles


## Las pestañas, en orden.
func get_tabs() -> Array[Button]:
	var tabs: Array[Button] = []
	tabs.assign(_tabs.get_children())
	return tabs


func _build_tabs() -> void:
	for tab: Node in _tabs.get_children():
		_tabs.remove_child(tab)
		tab.queue_free()
	for category: ContentCategory in catalog.categories:
		var tab := Button.new()
		tab.theme_type_variation = &"SmallButton"
		tab.toggle_mode = true
		tab.button_group = _tab_group
		tab.text = tr(&"ARCHIVE_TAB") % [tr(category.name_key), _found(category), category.entries.size()]
		tab.set_meta(&"category", category)
		tab.pressed.connect(show_category.bind(category))
		_tabs.add_child(tab)


func _found(category: ContentCategory) -> int:
	if Save.discoveries == null:
		return 0
	var found := 0
	for entry: Resource in category.entries:
		var id: StringName = entry.get(&"id")
		if Save.discoveries.has(category.id, id):
			found += 1
	return found


func _make_tile(entry: Resource) -> Button:
	var tile := Button.new()
	tile.theme_type_variation = &"SmallButton"
	tile.custom_minimum_size = Vector2(tile_size, tile_size)
	tile.toggle_mode = true
	tile.button_group = _tile_group
	tile.expand_icon = true
	tile.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if is_discovered(entry):
		tile.icon = entry.get(&"icon")
	else:
		tile.text = LOCKED_TILE
	tile.mouse_entered.connect(show_entry.bind(entry))
	tile.focus_entered.connect(show_entry.bind(entry))
	tile.pressed.connect(show_entry.bind(entry))
	return tile


func _show_character(character: CharacterData) -> void:
	_name.add_theme_color_override(&"font_color", character.color)
	for modifier: StatModifier in character.stat_modifiers:
		_add_line(ModifierFormat.describe(modifier), &"StatModifiedLabel")
	if character.starting_weapon:
		_add_line(tr(&"ARCHIVE_STARTING_WEAPON") % tr(character.starting_weapon.name_key), &"StatNameLabel")
	_add_line(tr(&"ARCHIVE_PASSIVE") % tr(character.passive_name_key), &"StatNameLabel")
	_add_line(character.passive_description_key, &"StatBaseLabel")


func _show_item(item: PassiveItemData) -> void:
	if item.rarity:
		_name.add_theme_color_override(&"font_color", item.rarity.color)
		var rarity := _add_line(item.rarity.name_key, &"StatGroupLabel")
		rarity.add_theme_color_override(&"font_color", item.rarity.color)
	for line: String in ModifierFormat.describe_all(item.stat_modifiers):
		_add_line(line, &"StatModifiedLabel")


func _show_rune(rune: RuneData) -> void:
	var names := PackedStringArray()
	for upgrade_stat: UpgradeStat in rune.upgrade_stats:
		names.append(tr(StatFormat.name_key(upgrade_stat.stat)))
	_add_line(tr(&"ARCHIVE_UPGRADES") % ", ".join(names), &"StatNameLabel")


## Una línea con [param stat] de los datos de [param entry] (su arma o sus fuentes de stats), si la
## tiene.
func _show_stat(entry: Resource, stat: StringName) -> void:
	for source: Resource in _stat_sources(entry):
		for property: Dictionary in source.get_property_list():
			var property_name: String = property["name"]
			if property_name == String(stat) and StatBlock.is_stat_property(property):
				var value: float = source.get(stat)
				_add_line(tr(&"ARCHIVE_STAT") % [tr(StatFormat.name_key(stat)), StatFormat.format(value, property)], &"StatNameLabel")
				return


static func _stat_sources(entry: Resource) -> Array[Resource]:
	var sources: Array[Resource] = []
	if entry is WeaponData:
		sources.append((entry as WeaponData).stats)
	elif entry is EnemyData:
		sources.assign((entry as EnemyData).stat_sources)
	return sources


func _add_line(text: String, style: StringName) -> Label:
	var line := Label.new()
	line.theme_type_variation = style
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.text = text
	_lines.add_child(line)
	return line
