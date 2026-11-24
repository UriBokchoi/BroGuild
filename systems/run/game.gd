class_name Game
extends Node
## La raíz del juego y su flujo de pantallas: menú principal, elegir personaje y nivel, la partida.
## Reintentar la vuelve a empezar con otra semilla y salir vuelve al menú. Cada pantalla sustituye a
## la anterior; los demás le piden cambios por el EventBus (ver RunFlow).

## Menú principal: su raíz es un [MainMenu].
@export var main_menu: PackedScene
## Selección de personaje y nivel: su raíz es un [RunSetup].
@export var run_setup: PackedScene
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
	menu.play_requested.connect(show_run_setup)
	_show.call_deferred(menu)


## Muestra la selección de personaje y nivel.
func show_run_setup() -> void:
	var setup := run_setup.instantiate() as RunSetup
	setup.play_requested.connect(_on_setup_done)
	setup.back_requested.connect(show_main_menu)
	_show.call_deferred(setup)


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


func _on_setup_done(character: CharacterData, level: LevelData) -> void:
	RunState.character = character
	play(level)
