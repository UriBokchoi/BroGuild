class_name EnemySteering
## Steering simple de los enemigos, en el plano XZ (CLAUDE.md, «Rendimiento»: sin navegación por
## enemigo): ir hacia el objetivo y separarse de los vecinos para no amontonarse. Funciones puras.

## Distancia a la que ya no hace falta acercarse más.
const ARRIVED: float = 0.3


## Velocidad de [param speed] hacia [param to] en el plano XZ (cero si ya está encima).
static func seek(from: Vector3, to: Vector3, speed: float) -> Vector3:
	var offset := Vector3(to.x - from.x, 0.0, to.z - from.z)
	if offset.length() < ARRIVED:
		return Vector3.ZERO
	return offset.normalized() * speed


## Empuje (0–n) para alejarse de [param neighbors] que estén a menos de [param radius]: más fuerte
## cuanto más cerca. Si un vecino está justo encima, empuja hacia [param fallback].
static func separation(
	position: Vector3,
	neighbors: PackedVector3Array,
	radius: float,
	fallback: Vector3,
) -> Vector3:
	var push := Vector3.ZERO
	for neighbor: Vector3 in neighbors:
		var away := Vector3(position.x - neighbor.x, 0.0, position.z - neighbor.z)
		var distance := away.length()
		if distance >= radius:
			continue
		var direction := away / distance if distance > 0.001 else fallback
		push += direction * (1.0 - distance / radius)
	return push
