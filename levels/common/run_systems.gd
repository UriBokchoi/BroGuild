class_name RunSystems
extends Node3D
## Todo lo que un nivel necesita para jugar una partida, ya conectado: jugador, horda, oleadas, botín,
## subir de nivel, jefe, HUD, pausa y resultados. Un nivel pone su mapa, una instancia de esto y el
## punto de aparición, y elige aquí sus oleadas, su jefe y sus mensajes (en un nivel con tiers se los
## pone LevelStages, mapa a mapa).

## Oleadas de este nivel.
@export var waves: WaveData
## Si las oleadas empiezan al cargar el nivel (en el gimnasio las empieza la campana).
@export var autostart_waves: bool = false
## Zona del suelo (x, z) dentro de las paredes del nivel: los enemigos solo salen dentro. Vacía: en
## cualquier sitio con suelo.
@export var play_area: Rect2 = Rect2()
## En un mapa redondo, el radio donde pueden salir (0: sin círculo).
@export_range(0.0, 1000.0, 0.5, "suffix:m") var play_radius: float = 0.0
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
@export var mini_bosses: MiniBossEncounter
@export var herald: HeraldSpawner
@export var pickups: PickupField
@export var loot: LootDropper


func _enter_tree() -> void:
	# Antes de que entren sus hijos: el jugador y el director arrancan ya con lo de este nivel.
	if default_character:
		player.character = default_character
	apply_map_settings()


func _ready() -> void:
	# Al cargar, no en plena partida: la primera carta o ficha con unidades daría un tirón.
	StatFormat.warm_up()
	UpgradableStats.warm_up()
	if spawn_point:
		player.teleport_to(spawn_point.global_position)
	if not intro_keys.is_empty():
		EventBus.level_intro.emit(intro_keys)


## Pasa al director y al jefe lo del mapa: oleadas, si empiezan solas, zona de juego y jefe.
func apply_map_settings() -> void:
	if waves:
		director.data = waves
	director.autostart = autostart_waves
	director.play_area = play_area
	director.play_radius = play_radius
	encounter.data = boss
