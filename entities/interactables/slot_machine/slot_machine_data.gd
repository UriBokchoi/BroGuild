class_name SlotMachineData
extends Resource
## Cómo es una tragaperras (GDD §5.3): sus símbolos ([WeightedTable] de [SlotSymbol]), lo que cuesta
## (sube con la dificultad y cada vez que se usa esa máquina) y el ritmo de los rodillos. Los valores
## viven en [code]data/slots/[/code]; aquí todo vale 0 o vacío a propósito.

## Símbolos de los rodillos (cada rodillo saca uno según sus pesos).
@export var symbols: WeightedTable
## Rodillos.
@export_range(2, 5, 1) var reels: int = 0
@export_group("cost")
## Oro que cuesta la primera tirada con dificultad 0.
@export_range(0.0, 10000.0, 1.0, "or_greater") var base_cost: float = 0.0
## Oro que se suma por cada punto de dificultad.
@export_range(0.0, 1000.0, 0.5, "or_greater") var cost_per_difficulty: float = 0.0
## Multiplica el coste cada vez que se usa la misma máquina.
@export_range(1.0, 10.0, 0.05) var cost_growth: float = 1.0
@export_group("timing")
## Segundos que gira el primer rodillo.
@export_range(0.1, 10.0, 0.05, "suffix:s") var spin_time: float = 0.0
## Segundos entre que se para un rodillo y el siguiente.
@export_range(0.0, 5.0, 0.05, "suffix:s") var reel_delay: float = 0.0


## Oro que cuesta con dificultad [param difficulty] tras [param uses] tiradas en esa máquina.
func cost_at(difficulty: float, uses: int) -> int:
	return roundi((base_cost + cost_per_difficulty * maxf(difficulty, 0.0)) * pow(cost_growth, uses))


## Un resultado al azar: un símbolo por rodillo.
func roll(rng: RandomNumberGenerator) -> Array[SlotSymbol]:
	var results: Array[SlotSymbol] = []
	for _reel: int in reels:
		results.append(symbols.pick(rng) as SlotSymbol)
	return results


## Segundos hasta que se para el último rodillo.
func total_time() -> float:
	return spin_time + reel_delay * (reels - 1)


## Lo que da [param results]: el jackpot si todos son iguales, la pareja del símbolo que más se
## repite si hay al menos dos iguales, o [code]null[/code] si no hay premio.
static func evaluate(results: Array[SlotSymbol]) -> SlotOutcome:
	var best: SlotSymbol = null
	var best_count := 0
	for symbol: SlotSymbol in results:
		var count := results.count(symbol)
		if count > best_count:
			best = symbol
			best_count = count
	if best == null or best_count < 2:
		return null
	return best.jackpot if best_count == results.size() else best.pair
