class_name LevelUpPanel
extends ModalPanel
## Elección al subir de nivel: pausa el juego, pide el cursor y muestra una carta por opción. Hay
## que elegir: Esc no la salta ([ModalPanel]). Quien la abre ([LevelUpController]) aplica la elegida
## y la cierra.

signal chosen(option: LevelUpOption)

@onready var _title: Label = %Title
@onready var _cards: HBoxContainer = %Cards


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


## Cartas que muestra ahora (para tests).
func get_cards() -> Array[LevelUpCard]:
	var cards: Array[LevelUpCard] = []
	for child: Node in _cards.get_children():
		cards.append(child as LevelUpCard)
	return cards


func _on_card_pressed(option: LevelUpOption) -> void:
	chosen.emit(option)
