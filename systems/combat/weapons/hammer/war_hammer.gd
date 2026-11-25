class_name WarHammer
extends Weapon
## Martillo de guerra (GDD §6): cae del cielo sobre el grupo de enemigos más denso a su alcance (el
## enemigo con más vecinos dentro del radio del golpe) y daña a todos los de dentro al tocar el suelo
## ([HammerStrike]). Los proyectiles extra son más martillos seguidos, cada uno sobre el siguiente
## grupo más denso. Sus stats son un [HammerStats].

## Escena del golpe (raíz [HammerStrike]).
@export var strike_scene: PackedScene
## Enemigos cercanos entre los que busca el grupo más denso.
@export_range(1, 128, 1) var candidates: int = 24
## Golpes que se crean de antemano.
@export_range(0, 16, 1) var prewarm_strikes: int = 2

var _strikes: NodePool
## Golpes en el aire o encogiendo.
var _active: Array[HammerStrike] = []


func _ready() -> void:
	super()
	_strikes = NodePool.new(_create_strike, self)
	_strikes.prewarm(prewarm_strikes)


## Radio del golpe: el de sus stats por el área.
func impact_radius() -> float:
	return (stats.get_resolved(HammerStats) as HammerStats).impact_radius * area_scale()


## Hasta [param count] de [param targets] (de más cerca a más lejos) ordenados por cuántos de los
## demás tienen a menos de [param radius] (en el suelo): primero los del grupo más denso. A igualdad,
## el más cercano. Cada elegido aparta a los que ya caen bajo su golpe, para no repetir grupo.
static func densest(targets: Array[Node3D], radius: float, count: int) -> Array[Node3D]:
	var left: Array[Node3D] = targets.duplicate()
	var chosen: Array[Node3D] = []
	while chosen.size() < count and not left.is_empty():
		var best := 0
		var best_score := -1
		for index: int in left.size():
			var score := _neighbors(left[index], left, radius)
			if score > best_score:
				best = index
				best_score = score
		var center := left[best]
		chosen.append(center)
		left = left.filter(func(other: Node3D) -> bool: return _flat_distance(center, other) > radius)
	return chosen


func _find_targets() -> Array[Node3D]:
	return densest(_candidates(candidates), impact_radius(), ceili(projectile_count()))


func _fire(target: Node3D, _index: int) -> void:
	var strike := _strikes.acquire() as HammerStrike
	_active.append(strike)
	strike.drop(self, target.global_position)


func _disarmed() -> void:
	for strike: HammerStrike in _active.duplicate():
		strike.recall()


func _create_strike() -> Node:
	var strike := strike_scene.instantiate() as HammerStrike
	strike.finished.connect(_on_strike_finished.bind(strike))
	return strike


func _on_strike_finished(strike: HammerStrike) -> void:
	_active.erase(strike)
	_strikes.release(strike)


static func _neighbors(center: Node3D, others: Array[Node3D], radius: float) -> int:
	var count := 0
	for other: Node3D in others:
		if other != center and _flat_distance(center, other) <= radius:
			count += 1
	return count


static func _flat_distance(a: Node3D, b: Node3D) -> float:
	return Vector2(a.global_position.x - b.global_position.x, a.global_position.z - b.global_position.z).length()
