class_name StreakData
extends Resource
## Cómo sube la racha (el power-up): cuántos enemigos hay que derrotar para cada nivel, qué
## multiplicador da cada uno al oro y a la experiencia y cuánta Suerte suma. Los valores viven en
## data/progression/streak.tres; aquí todo vale 0 o vacío a propósito.

## Enemigos derrotados desde que empezó para llegar a cada nivel (el primero, 0: ×1 al empezar).
@export var kills: PackedInt32Array = PackedInt32Array()
## Multiplicador de oro y experiencia de cada nivel, en el mismo orden.
@export var multipliers: PackedFloat32Array = PackedFloat32Array()
## Suerte que suma por cada punto de multiplicador por encima de 1 (con ×3, el doble que con ×2).
@export_range(0.0, 100.0, 0.5) var luck_per_multiplier: float = 0.0


## El nivel al que llega con [param kill_count] enemigos derrotados.
func level_for(kill_count: int) -> int:
	var level := 0
	for index: int in kills.size():
		if kill_count >= kills[index]:
			level = index
	return level
