class_name EliteData
extends Resource
## Cómo es un élite: lo que mejora sobre el enemigo normal, cuánto más grande es y su brillo.
## Cualquier enemigo puede salir élite; la probabilidad la decide quien lo saca.

## Modificadores sobre sus stats y las de sus armas: cada uno va adonde exista su stat
## ([code]max_health[/code] a su vida, [code]damage[/code] a sus armas…).
@export var stat_modifiers: StatModifierSet
## Tamaño respecto al normal: cuerpo, zonas de golpe y modelo (y su masa, al cubo).
@export_range(0.25, 5.0, 0.05) var size: float = 1.0
## Material que se superpone a su modelo (el brillo de élite).
@export var overlay: Material
## Multiplica la probabilidad de botín del jugador ([code]drop_chance[/code]) para sus extras.
@export_range(0.0, 100.0, 0.1, "or_greater") var drop_chance_multiplier: float = 0.0
## De qué tabla salen sus extras (power-ups).
@export var drop_table: WeightedTable
## Probabilidad (%) de soltar un cofre al morir, aparte de sus extras.
@export_range(0.0, 100.0, 0.5, "suffix:%") var chest_chance: float = 0.0
## El cofre que suelta (uno normal: cuesta oro como los del mapa).
@export var chest: PackedScene
