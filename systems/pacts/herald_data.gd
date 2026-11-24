class_name HeraldData
extends Resource
## El heraldo del Gremio: cada cuántos enemigos llega, a qué distancia del jugador aparece, qué
## pactos ofrece y cuánto cuesta pedir otros. Los valores viven en data/pacts/herald.tres; aquí todo
## vale 0 o vacío a propósito.

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
## Oro que cuesta el primer «volver a tirar» de la partida, y cuánto se multiplica con cada uso.
@export_range(0, 1000, 1, "or_greater") var reroll_cost: int = 0
@export_range(1.0, 5.0, 0.05) var reroll_growth: float = 1.0


## Hasta [member choices] pactos distintos de [member pacts], al azar. Los de [param avoid] (los que
## ya se enseñaban) solo salen si no quedan otros.
func roll(rng: RandomNumberGenerator, avoid: Array[PactData] = []) -> Array[PactData]:
	var fresh: Array[PactData] = pacts.filter(func(pact: PactData) -> bool: return not avoid.has(pact))
	var seen: Array[PactData] = pacts.filter(func(pact: PactData) -> bool: return avoid.has(pact))
	var chosen: Array[PactData] = []
	for left: Array[PactData] in [fresh, seen]:
		while chosen.size() < choices and not left.is_empty():
			chosen.append(left.pop_at(rng.randi_range(0, left.size() - 1)))
	return chosen


## Coste del «volver a tirar» tras [param uses] usos en la partida.
func reroll_cost_at(uses: int) -> int:
	return roundi(reroll_cost * pow(reroll_growth, uses))
