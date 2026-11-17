class_name Summoner
extends Node3D
## Invocador de la zona de práctica: al interactuar saca un anillo de enemigos alrededor de quien
## lo usa, para probar armas contra enemigos de verdad. Solo para probar: en una partida los saca
## el director de oleadas.

@export var interactable: Interactable
## Cartel encima: muestra el nombre del enemigo que invoca.
@export var label: Label3D
## Dónde salen los enemigos (lo asigna el nivel).
@export var swarm: EnemySwarm
## Tipo de enemigo que invoca.
@export var enemy: EnemyData
## Enemigos por invocación.
@export_range(1, 200, 1) var count: int = 12
## Distancia del anillo a quien invoca.
@export_range(1.0, 50.0, 0.5, "suffix:m") var ring_radius: float = 10.0


func _ready() -> void:
	interactable.interacted.connect(_on_interacted)
	if label and enemy:
		# Es una clave: el Label3D la traduce solo.
		label.text = enemy.name_key


## Saca el anillo de enemigos alrededor de [param center].
func summon(center: Vector3) -> void:
	if swarm == null or enemy == null:
		push_error("Summoner: falta 'swarm' o 'enemy'.")
		return
	for index: int in count:
		var angle := TAU * index / count
		var offset := Vector3(cos(angle), 0.0, sin(angle)) * ring_radius
		swarm.spawn(enemy, center + offset)


func _on_interacted(by: Node3D) -> void:
	summon(by.global_position)
