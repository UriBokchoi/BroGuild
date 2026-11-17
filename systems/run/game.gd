class_name Game
extends Node
## Raíz del juego y su flujo de pantallas: empieza en el menú principal; «Jugar» empieza una partida
## en el nivel elegido ([code]RunState.level[/code]); reintentar la vuelve a empezar con otra
## semilla y salir vuelve al menú. Cada pantalla es una escena que sustituye a la anterior. Los
## demás le piden cosas por el [code]EventBus[/code] (ver [RunFlow]).

## Menú principal: su raíz es un [MainMenu].
@export var main_menu: PackedScene
## Nivel que se juega si no se ha elegido otro.
@export var default_level: LevelData

var _screen: Node


func _ready() -> void:
	EventBus.retry_requested.connect(retry)
	EventBus.main_menu_requested.connect(show_main_menu)
	show_main_menu()


## Termina la partida (si la hay) y muestra el menú principal.
func show_main_menu() -> void:
	RunState.end_run()
	var menu := main_menu.instantiate() as MainMenu
	menu.play_requested.connect(play)
	_show.call_deferred(menu)


## Empieza una partida en [param level] (sin nivel, el elegido o el de serie).
func play(level: LevelData = null) -> void:
	if level:
		RunState.level = level
	elif RunState.level == null:
		RunState.level = default_level
	RunState.start_run(Rng.make_seed())
	_show.call_deferred(RunState.level.scene.instantiate())


## Vuelve a empezar la partida en el mismo nivel, con otra semilla.
func retry() -> void:
	play(RunState.level)


## Pantalla que se muestra ahora.
func get_screen() -> Node:
	return _screen


## Diferido: quien lo pide suele ser un botón de la pantalla que se va.
func _show(screen: Node) -> void:
	if _screen:
		_screen.free()
	_screen = screen
	add_child(screen)
