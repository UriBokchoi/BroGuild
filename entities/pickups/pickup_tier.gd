class_name PickupTier
extends Resource
## Un nivel de un recogible según lo que vale (gema azul, verde, roja…): desde qué valor se usa, de
## qué color se ve y a qué tamaño. Vive dentro de su [PickupData]; aquí todo vale 0 a propósito.

## Valor desde el que el recogible se ve así.
@export_range(0.0, 100000.0, 0.5, "or_greater") var min_amount: float = 0.0
## Color (el [code]color[/code] de instancia de su shader).
@export var color: Color = Color.BLACK
## Tamaño respecto al de su escena.
@export_range(0.1, 5.0, 0.05) var scale: float = 0.0
