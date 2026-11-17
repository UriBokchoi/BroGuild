class_name RuneData
extends ItemData
## Una runa (GDD §6): mejora pasiva que sube stats del jugador con cada nivel. Cada nivel aplica su
## conjunto de modificadores sobre los de los niveles anteriores (se acumulan). Añadir una runa es
## crear su [code].tres[/code] en [code]data/runes/[/code].

## Modificadores de cada nivel: el primero es el del nivel 1, y así. El nivel máximo es cuántos
## haya. Un mismo conjunto puede repetirse si todos los niveles dan lo mismo.
@export var levels: Array[StatModifierSet] = []


## Nivel máximo de la runa.
func max_level() -> int:
	return levels.size()


func kind_key() -> StringName:
	return &"ITEM_KIND_RUNE"


func level_modifiers(level: int) -> Array[StatModifier]:
	if level < 1 or level > max_level():
		return []
	return levels[level - 1].stat_modifiers
