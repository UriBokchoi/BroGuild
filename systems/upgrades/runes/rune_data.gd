class_name RuneData
extends ItemData
## Una runa (GDD §6): mejora pasiva que sube stats del jugador. Al conseguirla da su mejora estándar
## (todas sus [member ItemData.upgrade_stats] con la fuerza de una común) y cada subida de nivel
## suma una mejora tirada con rareza. Añadir una runa es crear su [code].tres[/code] en
## [code]data/runes/[/code].


func kind_key() -> StringName:
	return &"ITEM_KIND_RUNE"
