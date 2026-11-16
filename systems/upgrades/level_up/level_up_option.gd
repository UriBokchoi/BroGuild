class_name LevelUpOption
extends RefCounted
## Una opción al subir de nivel: un objeto y el nivel que tendrá si se elige (1 = nuevo).

var item: ItemData
var level: int = 1


static func create(offered: ItemData, new_level: int) -> LevelUpOption:
	var option := LevelUpOption.new()
	option.item = offered
	option.level = new_level
	return option


## ¿Es un objeto que aún no lleva?
func is_new() -> bool:
	return level == 1


## Lo que mejora este nivel.
func modifiers() -> Array[StatModifier]:
	return item.level_modifiers(level)
