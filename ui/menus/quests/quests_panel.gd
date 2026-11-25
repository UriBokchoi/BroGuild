class_name QuestsPanel
extends PanelContainer
## La pestaña «Misiones» del menú principal: cada misión con lo que desbloquea (icono y nombre), lo
## que hay que hacer y si ya está hecha. Se cumplen solas al acabar una partida. «Volver» o Esc la
## cierran.

## Se cerró.
signal closed

## Lado del icono de lo que desbloquea.
const ICON_SIZE := 44.0

@export var catalog: QuestCatalog

@onready var _list: VBoxContainer = %List
@onready var _scroll: ScrollContainer = %Scroll
@onready var _back: Button = %Back


func _ready() -> void:
	_back.pressed.connect(close)
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(InputActions.PAUSE):
		close()
		get_viewport().set_input_as_handled()


## Muestra las misiones con las cumplidas hasta ahora.
func open() -> void:
	if Save.profile == null:
		Save.load_profile()
	for child: Node in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	for index: int in catalog.quests.size():
		_list.add_child(_row(catalog.quests[index], index % 2 == 1))
	_scroll.scroll_vertical = 0
	UiMotion.reveal(self)
	_back.grab_focus()


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


## El estado de cada misión, en orden («Hecha» o «Pendiente», ya traducido).
func get_states() -> PackedStringArray:
	var states := PackedStringArray()
	for row: Node in _list.get_children():
		states.append((row.find_child("State", true, false) as Label).text)
	return states


func _row(quest: QuestData, alternate: bool) -> PanelContainer:
	var done := Save.profile.has_completed(quest.id)
	var row := PanelContainer.new()
	row.theme_type_variation = &"StatRowAlt" if alternate else &"StatRow"
	var layout := HBoxContainer.new()
	layout.theme_type_variation = &"CardRow"
	row.add_child(layout)
	var icon := TextureRect.new()
	icon.texture = quest.reward.get(&"icon") as Texture2D if quest.reward else null
	icon.custom_minimum_size = Vector2.ONE * ICON_SIZE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.modulate = Color.WHITE if done else Color(1.0, 1.0, 1.0, 0.45)
	layout.add_child(icon)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(text)
	var reward_name := str(quest.reward.get(&"name_key")) if quest.reward else ""
	text.add_child(_label(reward_name, &"StatNameLabel"))
	var description := _label(String(quest.description_key), &"StatBaseLabel")
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_child(description)
	var state := _label(tr(&"QUESTS_DONE" if done else &"QUESTS_PENDING"),
		&"StatModifiedLabel" if done else &"StatBaseLabel")
	state.name = "State"
	state.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	layout.add_child(state)
	return row


func _label(text_value: String, variation: StringName) -> Label:
	var label := Label.new()
	label.text = text_value
	label.theme_type_variation = variation
	return label
