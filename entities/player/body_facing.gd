class_name BodyFacing
extends Node
## Gira el modelo del personaje hacia donde se mueve. Solo es visual: el cuerpo físico no gira.

## Cuerpo cuya velocidad marca la dirección.
@export var body: CharacterBody3D
## Nodo visual que gira (el modelo).
@export var visual: Node3D
## Stats de donde sale la velocidad de giro ([code]turn_speed[/code] de MovementData).
@export var stats: StatsComponent
## Por debajo de esta velocidad horizontal no gira: se queda mirando a donde estaba.
@export_range(0.0, 5.0, 0.05, "suffix:m/s") var min_speed: float = 0.5

var _move: MovementData


func _ready() -> void:
	_move = stats.get_resolved(MovementData) as MovementData


func _physics_process(delta: float) -> void:
	var horizontal := Vector2(body.velocity.x, body.velocity.z)
	if horizontal.length() < min_speed:
		return
	# El «delante» de un nodo es −Z: para mirar hacia (x, z), el giro es atan2(−x, −z).
	var target_yaw := atan2(-horizontal.x, -horizontal.y)
	visual.rotation.y = rotate_toward(visual.rotation.y, target_yaw, _move.turn_speed * delta)
