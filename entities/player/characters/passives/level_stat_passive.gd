class_name LevelStatPassive
extends CharacterPassive
## Pasiva que crece con el nivel: el personaje gana [member per_level] de [member stat] por cada
## nivel que sube (con el nivel 1, nada). Así son las de los iniciales: Veterano (Guerrero, daño),
## Expansión arcana (Mago, área) y Letal (Pícaro, crítico).

## Stat que sube.
@export var stat: StringName = &""
## Cómo sube (plano o %).
@export var kind: StatModifier.Kind = StatModifier.Kind.FLAT
## Lo que gana por cada nivel (con %, 0,01 = +1 %).
@export var per_level: float = 0.0


func _activated() -> void:
	player.experience.leveled_up.connect(_apply)
	_apply(player.experience.get_level())


## Lo que gana con [param level].
func bonus_at(level: int) -> float:
	return per_level * (level - 1)


func _apply(level: int) -> void:
	_set_bonus(stat, kind, bonus_at(level))
