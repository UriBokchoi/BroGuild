class_name MainMenu
extends Node3D
## Menú principal: Jugar, Opciones, Archivo, Logros (aún sin hacer: desactivado) y Abandonar, y a la
## derecha, fijos, los récords. Cada panel sustituye a la lista y a los récords y, al cerrarse,
## vuelven. Detrás, los personajes con su aspecto en un claro del Brosque (el mapa generado, siempre
## el mismo) con hojas que caen. Lo muestra Game, que escucha play_requested.

## Se pulsó «Jugar».
signal play_requested

## Personajes que se ven detrás, en el orden de [member models].
@export var characters: Array[CharacterData] = []
## Modelos que visten esos personajes.
@export var models: Array[CharacterModel] = []
## El claro del fondo y su semilla (siempre la misma: así queda bien encuadrado).
@export var layout: LevelLayout
@export var layout_seed: int = 0

@onready var _menu: Control = %Menu
@onready var _right: Control = %Right
@onready var _play: Button = %Play
@onready var _quit: Button = %Quit
@onready var _options: OptionsPanel = %OptionsPanel
@onready var _archive: ArchivePanel = %ArchivePanel
@onready var _records: LeaderboardPanel = %LeaderboardPanel
@onready var _run_detail: RunDetailPanel = %RunDetailPanel


func _enter_tree() -> void:
	# Antes de que el claro se genere (en su _ready).
	if layout and layout.rng == null:
		layout.rng = RandomNumberGenerator.new()
		layout.rng.seed = layout_seed


func _ready() -> void:
	# Sin partida no hay nada que mirar con la cámara: el ratón, libre.
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Al cargar el menú: la selección de personaje enseña sus stats con unidades.
	StatFormat.warm_up()
	for index: int in mini(characters.size(), models.size()):
		models[index].dress(characters[index])
	_play.pressed.connect(play_requested.emit)
	_wire(%Options as Button, _options.open, _options.closed)
	_wire(%Archive as Button, _archive.open, _archive.closed)
	_records.run_chosen.connect(_show_run)
	_run_detail.closed.connect(func() -> void:
		_menu.visible = true
		_right.visible = true
		_play.grab_focus())
	_quit.pressed.connect(_quit_game)
	_play.grab_focus()


## [param button] cambia la lista y los récords por un panel ([param open_panel]); cuando se cierra
## ([param closed]), vuelven, con el foco en el botón.
func _wire(button: Button, open_panel: Callable, closed: Signal) -> void:
	button.pressed.connect(func() -> void:
		_menu.visible = false
		_right.visible = false
		open_panel.call())
	closed.connect(func() -> void:
		_menu.visible = true
		_right.visible = true
		button.grab_focus())


## Abre el detalle de [param record] en su ventana, en lugar de la lista y los récords.
func _show_run(record: RunRecord) -> void:
	_menu.visible = false
	_right.visible = false
	_run_detail.open(record)


func _quit_game() -> void:
	get_tree().quit()
