class_name BonusDrop
extends Resource
## Un recogible que a veces sale además del botín normal (un imán, comida, una bomba…): de un
## rompible ([member BreakableData.bonus_drops]) o de un élite ([member EliteData.bonus_drops]).
## Cada uno se tira por separado.

## Recogible que sale.
@export var pickup: PickupData
## Probabilidad de que salga.
@export_range(0.0, 100.0, 0.1, "suffix:%") var chance: float = 0.0
## Lo que vale (lo que hace con ello depende de su efecto: la comida cura esa parte de la vida…).
@export_range(0.0, 1000.0, 0.01, "or_greater") var amount: float = 0.0
