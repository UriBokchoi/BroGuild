class_name WeaponData
extends ItemData
## Un arma: escena con su comportamiento, stats de nivel 1 y mejoras de cada nivel (su nombre e id
## vienen de [ItemData]). Añadir un arma es crear su [code].tres[/code] en [code]data/weapons/[/code]
## (y su escena si ataca de una forma nueva).

## Escena del arma: su raíz es un [Weapon].
@export var scene: PackedScene
## Stats a nivel 1.
@export var stats: WeaponStats
## Mejoras de cada nivel a partir del 2: la primera es la del nivel 2, y así. El nivel máximo es
## una más que las que haya.
@export var levels: Array[StatModifierSet] = []


## Nivel máximo del arma.
func max_level() -> int:
	return levels.size() + 1
