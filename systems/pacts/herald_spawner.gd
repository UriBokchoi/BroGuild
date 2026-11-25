class_name HeraldSpawner
extends Node
## Trae al heraldo del Gremio cada tantos enemigos derrotados: lo pone en el suelo cerca del jugador,
## en un hueco libre, mirándolo, y lo avisa (en el HUD y con [signal EventBus.herald_arrived], que
## enseña la flecha). Solo hay uno: si el anterior sigue esperando, se va.

## Cada cuántos enemigos llega, dónde y qué ofrece.
@export var data: HeraldData
@export var herald_scene: PackedScene
## El jugador (cerca de quien aparece).
@export var player: Node3D
## Dónde va el heraldo (en el mundo).
@export var parent: Node3D
## Qué cuenta como suelo (y como estorbo).
@export_flags_3d_physics var ground_mask: int = 1
## Cuánto más alto o más bajo que el jugador se busca el suelo. Lo que sobresale más (un árbol, una
## roca grande) no cuenta como suelo: se mira desde dentro y estorba.
@export_range(0.5, 50.0, 0.5, "suffix:m") var ground_probe: float = 3.0
## Hueco libre que necesita: radio de la esfera que se mira encima del suelo.
@export_range(0.1, 5.0, 0.1, "suffix:m") var clearance: float = 0.8
## Sitios que prueba antes de quedarse con el último suelo que encontró.
@export_range(1, 64, 1) var attempts: int = 12

## Azar del sitio (y de lo que ofrece el heraldo). Si no se asigna antes de entrar en el árbol, el
## flujo de apuestas de Rng.
var rng: RandomNumberGenerator

var _kills: int = 0
var _herald: Herald


func _ready() -> void:
	if rng == null:
		rng = Rng.stream(Rng.Stream.GAMBLE)
	EventBus.enemy_died.connect(_on_enemy_died)


## El heraldo que espera ahora, o null.
func get_herald() -> Herald:
	return _herald if is_instance_valid(_herald) and not _herald.is_queued_for_deletion() else null


## Si hay un heraldo esperando, se va (al cambiar de mapa).
func dismiss() -> void:
	if get_herald():
		_herald.free()
	_herald = null


## Trae al heraldo ya (si había otro esperando, se va). Lo llama la cuenta de enemigos.
func summon() -> Herald:
	if get_herald():
		_herald.free()
	_herald = herald_scene.instantiate() as Herald
	_herald.data = data
	_herald.rng = rng
	parent.add_child(_herald)
	_herald.global_position = _find_spot()
	var facing := Vector3(player.global_position.x, _herald.global_position.y, player.global_position.z)
	if _herald.global_position.distance_to(facing) > 0.01:
		_herald.look_at(facing, Vector3.UP)
	EventBus.announced.emit(data.announce_key, [], data.announce_color)
	EventBus.herald_arrived.emit(_herald.global_position)
	return _herald


func _on_enemy_died(_enemy: Enemy) -> void:
	_kills += 1
	if _kills % data.every_kills == 0:
		summon()


## Un sitio con suelo y sin estorbos a la distancia de los datos. Si no encuentra ninguno libre, el
## último suelo que encontró; si ni eso, al lado del jugador.
func _find_spot() -> Vector3:
	var space := player.get_world_3d().direct_space_state
	var fallback := player.global_position
	for _attempt: int in attempts:
		var angle := rng.randf_range(0.0, TAU)
		var distance := rng.randf_range(data.min_distance, data.max_distance)
		var at := player.global_position + Vector3(cos(angle), 0.0, sin(angle)) * distance
		var ground := _ground_below(space, at)
		if ground.is_empty():
			continue
		var spot: Vector3 = ground.position
		fallback = spot
		if (ground.normal as Vector3).y > 0.7 and _is_clear(space, spot):
			return spot
	return fallback


func _ground_below(space: PhysicsDirectSpaceState3D, at: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(
		at + Vector3.UP * ground_probe, at + Vector3.DOWN * ground_probe, ground_mask
	)
	return space.intersect_ray(query)


func _is_clear(space: PhysicsDirectSpaceState3D, spot: Vector3) -> bool:
	var sphere := SphereShape3D.new()
	sphere.radius = clearance
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = sphere
	query.collision_mask = ground_mask
	query.transform = Transform3D(Basis.IDENTITY, spot + Vector3.UP * (clearance + 0.3))
	return space.intersect_shape(query, 1).is_empty()
