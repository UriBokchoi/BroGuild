class_name PortalArrow
extends Node3D
## Flecha que señala algo que acaba de aparecer (el portal del jefe, el heraldo del Gremio): durante
## [member show_time] segundos flota a un lado de [member target] (el jugador), en su dirección y
## apuntando a él, con un pequeño vaivén; al final se desvanece. Solo visual. Vive en el mundo
## ([code]top_level[/code]): no gira con el jugador.

## A quién acompaña (el jugador).
@export var target: Node3D
## Aviso del EventBus que la enciende: uno que lleva dónde señalar ([code]at: Vector3[/code]).
@export var event: StringName = &"boss_portal_opened"
## Color de la flecha.
@export var color: Color = Color(1.0, 0.85, 0.2, 1.0)
## Las mallas de la flecha (apunta hacia −Z), para desvanecerlas.
@export var meshes: Array[GeometryInstance3D] = []
## Segundos que se ve.
@export_range(0.5, 10.0, 0.1, "suffix:s") var show_time: float = 3.0
## Segundos del final en los que se desvanece.
@export_range(0.05, 2.0, 0.05, "suffix:s") var fade_time: float = 0.5
## Distancia al jugador (hacia el portal) y altura sobre sus pies.
@export_range(0.5, 10.0, 0.1, "suffix:m") var distance: float = 2.4
@export_range(0.0, 5.0, 0.05, "suffix:m") var height: float = 1.4
## Vaivén arriba y abajo: cuánto y cuántas veces por segundo.
@export_range(0.0, 1.0, 0.01, "suffix:m") var bob_height: float = 0.15
@export_range(0.1, 10.0, 0.1, "suffix:1/s") var bob_rate: float = 2.0

var _destination: Vector3 = Vector3.ZERO
var _left: float = 0.0


func _enter_tree() -> void:
	var opened := Signal(EventBus, event)
	if not opened.is_connected(point_at):
		opened.connect(point_at)


func _ready() -> void:
	for mesh: GeometryInstance3D in meshes:
		var material := (mesh as MeshInstance3D).mesh.surface_get_material(0).duplicate() as StandardMaterial3D
		material.albedo_color = color
		mesh.material_override = material
	top_level = true
	visible = false
	set_process(false)


func _process(delta: float) -> void:
	_left -= delta
	if _left <= 0.0 or not is_instance_valid(target):
		visible = false
		set_process(false)
		return
	var feet := target.global_position
	var toward := Vector3(_destination.x - feet.x, 0.0, _destination.z - feet.z)
	var direction := toward.normalized() if toward.length() > 0.01 else Vector3.FORWARD
	var bob := sin((show_time - _left) * bob_rate * TAU) * bob_height
	global_position = feet + direction * distance + Vector3.UP * (height + bob)
	look_at(global_position + direction, Vector3.UP)
	var fade := clampf(_left / fade_time, 0.0, 1.0)
	for mesh: GeometryInstance3D in meshes:
		mesh.transparency = 1.0 - fade


## Señala [param destination] durante [member show_time] segundos.
func point_at(destination: Vector3) -> void:
	_destination = destination
	_left = show_time
	visible = true
	set_process(true)


## ¿Se ve ahora?
func is_showing() -> bool:
	return visible and _left > 0.0
