class_name PickupField
extends Node3D
## Recogibles en el suelo (gemas de experiencia, oro…). Los saca de un pool por tipo ([method drop])
## y los deja en el suelo. Cuando [member collector] (el jugador) está a menos de su radio de
## recogida (su stat [code]pickup_range[/code]), o nada más salir si son de recogida automática
## ([member PickupData.auto_collect]), vuelan hacia él acelerando y, al llegar, se recogen: avisa por
## [code]EventBus.pickup_collected[/code] y vuelven al pool. Todos se mueven en un único bucle; no
## usan física.

## Quien recoge (el jugador).
@export var collector: Node3D
## Stats de quien recoge (su radio de recogida).
@export var collector_stats: StatsComponent
## Capas de física que cuentan como suelo al soltar un recogible.
@export_flags_3d_physics var ground_mask: int = 1
## Distancia hacia abajo en la que se busca suelo al soltar.
@export_range(1.0, 200.0, 1.0, "suffix:m") var probe_depth: float = 50.0

var _pools: Dictionary[StringName, NodePool] = {}
var _active: Array[Pickup] = []


func _physics_process(delta: float) -> void:
	if collector == null or _active.is_empty():
		return
	var pickup_range := collector_stats.get_value(&"pickup_range") if collector_stats else 0.0
	var feet := collector.global_position
	for index: int in range(_active.size() - 1, -1, -1):
		var pickup := _active[index]
		var goal := feet + Vector3.UP * pickup.data.target_height
		var offset := goal - pickup.global_position
		var distance := offset.length()
		if not pickup.attracted:
			if distance > pickup_range:
				continue
			pickup.attracted = true
			pickup.speed = pickup.data.start_speed
		pickup.speed += pickup.data.acceleration * delta
		var step := minf(pickup.speed * delta, distance)
		if distance - step <= pickup.data.collect_radius:
			_collect(index)
			continue
		pickup.global_position += offset / distance * step


## Suelta un recogible de [param pickup_data] que vale [param amount] en el suelo bajo [param at]
## (o en [param at], si debajo no hay suelo) y lo devuelve.
func drop(pickup_data: PickupData, at: Vector3, amount: float) -> Pickup:
	var pickup := _pool_for(pickup_data).acquire() as Pickup
	pickup.activate(_ground_below(at), amount)
	if pickup_data.auto_collect:
		pickup.attracted = true
		pickup.speed = pickup_data.start_speed
	_active.append(pickup)
	return pickup


## Recogibles en el suelo o volando.
func active_count() -> int:
	return _active.size()


func get_active() -> Array[Pickup]:
	return _active.duplicate()


## Retira todos los recogibles sin darlos.
func clear() -> void:
	for index: int in range(_active.size() - 1, -1, -1):
		_release(index)


func _collect(index: int) -> void:
	var pickup := _active[index]
	EventBus.pickup_collected.emit(pickup.data.reward, pickup.amount)
	_release(index)


func _release(index: int) -> void:
	var pickup := _active[index]
	_active.remove_at(index)
	pickup.deactivate()
	_pools[pickup.data.id].release(pickup)


func _ground_below(at: Vector3) -> Vector3:
	var from := at + Vector3.UP * 0.5
	var query := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * probe_depth, ground_mask)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return at
	var ground: Vector3 = hit["position"]
	return ground


func _pool_for(pickup_data: PickupData) -> NodePool:
	if not _pools.has(pickup_data.id):
		_pools[pickup_data.id] = NodePool.new(_create.bind(pickup_data), self)
	return _pools[pickup_data.id]


func _create(pickup_data: PickupData) -> Node:
	var pickup := pickup_data.scene.instantiate() as Pickup
	pickup.data = pickup_data
	return pickup
