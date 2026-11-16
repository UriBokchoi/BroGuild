class_name EliteData
extends Resource
## Cómo es un élite: lo que mejora sobre el enemigo normal (vida, daño al tocar y de sus armas,
## experiencia y oro que suelta…), cuánto más grande es y su brillo. Cualquier enemigo puede salir
## élite ([method Enemy.promote]); la probabilidad la decide quien lo saca
## ([member WaveData.elite_chance]). Los valores viven en [code]data/enemies/elite.tres[/code]; aquí
## todo es neutro a propósito.

## Modificadores sobre sus stats y las de sus armas: cada uno va adonde exista su stat
## ([code]max_health[/code] a su vida, [code]damage[/code] a sus armas…).
@export var stat_modifiers: StatModifierSet
## Tamaño respecto al normal: cuerpo, zonas de golpe y modelo (y su masa, al cubo).
@export_range(0.25, 5.0, 0.05) var size: float = 1.0
## Material que se superpone a su modelo (el brillo de élite).
@export var overlay: Material
