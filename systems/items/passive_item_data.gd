class_name PassiveItemData
extends StatModifierSet
## Un objeto pasivo (GDD §6): sale de cofres, círculos de setas y jefes, tiene una rareza fija, no
## ocupa ranura y se apila: cada copia suma otra vez sus stats y la probabilidad de sus efectos al
## golpear. Un objeto nuevo es un .tres más en data/items/, sin código.

## Identificador estable.
@export var id: StringName = &""
## Clave de traducción del nombre (p. ej. [code]ITEM_PROTEIN_SHAKE_NAME[/code]).
@export var name_key: StringName = &""
## Clave de traducción de su frase (con gracia y sin cifras: lo que hace lo dicen sus modificadores,
## que se muestran aparte).
@export var description_key: StringName = &""
@export var icon: Texture2D
## Rareza: decide cuánto sale de los cofres y el color con que se ve.
@export var rarity: Rarity
## Lo que puede pasar al golpear (veneno, rayo, frío…), además de sus stats.
@export var on_hit: Array[OnHitEffect] = []


## Una línea por efecto al golpear, para las fichas, con [param copies] copias.
func effect_lines(copies: int = 1) -> PackedStringArray:
	var lines := PackedStringArray()
	for effect: OnHitEffect in on_hit:
		lines.append(effect.describe(copies))
	return lines
