class_name WeaponData
extends ItemData
## Un arma: escena con su comportamiento y stats de nivel 1 (su nombre, id, nivel máximo y las stats
## que pueden mejorar sus subidas de nivel vienen de [ItemData]). Añadir un arma es crear su
## [code].tres[/code] en [code]data/weapons/[/code] (y su escena si ataca de una forma nueva).

## Escena del arma: su raíz es un [Weapon].
@export var scene: PackedScene
## Stats a nivel 1.
@export var stats: WeaponStats


func kind_key() -> StringName:
	return &"ITEM_KIND_WEAPON"


func level_bonus_stat() -> StringName:
	return &"weapon_level_bonus"
