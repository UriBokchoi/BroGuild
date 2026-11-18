class_name MainMenu
extends Node3D
## Menú principal: Jugar, Opciones ([OptionsPanel]), Récords ([LeaderboardPanel]), Archivo
## ([ArchivePanel]) y Abandonar (cierra el juego). Cada panel sustituye a la lista y, al cerrarse,
## vuelve a ella. Detrás, los personajes con su aspecto. Lo muestra [Game], que escucha
## [signal play_requested].

## Se pulsó «Jugar».
signal play_requested

## Personajes que se ven detrás, en el orden de [member models].
@export var characters: Array[CharacterData] = []
## Modelos que visten esos personajes.
@export var models: Array[CharacterModel] = []

@onready var _menu: Control = %Menu
@onready var _play: Button = %Play
@onready var _quit: Button = %Quit
@onready var _options: OptionsPanel = %OptionsPanel
@onready var _records: LeaderboardPanel = %LeaderboardPanel
@onready var _archive: ArchivePanel = %ArchivePanel


func _ready() -> void:
	# Sin partida no hay nada que mirar con la cámara: el ratón, libre.
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	for index: int in mini(characters.size(), models.size()):
		models[index].dress(characters[index])
	_play.pressed.connect(play_requested.emit)
	_wire(%Options as Button, _options.open, _options.closed)
	_wire(%Records as Button, _records.open, _records.closed)
	_wire(%Archive as Button, _archive.open, _archive.closed)
	_quit.pressed.connect(_quit_game)
	_play.grab_focus()


## [param button] cambia la lista por un panel ([param open_panel]); cuando se cierra
## ([param closed]), la lista vuelve con el foco en el botón.
func _wire(button: Button, open_panel: Callable, closed: Signal) -> void:
	button.pressed.connect(func() -> void:
		_menu.visible = false
		open_panel.call())
	closed.connect(func() -> void:
		_menu.visible = true
		button.grab_focus())


func _quit_game() -> void:
	get_tree().quit()
