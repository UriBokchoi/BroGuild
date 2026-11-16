class_name LethalPassive
extends CharacterPassive
## Letal (Pícaro): su probabilidad de crítico crece con el nivel, [member crit_per_level] por cada
## nivel que suba.

## Probabilidad de crítico que gana por nivel.
@export_range(0.0, 10.0, 0.1, "suffix:%") var crit_per_level: float = 0.0


func _activated() -> void:
	player.experience.leveled_up.connect(_apply)
	_apply(player.experience.get_level())


func _apply(level: int) -> void:
	_set_bonus(&"crit_chance", StatModifier.Kind.FLAT, crit_per_level * (level - 1))
