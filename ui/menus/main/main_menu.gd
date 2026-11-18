class_name MainMenu
extends Node3D
## Menú principal: Jugar, Opciones ([OptionsPanel]), Récords ([LeaderboardPanel]), Archivo
## (desactivado hasta que exista) y Abandonar (cierra el juego). Detrás, los personajes con su
## aspecto. Lo muestra [Game], que escucha [signal play_requested].

## Se pulsó «Jugar».
signal play_requested

## Personajes que se ven detrás, en el orden de [member models].
@export var characters: Array[CharacterData] = []
## Modelos que visten esos personajes.
@export var models: Array[CharacterModel] = []

@onready var _menu: Control = %Menu
@onready var _play: Button = %Play
@onready var _options_button: Button = %Options
@onready var _records_button: Button = %Records
@onready var _quit: Button = %Quit
@onready var _options: OptionsPanel = %OptionsPanel
@onready var _records: LeaderboardPanel = %LeaderboardPanel


func _ready() -> void:
	# Sin partida no hay nada que mirar con la cámara: el ratón, libre.
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	for index: int in mini(characters.size(), models.size()):
		models[index].dress(characters[index])
	_play.pressed.connect(play_requested.emit)
	_options_button.pressed.connect(_open_options)
	_options.closed.connect(_on_options_closed)
	_records_button.pressed.connect(_open_records)
	_records.closed.connect(_on_records_closed)
	_quit.pressed.connect(_quit_game)
	_play.grab_focus()


func _open_options() -> void:
	_menu.visible = false
	_options.open()


func _on_options_closed() -> void:
	_menu.visible = true
	_options_button.grab_focus()


func _open_records() -> void:
	_menu.visible = false
	_records.open()


func _on_records_closed() -> void:
	_menu.visible = true
	_records_button.grab_focus()


func _quit_game() -> void:
	get_tree().quit()
