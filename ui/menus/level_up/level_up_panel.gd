class_name LevelUpPanel
extends ModalPanel
## Elección al subir de nivel: pausa el juego, pide el cursor y muestra una carta por opción. Hay
## que elegir: Esc no la salta ([ModalPanel]). Quien la abre ([LevelUpController]) aplica la elegida
## y la cierra.
##
## La ruleta (GDD §5): las cartas de mejora giran por las rarezas y se paran una tras otra
## ([method LevelUpCard.spin], con los tiempos de [member data]); hasta entonces no se puede elegir.
## Un clic o «aceptar» las para todas ya. «Volver a tirar» pide otras cartas
## ([signal reroll_requested]); quien abre el panel cobra y lo vuelve a abrir.

signal chosen(option: LevelUpOption)
## Se pulsó «volver a tirar».
signal reroll_requested

## Rarezas de la ruleta y cómo gira ([code]data/progression/level_up.tres[/code]).
@export var data: LevelUpData

var _can_reroll: bool = false

@onready var _title: Label = %Title
@onready var _subtitle: Label = %Subtitle
@onready var _cards: HBoxContainer = %Cards
@onready var _reroll: Button = %Reroll


func _ready() -> void:
	super()
	_reroll.pressed.connect(reroll_requested.emit)
	set_process(false)


func _input(event: InputEvent) -> void:
	super(event)
	if visible and is_spinning() and _skips_spin(event):
		stop_spins()
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	_refresh()
	if not is_spinning():
		set_process(false)


## Muestra [param options] para el nivel [param level], con el título de subir de nivel o, si se
## da, [param title_key] (una mejora gratis). «Volver a tirar» cuesta [param reroll_cost] y solo se
## puede si [param reroll_allowed].
func open(
	options: Array[LevelUpOption],
	level: int,
	title_key: StringName = &"",
	reroll_cost: int = 0,
	reroll_allowed: bool = false,
) -> void:
	for card: Node in _cards.get_children():
		card.free()
	var wheel := _wheel()
	for index: int in options.size():
		var option := options[index]
		var card := LevelUpCard.new(option)
		card.pressed.connect(_on_card_pressed.bind(option))
		_cards.add_child(card)
		if data:
			card.spin(wheel, data.spin_time + data.spin_stagger * index, data.spin_loops)
	_title.text = tr(&"LEVEL_UP_TITLE") % level if title_key.is_empty() else tr(title_key)
	_reroll.text = tr(&"LEVEL_UP_REROLL") % reroll_cost
	_can_reroll = reroll_allowed
	_refresh()
	_set_open(true)
	set_process(true)


func _set_open(open_panel: bool) -> void:
	super(open_panel)
	if not open_panel:
		# Cerrado no gira nada por detrás (ni suena): fuera las cartas.
		for card: Node in _cards.get_children():
			card.queue_free()
		set_process(false)


## Cartas que muestra ahora (para tests).
func get_cards() -> Array[LevelUpCard]:
	var cards: Array[LevelUpCard] = []
	for child: Node in _cards.get_children():
		cards.append(child as LevelUpCard)
	return cards


## ¿Gira aún alguna carta?
func is_spinning() -> bool:
	return get_cards().any(func(card: LevelUpCard) -> bool: return card.is_spinning())


## Para ya todas las cartas en su rareza.
func stop_spins() -> void:
	for card: LevelUpCard in get_cards():
		card.stop_spin()
	_refresh()


## ¿Se puede pulsar «volver a tirar» ahora?
func can_reroll() -> bool:
	return not _reroll.disabled


func _refresh() -> void:
	var spinning := is_spinning()
	_reroll.disabled = spinning or not _can_reroll
	_subtitle.text = "LEVEL_UP_SPINNING" if spinning else "LEVEL_UP_CHOOSE"


## Las rarezas en el orden de la tabla.
func _wheel() -> Array[Rarity]:
	var wheel: Array[Rarity] = []
	if data and data.rarities:
		wheel.assign(data.rarities.entries)
	return wheel


static func _skips_spin(event: InputEvent) -> bool:
	var click := event as InputEventMouseButton
	if click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		return true
	return event.is_action_pressed(&"ui_accept")


func _on_card_pressed(option: LevelUpOption) -> void:
	chosen.emit(option)
