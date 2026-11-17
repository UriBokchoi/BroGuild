class_name ItemPool
extends Resource
## De dónde sale un objeto pasivo (un cofre, el premio del jefe): qué rarezas pueden salir
## ([WeightedTable] de [Rarity], con la Suerte del jugador) y de qué carpeta salen los objetos. Los
## valores viven en el [code].tres[/code] de quien lo usa; aquí todo vale vacío a propósito.

## Rarezas que pueden salir (la Suerte sube las altas).
@export var rarities: WeightedTable
## Carpeta de los objetos pasivos que pueden salir.
@export_dir var items_dir: String = ""


## Los objetos que pueden salir (los de [member items_dir]).
func load_catalog() -> Array[PassiveItemData]:
	var catalog: Array[PassiveItemData] = []
	catalog.assign(ResourceDir.load_all(items_dir, PassiveItemData))
	return catalog


## Un objeto al azar de [param catalog]: tira una rareza (con [param luck] puntos de Suerte) y elige
## uno de esa rareza. Si no hay ninguno de esa rareza, prueba con las de debajo en la tabla y, si
## tampoco, cualquiera. [code]null[/code] si el catálogo está vacío.
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
