class_name BreakableData
extends Resource
## Lo que suelta un rompible (calavera, bolsita…) al romperse: qué recogible, cuánto en total (más
## cuanto mayor es la dificultad: más riesgo, más recompensa) y en cuántos trozos, repartidos
## alrededor. Añadir un rompible es crear su [code].tres[/code] en [code]data/breakables/[/code] y su
## escena (raíz [Breakable]) con su aspecto.

## Recogible que suelta (la gema de experiencia, la moneda de oro…).
@export var reward: PickupData
## Valor total con dificultad 0.
@export_range(0.0, 1000.0, 0.5, "or_greater") var amount: float = 0.0
## Valor que se suma por cada punto de dificultad (la stat [code]difficulty[/code]).
@export_range(0.0, 1000.0, 0.1, "or_greater") var amount_per_difficulty: float = 0.0
## En cuántos recogibles se reparte.
@export_range(1, 20, 1) var pieces: int = 0
## Recogibles que a veces suelta además (imán, comida, bomba…).
@export var bonus_drops: Array[BonusDrop] = []
## Hasta qué distancia del rompible caen.
@export_range(0.0, 5.0, 0.1, "suffix:m") var spread: float = 0.0


## Valor total con dificultad [param difficulty].
func amount_at(difficulty: float) -> float:
	return amount + amount_per_difficulty * maxf(difficulty, 0.0)
