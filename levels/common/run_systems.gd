class_name RunSystems
extends Node3D
## Todo lo que necesita un nivel para jugar una partida, ya conectado: jugador, horda y oleadas,
## botín, subir de nivel, HUD, pausa, resultados, números de daño y panel de depuración. Un nivel
## pone su mapa, una instancia de esto y el punto donde aparece el jugador; aquí se eligen sus
## oleadas y si empiezan solas.

## Oleadas de este nivel.
@export var waves: WaveData
## Si las oleadas empiezan al cargar el nivel (en el gimnasio las empieza la campana).
@export var autostart_waves: bool = false
## Personaje si no se eligió otro ([code]RunState.character[/code]).
@export var default_character: CharacterData
## Dónde aparece el jugador (vacío: en el origen de esta escena).
@export var spawn_point: Node3D

@export var player: Player
@export var director: WaveDirector


func _enter_tree() -> void:
	# Antes de que entren sus hijos: el jugador y el director arrancan ya con lo de este nivel.
	if default_character:
		player.character = default_character
	if waves:
		director.data = waves
	director.autostart = autostart_waves


func _ready() -> void:
	if spawn_point:
		player.teleport_to(spawn_point.global_position)
