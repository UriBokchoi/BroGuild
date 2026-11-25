class_name CharacterData
extends StatModifierSet
## Un personaje. Todos parten de las mismas stats (data/player/) y sus modificadores dicen en qué se
## diferencia; cuentan como su base, no como una mejora. También lleva su arma inicial, su pasiva y
## su aspecto.
##
## Para añadir uno: un .tres en data/characters/ con sus textos traducidos (y, si su pasiva es nueva,
## su escena en entities/player/characters/passives/).

## Identificador estable (récords, Archivo).
@export var id: StringName = &""
## Clave de traducción del nombre (p. ej. [code]CHARACTER_WARRIOR_NAME[/code]).
@export var name_key: StringName = &""
## Clave de traducción de la descripción de su gimmick.
@export var description_key: StringName = &""
## Color con el que se le reconoce: el de su modelo, sus pedestales y la selección de personaje.
@export var color: Color = Color.WHITE
## Icono (Archivo).
@export var icon: Texture2D
## Arma con la que empieza.
@export var starting_weapon: WeaponData

@export_group("passive")
## Habilidad pasiva: escena cuya raíz es un [CharacterPassive] (sus números van en ella).
@export var passive: PackedScene
## Clave de traducción del nombre de la pasiva.
@export var passive_name_key: StringName = &""
## Clave de traducción de lo que hace la pasiva.
@export var passive_description_key: StringName = &""

@export_group("model")
## Piezas que lleva encima su modelo ([CharacterModel]): espada y escudo, bastón y sombrero…
@export var attachments: Array[ModelAttachment] = []
## Si da un mortal hacia delante en el doble salto (el Pícaro).
@export var air_jump_flip: bool = false
