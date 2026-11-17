class_name PickupField
extends Node3D
## Recogibles en el suelo (gemas de experiencia, oro…). Los saca de un pool por tipo ([method drop])
## y los deja en el suelo. Cuando [member collector] (el jugador) está a menos de su radio de
## recogida (su stat [code]pickup_range[/code]), o nada más salir si son de recogida automática
## ([member PickupData.auto_collect]), vuelan hacia él acelerando y, al llegar, se recogen: avisa por
## [code]EventBus.pickup_collected[/code] y vuelven al pool. Todos se mueven en un único bucle; no
## usan física. Cada [member merge_interval] segundos junta los del mismo tipo que esperan juntos en
## el suelo ([member PickupData.merge_radius]): el de más valor se queda con la suma y los demás
## vuelven al pool.

## Quien recoge (el jugador).
@export var collector: Node3D
## Stats de quien recoge (su radio de recogida).
@export var collector_stats: StatsComponent
## Capas de física que cuentan como suelo al soltar un recogible.
@export_flags_3d_physics var ground_mask: int = 1
## Distancia hacia abajo en la que se busca suelo al soltar.
@export_range(1.0, 200.0, 1.0, "suffix:m") var probe_depth: float = 50.0
## Segundos entre las pasadas que juntan recogibles cercanos.
@export_range(0.05, 10.0, 0.05, "suffix:s") var merge_interval: float = 0.5

var _pools: Dictionary[StringName, NodePool] = {}
## Número de cada tipo, para separar los tipos al agrupar.
var _type_slots: Dictionary[StringName, int] = {}
var _active: Array[Pickup] = []
var _merge_left: float = 0.0
## Desplaza las zonas media zona en pasadas alternas: así un grupo partido por el borde de dos
## zonas se junta en la siguiente pasada.
var _shift_zones: bool = false


func _physics_process(delta: float) -> void:
	_merge_left -= delta
	if _merge_left <= 0.0:
		_merge_left = merge_interval
		merge_nearby()
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


## Hace volar hacia quien recoge todos los recogibles de recompensa [param reward] (el imán), estén
## donde estén.
func attract_all(reward: StringName) -> void:
	for pickup: Pickup in _active:
		if pickup.data.reward == reward and not pickup.attracted:
			pickup.attracted = true
			pickup.speed = pickup.data.start_speed


## Retira todos los recogibles sin darlos.
func clear() -> void:
	for index: int in range(_active.size() - 1, -1, -1):
		_release(index)


## Junta los recogibles del mismo tipo que esperan en el suelo en la misma zona de
## [member PickupData.merge_radius] de lado, si hay al menos [member PickupData.merge_count]: el de
## más valor se queda con la suma (y cambia de nivel) y los demás vuelven al pool. Las zonas se
## desplazan media zona en pasadas alternas. Lo hace solo cada [member merge_interval]; se puede
## llamar a mano.
func merge_nearby() -> void:
	var shift := 0.5 if _shift_zones else 0.0
	_shift_zones = not _shift_zones
	var zones: Dictionary[Vector3i, Array] = {}
	for pickup: Pickup in _active:
		var side := pickup.data.merge_radius
		if pickup.attracted or side <= 0.0:
			continue
		var at := pickup.global_position
		var cell := Vector2i(floori(at.x / side + shift), floori(at.z / side + shift))
		var key := Vector3i(cell.x, cell.y, _type_slots[pickup.data.id])
		if not zones.has(key):
			zones[key] = []
		zones[key].append(pickup)
	for group: Array in zones.values():
		var first := group[0] as Pickup
		if group.size() >= maxi(first.data.merge_count, 2):
			_merge(group)


func _merge(group: Array) -> void:
	var keeper := group[0] as Pickup
	var total := 0.0
	for pickup: Pickup in group:
		total += pickup.amount
		if pickup.amount > keeper.amount:
			keeper = pickup
	for pickup: Pickup in group:
		if pickup != keeper:
			_release(_active.find(pickup))
	keeper.set_amount(total)


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
		_type_slots[pickup_data.id] = _type_slots.size()
	return _pools[pickup_data.id]


func _create(pickup_data: PickupData) -> Node:
	var pickup := pickup_data.scene.instantiate() as Pickup
	pickup.data = pickup_data
	return pickup
