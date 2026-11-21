class_name RunSystems
extends Node3D
## Todo lo que necesita un nivel para jugar una partida, ya conectado: jugador, horda y oleadas,
## botín, subir de nivel, jefe, HUD, pausa, resultados, números de daño y panel de depuración. Un
## nivel pone su mapa, una instancia de esto y el punto donde aparece el jugador; aquí se eligen sus
## oleadas, si empiezan solas, la zona donde pueden salir enemigos, los mensajes del principio y su
## jefe.

## Oleadas de este nivel.
@export var waves: WaveData
## Si las oleadas empiezan al cargar el nivel (en el gimnasio las empieza la campana).
@export var autostart_waves: bool = false
## Zona del suelo (x, z) dentro de las paredes del nivel: los enemigos solo salen dentro. Vacía: en
## cualquier sitio con suelo.
@export var play_area: Rect2 = Rect2()
## Personaje si no se eligió otro ([code]RunState.character[/code]).
@export var default_character: CharacterData
## Dónde aparece el jugador (vacío: en el origen de esta escena).
@export var spawn_point: Node3D
## Mensajes al empezar (claves de traducción): el primero, grande. Vacío: ninguno.
@export var intro_keys: Array[StringName] = []
## Jefe del nivel (vacío: sin jefe).
@export var boss: BossData

@export var player: Player
@export var director: WaveDirector
@export var encounter: BossEncounter


func _enter_tree() -> void:
	# Antes de que entren sus hijos: el jugador y el director arrancan ya con lo de este nivel.
	if default_character:
		player.character = default_character
	if waves:
		director.data = waves
	director.autostart = autostart_waves
	director.play_area = play_area
	encounter.data = boss


func _ready() -> void:
	# Al cargar, no en plena partida: la primera carta o ficha con unidades daría un tirón.
	StatFormat.warm_up()
	if spawn_point:
		player.teleport_to(spawn_point.global_position)
	if not intro_keys.is_empty():
		EventBus.level_intro.emit(intro_keys)
