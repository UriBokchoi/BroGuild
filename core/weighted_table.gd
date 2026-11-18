class_name WeightedTable
extends Resource
## Tabla ponderada (CLAUDE.md, regla 8): elige una entrada al azar según sus pesos, con el generador
## que se le pase (así se reproduce con la semilla). Sirve para el botín, las tragaperras, los
## cofres… Cada uso define su tipo de entrada heredando de [WeightedEntry]. La Suerte sube el peso de
## cada entrada según su [member WeightedEntry.luck_scaling].

@export var entries: Array[WeightedEntry] = []


## Una entrada al azar según los pesos (con [param luck] puntos de Suerte), o [code]null[/code] si
## no hay ninguna con peso.
func pick(rng: RandomNumberGenerator, luck: float = 0.0) -> WeightedEntry:
	var total := total_weight(luck)
	if total <= 0.0:
		return null
	var roll := rng.randf() * total
	for entry: WeightedEntry in entries:
		var weight := entry.weight_with_luck(luck)
		if weight <= 0.0:
			continue
		roll -= weight
		if roll < 0.0:
			return entry
	# Por redondeo, el último con peso.
	for index: int in range(entries.size() - 1, -1, -1):
		if entries[index].weight_with_luck(luck) > 0.0:
			return entries[index]
	return null


## Suma de los pesos (con [param luck] puntos de Suerte).
func total_weight(luck: float = 0.0) -> float:
	var total := 0.0
	for entry: WeightedEntry in entries:
		total += entry.weight_with_luck(luck)
	return total


## Probabilidad (0–1) de que salga [param entry] con [param luck] puntos de Suerte.
func chance(entry: WeightedEntry, luck: float = 0.0) -> float:
	var total := total_weight(luck)
	if total <= 0.0 or not entries.has(entry):
		return 0.0
	return entry.weight_with_luck(luck) / total
