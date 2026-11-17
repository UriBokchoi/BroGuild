class_name PassiveItemData
extends StatModifierSet
## Objeto pasivo de la partida (GDD §6): sale de los cofres (más adelante, también del jefe), tiene
## una rareza fija, no ocupa ranura y se apila: cada copia vuelve a sumar sus
## [member StatModifierSet.stat_modifiers]. Viven en [code]data/items/[/code]: un objeto nuevo es un
## [code].tres[/code] más, sin código.

## Identificador estable.
@export var id: StringName = &""
## Clave de traducción del nombre (p. ej. [code]ITEM_PROTEIN_SHAKE_NAME[/code]).
@export var name_key: StringName = &""
## Clave de traducción de lo que hace.
@export var description_key: StringName = &""
@export var icon: Texture2D
## Rareza: decide cuánto sale de los cofres y el color con que se ve.
@export var rarity: Rarity
