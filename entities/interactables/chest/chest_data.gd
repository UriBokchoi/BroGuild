class_name ChestData
extends Resource
## Cómo es un cofre (GDD §5.2): qué rarezas salen ([WeightedTable] de [Rarity], con la Suerte del
## jugador), de qué carpeta salen los objetos, cuánto cuesta (sube con la dificultad y con cada
## cofre abierto en la partida) y cuánto dura el revelado. Los valores viven en
## [code]data/chests/[/code]; aquí todo vale 0 o vacío a propósito.

## Rarezas que pueden salir (la Suerte sube las altas).
@export var rarities: WeightedTable
## Carpeta de los objetos pasivos que pueden salir.
@export_dir var items_dir: String = ""
@export_group("cost")
## Oro que cuesta el primer cofre con dificultad 0.
@export_range(0.0, 10000.0, 1.0, "or_greater") var base_cost: float = 0.0
## Oro que se suma por cada punto de dificultad.
@export_range(0.0, 1000.0, 0.5, "or_greater") var cost_per_difficulty: float = 0.0
## Multiplica el coste por cada cofre ya abierto en la partida.
@export_range(1.0, 10.0, 0.05) var cost_growth: float = 1.0
@export_group("reveal")
## Segundos que tarda en revelarse lo que sale (y en llegar al jugador).
@export_range(0.1, 10.0, 0.05, "suffix:s") var reveal_time: float = 0.0


## Oro que cuesta con dificultad [param difficulty] tras abrir [param opened] cofres en la partida.
func cost_at(difficulty: float, opened: int) -> int:
	return roundi((base_cost + cost_per_difficulty * maxf(difficulty, 0.0)) * pow(cost_growth, opened))


## Los objetos que pueden salir (los de [member items_dir]).
func load_catalog() -> Array[PassiveItemData]:
	var catalog: Array[PassiveItemData] = []
	catalog.assign(ResourceDir.load_all(items_dir, PassiveItemData))
	return catalog


## Un objeto al azar de [param catalog]: tira una rareza (con [param luck] puntos de Suerte) y elige
## uno de esa rareza. Si no hay ninguno de esa rareza, prueba con las de debajo y, si tampoco,
## cualquiera. [code]null[/code] si el catálogo está vacío.
func roll(catalog: Array[PassiveItemData], luck: float, rng: RandomNumberGenerator) -> PassiveItemData:
	if catalog.is_empty():
		return null
	var rarity := rarities.pick(rng, luck) as Rarity
	for index: int in range(rarities.entries.find(rarity), -1, -1):
		var wanted := rarities.entries[index] as Rarity
		var matching := catalog.filter(
			func(item: PassiveItemData) -> bool: return item.rarity != null and item.rarity.id == wanted.id
		)
		if not matching.is_empty():
			return matching[rng.randi_range(0, matching.size() - 1)]
	return catalog[rng.randi_range(0, catalog.size() - 1)]
