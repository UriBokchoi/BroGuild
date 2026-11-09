class_name StatModifierSet
extends Resource
## Modificadores que se aplican y se quitan juntos: un personaje, una mejora, una maldición…
## Quien los aplica usa el propio conjunto como origen, así que quitarlo es
## [code]remove_modifiers_from(conjunto)[/code].

@export var stat_modifiers: Array[StatModifier] = []
