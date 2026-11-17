class_name BreakableData
extends Resource
## Lo que suelta un rompible (calavera, bolsita…) al romperse: qué recogible, cuánto en total y en
## cuántos trozos, repartidos alrededor. Añadir un rompible es crear su [code].tres[/code] en
## [code]data/breakables/[/code] y su escena (raíz [Breakable]) con su aspecto.

## Recogible que suelta (la gema de experiencia, la moneda de oro…).
@export var reward: PickupData
## Valor total.
@export_range(0.0, 1000.0, 0.5, "or_greater") var amount: float = 0.0
## En cuántos recogibles se reparte.
@export_range(1, 20, 1) var pieces: int = 0
## Hasta qué distancia del rompible caen.
@export_range(0.0, 5.0, 0.1, "suffix:m") var spread: float = 0.0
