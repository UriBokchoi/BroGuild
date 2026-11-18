class_name WeightedEntry
extends Resource
## Una entrada de una [WeightedTable]: su peso frente a las demás (el doble de peso, el doble de
## veces). Lo que sale (un recogible, un cofre, un símbolo de tragaperras…) va en la subclase.

## Peso frente a las demás entradas de la tabla. 0 = nunca.
@export_range(0.0, 1000.0, 0.1, "or_greater") var weight: float = 0.0
## Cuánto gana con la Suerte: % de su peso que suma por cada punto. 0 = no le afecta. Las entradas
## buenas (rarezas altas) lo llevan más alto, así que con Suerte salen más.
@export_range(0.0, 100.0, 0.1, "or_greater", "suffix:%") var luck_scaling: float = 0.0


## Peso con [param luck] puntos de Suerte (nunca negativo).
func weight_with_luck(luck: float) -> float:
	return maxf(weight * (1.0 + luck * luck_scaling / 100.0), 0.0)
