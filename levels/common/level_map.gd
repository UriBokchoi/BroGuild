class_name LevelMap
extends Node3D
## El mapa de una fase (un tier o la arena final): el escenario y lo que la partida necesita saber de
## él (oleadas, jefe, zona de juego, punto de aparición y mensajes al entrar). Lo pone LevelStages.
## Al estar listo cambia los materiales de material_swaps en todo el mapa, también en lo generado:
## así un tier reutiliza las piezas de otro con otros colores.

## Oleadas de este mapa.
@export var waves: WaveData
## Si las oleadas empiezan al entrar.
@export var autostart_waves: bool = false
## Si las oleadas empiezan al vencer al jefe (la oleada infinita de la arena final).
@export var waves_after_boss: bool = false
## Zona del suelo (x, z) dentro de las paredes: los enemigos solo salen dentro.
@export var play_area: Rect2 = Rect2()
## En un mapa redondo, el radio donde pueden salir (0: sin círculo).
@export_range(0.0, 1000.0, 0.5, "suffix:m") var play_radius: float = 0.0
## Dónde aparece el jugador.
@export var spawn_point: Node3D
## Mensajes al entrar (claves de traducción), detrás del nombre de la fase.
@export var intro_keys: Array[StringName] = []
## Jefe del mapa (vacío: sin jefe).
@export var boss: BossData
## Si el jefe sale nada más entrar, aquí (vacío: con sus llaves en el portal, o al acabar la ronda).
@export var boss_spawn: Node3D
## Si morir con el jefe vencido gana la partida aunque no sea la prórroga.
@export var death_wins_after_boss: bool = false
## Nodos que siguen al jugador: se les pone en [code]target[/code] al entrar.
@export var followers: Array[Node] = []
## Materiales que se cambian por otros en todo el mapa (el de la izquierda por el de la derecha).
@export var material_swaps: Dictionary[Material, Material] = {}


func _ready() -> void:
	if not material_swaps.is_empty():
		MaterialSwap.apply(self, material_swaps)


## Hace que lo que sigue al jugador siga a [param player].
func attach(player: Node3D) -> void:
	for follower: Node in followers:
		if follower:
			follower.set(&"target", player)
