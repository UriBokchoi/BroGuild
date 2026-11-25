class_name MapBoundary
extends Node3D
## El borde del mapa, que solo se ve al acercarse: paredes de malla (boundary_wall.gdshader) que
## brillan en un círculo alrededor de target y se desvanecen con la distancia; lejos de todos los
## bordes no se dibujan. Cuatro, en cuadrado (half_extent), o en círculo si tiene radius (la arena
## final). Solo se ve: lo que choca son las paredes del nivel, que deben coincidir con él.

## A quién sigue el brillo (el jugador).
@export var target: Node3D
## Medio lado del cuadrado de juego: las paredes van en x = ±x y z = ±y.
@export var half_extent: Vector2 = Vector2(80.0, 80.0)
## Radio de un borde redondo (0: cuadrado, con [member half_extent]) y en cuántos tramos se hace.
@export_range(0.0, 500.0, 0.5, "suffix:m") var radius: float = 0.0
@export_range(8, 256, 1) var segments: int = 48
## Alto de las paredes.
@export_range(1.0, 40.0, 0.5, "suffix:m") var height: float = 8.0
## Material de las cuatro paredes (con [code]boundary_wall.gdshader[/code]). Lo cambia cada
## fotograma: no lo compartas con otra cosa.
@export var material: ShaderMaterial
## Altura del centro del brillo sobre los pies de [member target].
@export_range(0.0, 3.0, 0.1, "suffix:m") var reveal_height: float = 1.0
## A qué distancia de [member target] la pared se ve del todo y a cuál deja de verse.
@export_range(0.0, 50.0, 0.5, "suffix:m") var reveal_near: float = 3.0
@export_range(0.5, 50.0, 0.5, "suffix:m") var reveal_far: float = 11.0
## Cuánto se meten las paredes hacia dentro, para no quedar justo en la cara de las de choque.
@export_range(0.0, 1.0, 0.01, "suffix:m") var inset: float = 0.05

var _walls: Array[MeshInstance3D] = []


func _ready() -> void:
	material.set_shader_parameter(&"wall_height", height)
	material.set_shader_parameter(&"reveal_near", reveal_near)
	material.set_shader_parameter(&"reveal_far", reveal_far)
	if radius > 0.0:
		_add_ring()
		_set_walls_visible(false)
		return
	var inner := half_extent - Vector2.ONE * inset
	_add_wall(Vector3(0.0, 0.0, -inner.y), 0.0, half_extent.x * 2.0)
	_add_wall(Vector3(0.0, 0.0, inner.y), 0.0, half_extent.x * 2.0)
	_add_wall(Vector3(-inner.x, 0.0, 0.0), PI / 2.0, half_extent.y * 2.0)
	_add_wall(Vector3(inner.x, 0.0, 0.0), PI / 2.0, half_extent.y * 2.0)
	_set_walls_visible(false)


func _process(_delta: float) -> void:
	if not is_instance_valid(target):
		_set_walls_visible(false)
		return
	var at := to_local(target.global_position)
	var to_edge := minf(half_extent.x - absf(at.x), half_extent.y - absf(at.z))
	if radius > 0.0:
		to_edge = radius - Vector2(at.x, at.z).length()
	_set_walls_visible(to_edge < reveal_far)
	if _walls[0].visible:
		material.set_shader_parameter(&"reveal_center", target.global_position + Vector3.UP * reveal_height)


## Las paredes, en orden: norte, sur, oeste y este (en círculo, los tramos alrededor).
func get_walls() -> Array[MeshInstance3D]:
	return _walls.duplicate()


func _add_wall(at: Vector3, turn: float, width: float) -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(width, height)
	quad.material = material
	var wall := MeshInstance3D.new()
	wall.mesh = quad
	wall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	wall.position = at + Vector3.UP * height / 2.0
	wall.rotation.y = turn
	add_child(wall)
	_walls.append(wall)


## Tramos rectos alrededor del círculo, un poco solapados para que no se vean huecos.
func _add_ring() -> void:
	var inner := radius - inset
	var width := 2.0 * inner * tan(PI / segments) * 1.02
	for index: int in segments:
		var spot := Vector2.from_angle(TAU * index / segments) * inner
		var at := Vector3(spot.x, 0.0, spot.y)
		_add_wall(at, atan2(at.x, at.z), width)


func _set_walls_visible(shown: bool) -> void:
	for wall: MeshInstance3D in _walls:
		wall.visible = shown
