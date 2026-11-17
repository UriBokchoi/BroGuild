class_name WeightedTable
extends Resource
## Tabla ponderada (CLAUDE.md, regla 8): elige una entrada al azar según sus pesos, con el generador
## que se le pase (así se reproduce con la semilla). Sirve para el botín, las tragaperras, los
## cofres… Cada uso define su tipo de entrada heredando de [WeightedEntry]. Más adelante, la Suerte
## desplazará los pesos hacia las rarezas altas.

@export var entries: Array[WeightedEntry] = []


## Una entrada al azar según los pesos, o [code]null[/code] si no hay ninguna con peso.
func pick(rng: RandomNumberGenerator) -> WeightedEntry:
	var total := total_weight()
	if total <= 0.0:
		return null
	var roll := rng.randf() * total
	for entry: WeightedEntry in entries:
		if entry.weight <= 0.0:
			continue
		roll -= entry.weight
		if roll < 0.0:
			return entry
	# Por redondeo, el último con peso.
	for index: int in range(entries.size() - 1, -1, -1):
		if entries[index].weight > 0.0:
			return entries[index]
	return null


## Suma de los pesos.
func total_weight() -> float:
	var total := 0.0
	for entry: WeightedEntry in entries:
		total += maxf(entry.weight, 0.0)
	return total
