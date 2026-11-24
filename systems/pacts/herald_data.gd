class_name HeraldData
extends Resource
## El heraldo del Gremio: cada cuántos enemigos llega, a qué distancia del jugador aparece y qué
## pactos ofrece. Los valores viven en data/pacts/herald.tres; aquí todo vale 0 o vacío a propósito.

## Enemigos derrotados entre un heraldo y el siguiente.
@export_range(1, 100000, 1, "or_greater") var every_kills: int = 0
## Distancia al jugador a la que aparece (entre una y otra).
@export_range(0.0, 100.0, 0.5, "suffix:m") var min_distance: float = 0.0
@export_range(0.0, 100.0, 0.5, "suffix:m") var max_distance: float = 0.0
## Cuántos pactos ofrece.
@export_range(1, 6, 1) var choices: int = 0
## Los pactos que puede ofrecer.
@export var pacts: Array[PactData] = []
## Aviso en el HUD al llegar.
@export var announce_key: StringName = &""
@export var announce_color: Color = Color.WHITE


## Hasta [member choices] pactos distintos de [member pacts], al azar.
func roll(rng: RandomNumberGenerator) -> Array[PactData]:
	var left := pacts.duplicate()
	var chosen: Array[PactData] = []
	while chosen.size() < choices and not left.is_empty():
		chosen.append(left.pop_at(rng.randi_range(0, left.size() - 1)))
	return chosen
