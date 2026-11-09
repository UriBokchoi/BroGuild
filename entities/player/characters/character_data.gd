class_name CharacterData
extends StatModifierSet
## Un personaje: todos parten de las stats básicas ([code]data/player/[/code]) y sus
## [member StatModifierSet.stat_modifiers] dicen en qué se diferencia según su gimmick (+1 salto
## en el aire, +20 % de velocidad…). Esas diferencias cambian la base de las stats: el menú las
## muestra como base, no como mejora. Añadir un personaje es crear un [code].tres[/code] en
## [code]data/characters/[/code] con su nombre y descripción traducidos.

## Clave de traducción del nombre (p. ej. [code]CHARACTER_BASE_NAME[/code]).
@export var name_key: StringName = &""
## Clave de traducción de la descripción de su gimmick.
@export var description_key: StringName = &""
