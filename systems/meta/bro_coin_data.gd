class_name BroCoinData
extends Resource
## Cuántas bro-monedas (la moneda de fuera de la partida, para la tienda de mejoras) da cada cosa.
## Los valores viven en data/meta/bro_coins.tres; aquí todo vale 0 a propósito.

## Por cada élite derrotado.
@export_range(0, 100, 1) var per_elite: int = 0
## Por cada miniboss vencido.
@export_range(0, 1000, 1) var per_mini_boss: int = 0
## Por cada jefe vencido.
@export_range(0, 1000, 1) var per_boss: int = 0
