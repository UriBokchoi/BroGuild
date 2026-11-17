class_name BonusDrop
extends WeightedEntry
## Un recogible especial que puede salir de una tabla de botín (un imán, comida, una bomba, una
## bebida energética…). Si sale de la tabla lo decide la probabilidad de botín (la stat
## [code]drop_chance[/code] del jugador por el multiplicador de quien lo suelta); cuál, los pesos.

## Recogible que sale.
@export var pickup: PickupData
## Lo que vale (lo que hace con ello depende de su efecto: la comida cura esa parte de la vida, la
## bebida dura esos segundos…).
@export_range(0.0, 1000.0, 0.01, "or_greater") var amount: float = 0.0
