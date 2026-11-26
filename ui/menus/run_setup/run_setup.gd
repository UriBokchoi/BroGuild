class_name RunSetup
extends Node3D
## Elegir personaje y nivel antes de jugar. A la izquierda, los personajes; en el centro, el modelo
## del que se mira; a la derecha, su ficha.
##
## Al elegir personaje salen los niveles: un clic marca uno y enseña sus tiers (los que no se han
## abierto, sin poder elegirlos), el objetivo del tier marcado y su lore, y «Jugar» empieza la
## partida. Esc o «Volver» retroceden de los niveles a los personajes y de ahí al menú.

## Se eligió personaje, nivel y tier (1 en un nivel sin tiers).
signal play_requested(character: CharacterData, level: LevelData, tier: int)
## Se pidió volver al menú principal.
signal back_requested

## Personajes que se pueden elegir, en orden.
@export var characters: Array[CharacterData] = []
## Misiones: los personajes que da una aún sin cumplir salen sin poder elegirse (dicen cuál).
@export var quests: QuestCatalog
## Niveles, en orden.
@export var levels: Array[LevelData] = []
## Modelo del personaje que se mira.
@export var model: CharacterModel

var _shown: CharacterData
var _chosen: CharacterData
## Nivel marcado (o [code]null[/code]) y su tier marcado.
var _selected: LevelData
var _tier: int = 1
var _level_group := ButtonGroup.new()
var _tier_group := ButtonGroup.new()

@onready var _side: Control = %Side
@onready var _character_list: VBoxContainer = %CharacterList
@onready var _info: Control = %Info
@onready var _level_panel: Control = %LevelPanel
@onready var _level_list: VBoxContainer = %LevelList
@onready var _level_info: Control = %LevelInfo
@onready var _level_play: Button = %LevelPlay
@onready var _level_name: Label = %LevelName
@onready var _tier_row: HBoxContainer = %TierRow
@onready var _level_goal: Label = %LevelGoal
@onready var _level_strength: Label = %LevelStrength
@onready var _level_lore: Label = %LevelLore
@onready var _name: Label = %CharacterName
@onready var _description: Label = %CharacterDescription
@onready var _stats: VBoxContainer = %CharacterStats
@onready var _weapon_icon: TextureRect = %WeaponIcon
@onready var _weapon_name: Label = %WeaponName
@onready var _passive_name: Label = %PassiveName
@onready var _passive_description: Label = %PassiveDescription


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	for character: CharacterData in characters:
		_character_list.add_child(_character_button(character))
	for level: LevelData in levels:
		_level_list.add_child(_level_button(level))
	(%Choose as Button).pressed.connect(func() -> void: choose(_shown))
	(%Back as Button).pressed.connect(back)
	(%LevelBack as Button).pressed.connect(back)
	_level_play.pressed.connect(func() -> void: play(_selected))
	var first := RunState.character if RunState.character else characters[0]
	show_character(first)
	_show_levels(false)
	(_character_list.get_child(characters.find(first)) as Button).grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(InputActions.PAUSE):
		back()
		get_viewport().set_input_as_handled()


## Muestra a [param character]: su modelo y su ficha.
func show_character(character: CharacterData) -> void:
	if character == null or _chosen:
		return
	_shown = character
	model.dress(character)
	_name.text = character.name_key
	_name.add_theme_color_override(&"font_color", character.color)
	_description.text = character.description_key
	for child: Node in _stats.get_children():
		_stats.remove_child(child)
		child.queue_free()
	for modifier: StatModifier in character.stat_modifiers:
		_stats.add_child(_line(ModifierFormat.describe(modifier), &"StatModifiedLabel"))
	var weapon := character.starting_weapon
	_weapon_icon.texture = weapon.icon if weapon else null
	_weapon_name.text = weapon.name_key if weapon else &""
	_passive_name.text = character.passive_name_key
	_passive_description.text = character.passive_description_key
	(%Choose as Button).disabled = is_locked(character)


## Elige a [param character]: la ficha se cambia por la lista de niveles, sin ninguno marcado. Si
## está bloqueado, no hace nada.
func choose(character: CharacterData) -> void:
	if is_locked(character):
		return
	show_character(character)
	_chosen = character
	_show_levels(true)
	select(null)
	if _level_list.get_child_count() > 0:
		(_level_list.get_child(0) as Button).grab_focus()


## Marca [param level] (o ninguno, con [code]null[/code]) y saca su ficha debajo. «Jugar» solo se
## puede pulsar con un nivel que ya exista.
func select(level: LevelData) -> void:
	_selected = level
	_level_info.visible = level != null
	_level_play.disabled = level == null or not level.is_available()
	for index: int in _level_list.get_child_count():
		(_level_list.get_child(index) as Button).set_pressed_no_signal(level != null and levels[index] == level)
	if level:
		show_level(level)


## Nivel marcado (o [code]null[/code]).
func get_selected() -> LevelData:
	return _selected


## Juega [param level] con el personaje elegido, hasta el tier marcado (si el nivel ya existe).
func play(level: LevelData) -> void:
	if _chosen and level and level.is_available():
		play_requested.emit(_chosen, level, _tier if level == _selected else 1)


## Marca el tier [param tier] del nivel marcado (si está abierto) y enseña su objetivo.
func select_tier(tier: int) -> void:
	if _selected == null or _selected.tiers.is_empty():
		return
	if tier < 1 or tier > _selected.tiers.size() or not Save.is_tier_unlocked(_selected.id, tier):
		return
	_tier = tier
	for index: int in _tier_row.get_child_count():
		(_tier_row.get_child(index) as Button).set_pressed_no_signal(index + 1 == tier)
	var stage := _selected.tiers[tier - 1]
	_level_goal.text = stage.goal_key
	_level_goal.visible = not stage.goal_key.is_empty()
	_level_strength.text = tr(&"TIER_STRENGTH") % stage.strength_percent()
	_level_strength.visible = stage.strength_percent() > 0


## Tier marcado.
func get_tier() -> int:
	return _tier


## Retrocede: de los niveles a los personajes; de ahí, al menú.
func back() -> void:
	if _chosen:
		_chosen = null
		_show_levels(false)
	else:
		back_requested.emit()


## Personaje que se está mirando.
func get_shown() -> CharacterData:
	return _shown


## ¿Se ve la lista de niveles?
func is_choosing_level() -> bool:
	return _level_panel.visible


func _show_levels(on: bool) -> void:
	_side.visible = not on
	_info.visible = not on
	_level_panel.visible = on


func _character_button(character: CharacterData) -> Button:
	var button := Button.new()
	button.text = character.name_key
	button.mouse_entered.connect(show_character.bind(character))
	button.focus_entered.connect(show_character.bind(character))
	button.pressed.connect(choose.bind(character))
	if is_locked(character):
		button.disabled = true
		button.text = tr(&"CHARACTER_LOCKED") % tr(character.name_key)
		button.tooltip_text = tr(quests.quest_for(character).description_key)
	return button


## ¿Falta cumplir la misión que da [param character]?
func is_locked(character: CharacterData) -> bool:
	if quests == null:
		return false
	if Save.profile == null:
		Save.load_profile()
	return quests.is_locked(character, Save.profile)


## Muestra la ficha de [param level]: su nombre, sus tiers, cómo se gana y su lore (lo que no tenga,
## no sale). Marca el último tier jugado si está abierto; si no, el 1.
func show_level(level: LevelData) -> void:
	_level_name.text = level.name_key
	_level_goal.text = level.goal_key
	_level_goal.visible = not level.goal_key.is_empty()
	_level_lore.text = level.lore_key
	_level_lore.visible = not level.lore_key.is_empty()
	for child: Node in _tier_row.get_children():
		_tier_row.remove_child(child)
		child.queue_free()
	_tier = 1
	_tier_row.visible = not level.tiers.is_empty()
	for index: int in level.tiers.size():
		_tier_row.add_child(_tier_button(level, index + 1))
	if not level.tiers.is_empty():
		var last := RunState.tier if RunState.level == level else 1
		select_tier(last if Save.is_tier_unlocked(level.id, last) else 1)


## Botón de un tier: con su número, sin poder pulsarlo si aún no se ha abierto (dice cuál abrirlo).
func _tier_button(level: LevelData, tier: int) -> Button:
	var button := Button.new()
	var unlocked := Save.is_tier_unlocked(level.id, tier)
	button.text = tr(&"TIER_SHORT") % tier
	button.disabled = not unlocked
	button.tooltip_text = String(level.tiers[tier - 1].name_key) if unlocked else tr(&"TIER_LOCKED") % (tier - 1)
	button.theme_type_variation = &"SmallButton"
	button.toggle_mode = true
	button.button_group = _tier_group
	button.pressed.connect(select_tier.bind(tier))
	return button


func _level_button(level: LevelData) -> Button:
	var button := Button.new()
	button.text = String(level.name_key) if level.is_available() else tr(&"LEVEL_COMING_SOON") % tr(level.name_key)
	button.disabled = not level.is_available()
	# Botones bajos: así la lista, la ficha y «Jugar» caben juntos. Se queda hundido el marcado (uno
	# solo a la vez).
	button.theme_type_variation = &"SmallButton"
	button.toggle_mode = true
	button.button_group = _level_group
	button.pressed.connect(select.bind(level))
	return button


func _line(text_value: String, variation: StringName) -> Label:
	var label := Label.new()
	label.text = text_value
	label.theme_type_variation = variation
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label
