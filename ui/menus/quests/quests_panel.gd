class_name QuestsPanel
extends PanelContainer
## La pestaña «Misiones» del menú principal (también hace de logros), con dos pestañas: las pendientes
## (lo que desbloquean y lo que hay que hacer) y las completadas, de la última a la primera, con su
## fecha. Se cumplen solas al acabar una partida. «Volver» o Esc la cierran.

## Se cerró.
signal closed

## Lado del icono de lo que desbloquea.
const ICON_SIZE := 44.0

@export var catalog: QuestCatalog

var _showing_done: bool = false
var _tab_group := ButtonGroup.new()

@onready var _pending_tab: Button = %PendingTab
@onready var _done_tab: Button = %DoneTab
@onready var _list: VBoxContainer = %List
@onready var _empty: Label = %Empty
@onready var _scroll: ScrollContainer = %Scroll
@onready var _back: Button = %Back


func _ready() -> void:
	_back.pressed.connect(close)
	_pending_tab.button_group = _tab_group
	_done_tab.button_group = _tab_group
	_pending_tab.pressed.connect(show_tab.bind(false))
	_done_tab.pressed.connect(show_tab.bind(true))
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(InputActions.PAUSE):
		close()
		get_viewport().set_input_as_handled()


## Muestra las misiones con las cumplidas hasta ahora, en la pestaña de las pendientes.
func open() -> void:
	if Save.profile == null:
		Save.load_profile()
	show_tab(false)
	UiMotion.reveal(self)
	_back.grab_focus()


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


## Enseña las completadas ([param done]) o las pendientes.
func show_tab(done: bool) -> void:
	_showing_done = done
	var pending := _quests(false)
	var completed := _quests(true)
	_pending_tab.text = tr(&"QUESTS_TAB_PENDING") % pending.size()
	_done_tab.text = tr(&"QUESTS_TAB_DONE") % completed.size()
	_pending_tab.set_pressed_no_signal(not done)
	_done_tab.set_pressed_no_signal(done)
	for child: Node in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	var shown := completed if done else pending
	for index: int in shown.size():
		_list.add_child(_row(shown[index], index % 2 == 1))
	_empty.text = &"QUESTS_EMPTY_DONE" if done else &"QUESTS_EMPTY_PENDING"
	_empty.visible = shown.is_empty()
	_scroll.scroll_vertical = 0


## ¿Enseña las completadas?
func is_showing_done() -> bool:
	return _showing_done


## El estado de cada misión que se ve, en orden («Pendiente», o la fecha en que se completó).
func get_states() -> PackedStringArray:
	var states := PackedStringArray()
	for row: Node in _list.get_children():
		states.append((row.find_child("State", true, false) as Label).text)
	return states


## Las misiones completadas ([param done], de la última a la primera) o las pendientes (en orden).
func _quests(done: bool) -> Array[QuestData]:
	var found: Array[QuestData] = []
	for quest: QuestData in catalog.quests:
		if Save.profile.has_completed(quest.id) == done:
			found.append(quest)
	if done:
		found.sort_custom(func(a: QuestData, b: QuestData) -> bool:
			return Save.profile.completed_at(a.id) > Save.profile.completed_at(b.id))
	return found


func _row(quest: QuestData, alternate: bool) -> PanelContainer:
	var done := Save.profile.has_completed(quest.id)
	var row := PanelContainer.new()
	row.theme_type_variation = &"StatRowAlt" if alternate else &"StatRow"
	var layout := HBoxContainer.new()
	layout.theme_type_variation = &"CardRow"
	row.add_child(layout)
	var icon := TextureRect.new()
	var first: Resource = quest.rewards[0] if not quest.rewards.is_empty() else null
	icon.texture = first.get(&"icon") as Texture2D if first else null
	icon.custom_minimum_size = Vector2.ONE * ICON_SIZE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.modulate = Color.WHITE if done else Color(1.0, 1.0, 1.0, 0.45)
	layout.add_child(icon)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(text)
	text.add_child(_label(quest.reward_names(), &"StatNameLabel"))
	var description := _label(String(quest.description_key), &"StatBaseLabel")
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_child(description)
	var state_text := tr(&"QUESTS_PENDING")
	if done:
		var when := Save.profile.completed_at(quest.id)
		state_text = tr(&"QUESTS_DONE_AT") % DateText.format(when) if when > 0.0 else tr(&"QUESTS_DONE")
	var state := _label(state_text, &"StatModifiedLabel" if done else &"StatBaseLabel")
	state.name = "State"
	state.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	layout.add_child(state)
	return row


func _label(text_value: String, variation: StringName) -> Label:
	var label := Label.new()
	label.text = text_value
	label.theme_type_variation = variation
	return label
