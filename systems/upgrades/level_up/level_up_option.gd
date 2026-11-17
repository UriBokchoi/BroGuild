class_name LevelUpOption
extends RefCounted
## Una opción al subir de nivel: un objeto y el nivel que tendrá si se elige (1 = nuevo). Si ya lo
## lleva, la mejora tirada que le daría ([member upgrade], con su rareza).

var item: ItemData
var level: int = 1
## Mejora que se aplica al elegirla (vacía si es nuevo).
var upgrade: ItemUpgrade


## Un objeto nuevo (nivel 1).
static func create(offered: ItemData, new_level: int) -> LevelUpOption:
	var option := LevelUpOption.new()
	option.item = offered
	option.level = new_level
	return option


## Subir de nivel [param offered] hasta [param new_level] con [param rolled].
static func create_upgrade(offered: ItemData, new_level: int, rolled: ItemUpgrade) -> LevelUpOption:
	var option := create(offered, new_level)
	option.upgrade = rolled
	return option


## ¿Es un objeto que aún no lleva?
func is_new() -> bool:
	return level == 1


## Rareza de la mejora (o [code]null[/code] si es nuevo).
func rarity() -> Rarity:
	return upgrade.rarity if upgrade else null


## Lo que mejora: la mejora tirada o, si es nuevo, lo que da al conseguirlo (las runas, su mejora
## estándar; las armas, nada más que el arma).
func modifiers() -> Array[StatModifier]:
	if upgrade:
		return upgrade.stat_modifiers
	if item is RuneData:
		return item.default_upgrade().stat_modifiers
	return []
