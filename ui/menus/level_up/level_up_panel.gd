class_name LevelUpPanel
extends ModalPanel
## Las cartas al subir de nivel. Pausa el juego y obliga a elegir (Esc no lo salta); quien lo abre,
## el LevelUpController, aplica la elegida.
##
## Las cartas de mejora giran como una ruleta y se paran una tras otra; un clic las para todas.
## «Volver a tirar» pide cartas nuevas. Al elegir una mejora que aún puede subir de rareza se puede
## apostar a doble o nada: el controlador decide y el panel lo enseña con resolve_double. Antes de
## decidir, el clic derecho deshace la elección y deja escoger otra carta.
##
## Con la mejora del menú, «Saltar» (verde) se salta la elección y «Vetar» (rojo) espera a que se
## pulse una carta para vetarla (el controlador la quita del resto de la partida y saca otras).

signal chosen(option: LevelUpOption)
## Se pulsó «volver a tirar».
signal reroll_requested
## Se pulsó «Saltar».
signal skip_requested
## Se vetó la carta de [param option].
signal ban_requested(option: LevelUpOption)
## Se apuesta [param option] al doble o nada.
signal double_requested(option: LevelUpOption)

enum Phase { CHOOSING, BETTING, RESOLVING }
## Cómo se ven las otras cartas mientras se decide la apuesta.
const DIMMED := Color(1.0, 1.0, 1.0, 0.35)
## Transparencia del panel mientras se prepara ([method warm_up]): casi invisible, pero se dibuja.
const WARM_UP_ALPHA := 0.01

## Rarezas de la ruleta, cómo gira y el doble o nada ([code]data/progression/level_up.tres[/code]).
@export var data: LevelUpData

var _can_reroll: bool = false
## Saltos y vetos que le quedan; con [member _skip_ban_shown] a false, ni se ven.
var _skips_left: int = 0
var _bans_left: int = 0
var _skip_ban_shown: bool = false
## Pulsó «Vetar»: la siguiente carta que pulse se veta.
var _banning: bool = false
var _double_chance: float = 0.0
var _phase: Phase = Phase.CHOOSING
## La carta elegida en el doble o nada, y lo que sale de la apuesta (null: perdida).
var _bet: LevelUpCard
var _result: LevelUpOption
var _result_left: float = 0.0
var _result_shown: bool = false
## Se está preparando ([method warm_up]): visible pero no abierto.
var _warming: bool = false

@onready var _title: Label = %Title
@onready var _subtitle: Label = %Subtitle
@onready var _cards: HBoxContainer = %Cards
@onready var _reroll: Button = %Reroll
@onready var _skip: Button = %Skip
@onready var _ban: Button = %Ban
@onready var _bet_row: HBoxContainer = %Bet
@onready var _keep: Button = %Keep
@onready var _double: Button = %Double


func _ready() -> void:
	super()
	_reroll.pressed.connect(reroll_requested.emit)
	_skip.pressed.connect(_on_skip_pressed)
	_ban.pressed.connect(_on_ban_pressed)
	_keep.pressed.connect(_on_keep_pressed)
	_double.pressed.connect(_on_double_pressed)
	set_process(false)


func _input(event: InputEvent) -> void:
	super(event)
	if visible and _phase == Phase.BETTING and _is_right_click(event):
		cancel_bet()
		get_viewport().set_input_as_handled()
		return
	if not visible or not _skips_spin(event):
		return
	if is_spinning():
		stop_spins()
		get_viewport().set_input_as_handled()
	elif _phase == Phase.RESOLVING:
		_result_left = 0.0
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if _phase == Phase.RESOLVING and not is_spinning():
		if not _result_shown:
			_result_shown = true
			_show_result()
		_result_left -= delta
		if _result_left <= 0.0:
			_finish_bet()
			return
	_refresh()
	if _phase != Phase.RESOLVING and not is_spinning():
		set_process(false)


## Muestra [param options] para el nivel [param level], con el título de subir de nivel o, si se
## da, [param title_key] (una mejora gratis). «Volver a tirar» cuesta [param reroll_cost] y solo se
## puede si [param reroll_allowed]. El doble o nada se gana con [param double_chance] (0: sin él).
func open(
	options: Array[LevelUpOption],
	level: int,
	title_key: StringName = &"",
	reroll_cost: int = 0,
	reroll_allowed: bool = false,
	double_chance: float = 0.0,
) -> void:
	_warming = false
	_set_alpha(1.0)
	for card: Node in _cards.get_children():
		card.free()
	var wheel := _wheel()
	for index: int in options.size():
		var card := _add_card(options[index])
		if data:
			card.spin(wheel, data.spin_time + data.spin_stagger * index, data.spin_loops)
	_title.text = tr(&"LEVEL_UP_TITLE") % level if title_key.is_empty() else tr(title_key)
	_reroll.text = tr(&"LEVEL_UP_REROLL") % reroll_cost
	_can_reroll = reroll_allowed
	_double_chance = double_chance
	_double.text = tr(&"LEVEL_UP_DOUBLE") % roundi(double_chance * 100.0)
	_phase = Phase.CHOOSING
	_bet = null
	_banning = false
	_refresh()
	_set_open(true)
	set_process(true)


## Cuántos saltos y vetos le quedan ([param skips_left], [param bans_left]); con [param shown] a
## false (sin la mejora), los botones no se ven. Llamar antes de [method open].
func set_skip_ban(skips_left: int, bans_left: int, shown: bool) -> void:
	_skips_left = skips_left
	_bans_left = bans_left
	_skip_ban_shown = shown


## ¿Está esperando la carta que vetar?
func is_banning() -> bool:
	return _banning


## ¿Se ven y se pueden usar «Saltar» y «Vetar»?
func can_skip() -> bool:
	return _skip.visible and not _skip.disabled


func can_ban() -> bool:
	return _ban.visible and not _ban.disabled


## El resultado del doble o nada de la carta apostada: [param result] es la mejora que sale al ganar
## (de la rareza siguiente) o [code]null[/code] si se pierde. La carta gira y, al pararse, se ve.
func resolve_double(result: LevelUpOption) -> void:
	if _phase != Phase.BETTING or _bet == null:
		return
	var from := _bet.option.rarity()
	var wheel: Array[Rarity] = [from, data.next_rarity(from)]
	_result = result
	if result:
		# La carta ganadora es otra mejora: sustituye a la apostada en su sitio.
		var index := _bet.get_index()
		var winner := _add_card(result)
		_cards.move_child(winner, index)
		_bet.free()
		_bet = winner
	_bet.spin(wheel, data.double_spin_time, data.double_spin_loops)
	_phase = Phase.RESOLVING
	_result_left = data.double_result_time
	_result_shown = false
	_refresh()
	set_process(true)


func _set_open(open_panel: bool) -> void:
	super(open_panel)
	if not open_panel:
		# Cerrado no gira nada por detrás (ni suena): fuera las cartas.
		for card: Node in _cards.get_children():
			card.queue_free()
		_bet = null
		_phase = Phase.CHOOSING
		set_process(false)


## Dibuja el panel un momento, sin verse ni pausar, con [param sample] de cartas: así la primera
## subida de nivel no paga el primer dibujo del desenfoque y de las cartas (unos 40 ms). Se llama al
## cargar el nivel; al fotograma siguiente lo deja como estaba.
func warm_up(sample: Array[LevelUpOption]) -> void:
	if visible or sample.is_empty():
		return
	for option: LevelUpOption in sample:
		_add_card(option)
	_set_alpha(WARM_UP_ALPHA)
	_warming = true
	visible = true
	await get_tree().process_frame
	await get_tree().process_frame
	# Una subida de nivel de verdad en medio ([method open]) lo cancela.
	if not _warming or not is_inside_tree():
		return
	_warming = false
	visible = false
	_set_alpha(1.0)
	for card: Node in _cards.get_children():
		card.queue_free()


## ¿Está abierto de verdad? (Mientras se prepara se dibuja, pero no cuenta.)
func is_open() -> bool:
	return super() and not _warming


func _set_alpha(alpha: float) -> void:
	for child: Node in get_children():
		if child is CanvasItem:
			(child as CanvasItem).modulate.a = alpha


## Cartas que muestra ahora (para tests).
func get_cards() -> Array[LevelUpCard]:
	var cards: Array[LevelUpCard] = []
	for child: Node in _cards.get_children():
		if not child.is_queued_for_deletion():
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
	return not _reroll.disabled and _reroll.visible


## En qué está: eligiendo, decidiendo si apuesta o viendo cómo sale la apuesta.
func get_phase() -> Phase:
	return _phase


## ¿Se puede apostar [param option] al doble o nada? (Una mejora que aún puede subir de rareza.)
func can_double(option: LevelUpOption) -> bool:
	return _double_chance > 0.0 and data != null and data.next_rarity(option.rarity()) != null


func _add_card(option: LevelUpOption) -> LevelUpCard:
	var card := LevelUpCard.new(option)
	card.pressed.connect(_on_card_pressed.bind(card))
	_cards.add_child(card)
	return card


func _refresh() -> void:
	var spinning := is_spinning()
	_reroll.visible = _phase == Phase.CHOOSING
	_reroll.disabled = spinning or not _can_reroll
	_skip.visible = _skip_ban_shown and _phase == Phase.CHOOSING
	_skip.disabled = spinning or _skips_left <= 0
	_skip.text = tr(&"LEVEL_UP_SKIP") % _skips_left
	_ban.visible = _skip_ban_shown and _phase == Phase.CHOOSING
	_ban.disabled = spinning or _bans_left <= 0
	_ban.text = tr(&"LEVEL_UP_BAN") % _bans_left
	_ban.set_pressed_no_signal(_banning)
	_bet_row.visible = _phase == Phase.BETTING
	match _phase:
		Phase.BETTING:
			_subtitle.text = "LEVEL_UP_BET"
		Phase.RESOLVING:
			_subtitle.text = "LEVEL_UP_SPINNING"
		_:
			if _banning:
				_subtitle.text = "LEVEL_UP_BAN_PICK"
			else:
				_subtitle.text = "LEVEL_UP_SPINNING" if spinning else "LEVEL_UP_CHOOSE"


## Las rarezas en el orden de la tabla.
func _wheel() -> Array[Rarity]:
	var wheel: Array[Rarity] = []
	if data and data.rarities:
		wheel.assign(data.rarities.entries)
	return wheel


func _show_result() -> void:
	if _result == null:
		_bet.mark_lost()
	EventBus.double_or_nothing_resolved.emit(_result != null)


func _finish_bet() -> void:
	var result := _result
	_phase = Phase.CHOOSING
	_result = null
	set_process(false)
	chosen.emit(result)


static func _skips_spin(event: InputEvent) -> bool:
	var click := event as InputEventMouseButton
	if click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		return true
	return event.is_action_pressed(&"ui_accept")


func _on_card_pressed(card: LevelUpCard) -> void:
	if _phase != Phase.CHOOSING:
		return
	if _banning:
		_banning = false
		_refresh()
		ban_requested.emit(card.option)
		return
	if not can_double(card.option):
		chosen.emit(card.option)
		return
	_bet = card
	_phase = Phase.BETTING
	for other: LevelUpCard in get_cards():
		if other != card:
			other.disabled = true
			other.modulate = DIMMED
	_refresh()


func _on_skip_pressed() -> void:
	if _phase == Phase.CHOOSING and _skips_left > 0:
		_banning = false
		skip_requested.emit()


## «Vetar» se queda pulsado hasta que se elige la carta; pulsarlo otra vez lo deja.
func _on_ban_pressed() -> void:
	_banning = _phase == Phase.CHOOSING and _bans_left > 0 and not _banning
	_refresh()


## Deshace la carta elegida (antes de quedársela o apostarla): vuelve a elegir entre todas.
func cancel_bet() -> void:
	if _phase != Phase.BETTING:
		return
	_bet = null
	_phase = Phase.CHOOSING
	for card: LevelUpCard in get_cards():
		card.disabled = false
		card.modulate = Color.WHITE
	_refresh()


static func _is_right_click(event: InputEvent) -> bool:
	var click := event as InputEventMouseButton
	return click != null and click.pressed and click.button_index == MOUSE_BUTTON_RIGHT


func _on_keep_pressed() -> void:
	if _phase == Phase.BETTING:
		_phase = Phase.CHOOSING
		chosen.emit(_bet.option)


func _on_double_pressed() -> void:
	if _phase == Phase.BETTING:
		double_requested.emit(_bet.option)
