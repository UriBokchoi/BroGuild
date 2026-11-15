class_name EnemySteering
## Steering simple de los enemigos (CLAUDE.md, «Rendimiento»: sin navegación por enemigo): ir hacia
## el objetivo y separarse un poco de los vecinos para no ir en fila. Los choques los resuelve la
## física; esto solo reparte la horda. Funciones puras.

## Distancia a la que ya no hace falta acercarse más.
const ARRIVED: float = 0.3
## Cuánto tiene que estar delante un vecino (coseno del ángulo con la dirección) para trepar.
const CLIMB_AHEAD: float = 0.6
## Por debajo de esta parte de su velocidad máxima, un enemigo que quiere avanzar va atascado.
const STUCK_SPEED: float = 0.5


## Velocidad de [param speed] hacia [param to] en el plano XZ (cero si ya está encima).
static func seek(from: Vector3, to: Vector3, speed: float) -> Vector3:
	var offset := Vector3(to.x - from.x, 0.0, to.z - from.z)
	if offset.length() < ARRIVED:
		return Vector3.ZERO
	return offset.normalized() * speed


## Empuje en el plano XZ para alejarse de [param neighbors] que estén a menos de [param radius]
## (contando la altura): más fuerte cuanto más cerca. Así un enemigo apilado encima de otro no lo
## aparta y las pilas aguantan. Si un vecino está justo al lado a su altura, empuja hacia
## [param fallback].
static func separation(
	position: Vector3,
	neighbors: PackedVector3Array,
	radius: float,
	fallback: Vector3,
) -> Vector3:
	var push := Vector3.ZERO
	for neighbor: Vector3 in neighbors:
		var distance := position.distance_to(neighbor)
		if distance >= radius:
			continue
		var away := Vector3(position.x - neighbor.x, 0.0, position.z - neighbor.z)
		var flat := away.length()
		var direction := away / flat if flat > 0.001 else fallback
		push += direction * (1.0 - distance / radius)
	return push


## ¿Tiene delante (hacia [param direction], en XZ y normalizada) un vecino a menos de
## [param reach]? Es lo que hace trepar a la horda cuando se atasca. La distancia cuenta la altura:
## en cuanto está encima del otro, ya no lo tiene delante.
static func blocked_ahead(
	position: Vector3,
	direction: Vector3,
	neighbors: PackedVector3Array,
	reach: float,
) -> bool:
	for neighbor: Vector3 in neighbors:
		if position.distance_to(neighbor) >= reach:
			continue
		var toward := Vector3(neighbor.x - position.x, 0.0, neighbor.z - position.z)
		if toward.length() > 0.001 and toward.normalized().dot(direction) >= CLIMB_AHEAD:
			return true
	return false
