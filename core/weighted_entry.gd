class_name WeightedEntry
extends Resource
## Una entrada de una [WeightedTable]: su peso frente a las demás (el doble de peso, el doble de
## veces). Lo que sale (un recogible, un cofre, un símbolo de tragaperras…) va en la subclase.

## Peso frente a las demás entradas de la tabla. 0 = nunca.
@export_range(0.0, 1000.0, 0.1, "or_greater") var weight: float = 0.0
