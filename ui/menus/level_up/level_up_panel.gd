class_name LevelUpPanel
extends CanvasLayer
## Elección al subir de nivel: pausa el juego, pide el cursor y muestra una carta por opción. Hay
## que elegir: Esc no la salta. Quien la abre ([LevelUpController]) aplica la elegida y la cierra.

signal chosen(option: LevelUpOption)

@onready var _title: Label = %Title
@onready var _cards: HBoxContainer = %Cards


func _ready() -> void:
	visible = false


func _input(event: InputEvent) -> void:
	# Mientras se elige, Esc no abre la pausa (al cerrarla se reanudaría el juego bajo las cartas).
	if visible and event.is_action_pressed(InputActions.PAUSE):
		get_viewport().set_input_as_handled()


func _exit_tree() -> void:
	if visible:
		_set_open(false)


## Muestra [param options] para el nivel [param level], con el título de subir de nivel o, si se
## da, [param title_key] (una mejora gratis).
func open(options: Array[LevelUpOption], level: int, title_key: StringName = &"") -> void:
	for card: Node in _cards.get_children():
		card.free()
	for option: LevelUpOption in options:
		var card := LevelUpCard.new(option)
		card.pressed.connect(_on_card_pressed.bind(option))
		_cards.add_child(card)
	_title.text = tr(&"LEVEL_UP_TITLE") % level if title_key.is_empty() else tr(title_key)
	_set_open(true)


func close() -> void:
	if visible:
		_set_open(false)


func is_open() -> bool:
	return visible


## Cartas que muestra ahora (para tests).
func get_cards() -> Array[LevelUpCard]:
	var cards: Array[LevelUpCard] = []
	for child: Node in _cards.get_children():
		cards.append(child as LevelUpCard)
	return cards


func _set_open(open_panel: bool) -> void:
	visible = open_panel
	get_tree().paused = open_panel
	EventBus.cursor_requested.emit(self, open_panel)


func _on_card_pressed(option: LevelUpOption) -> void:
	chosen.emit(option)
