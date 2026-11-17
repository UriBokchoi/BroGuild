class_name LevelUpOffer
extends RefCounted
## Elige las opciones de una subida de nivel (lógica pura, con el azar inyectado): de
## [param catalog], los objetos que ya lleva y no están al máximo (para subirlos) y los que no lleva
## si le queda ranura de ese tipo (armas o runas). Todas distintas, al azar. De momento todas pesan
## lo mismo; las rarezas y la ruleta llegarán en el Hito 4.


## Hasta [member LevelUpData.choices] opciones. [param levels] es el nivel de cada objeto que lleva
## (por id).
static func build(
	catalog: Array[ItemData],
	levels: Dictionary[StringName, int],
	data: LevelUpData,
	rng: RandomNumberGenerator,
) -> Array[LevelUpOption]:
	var weapons := _count_owned(catalog, levels, WeaponData)
	var runes := _count_owned(catalog, levels, RuneData)
	var candidates: Array[LevelUpOption] = []
	for item: ItemData in catalog:
		var level: int = levels.get(item.id, 0)
		if level >= item.max_level():
			continue
		if level == 0:
			var full := weapons >= data.weapon_slots if item is WeaponData else runes >= data.rune_slots
			if full:
				continue
		candidates.append(LevelUpOption.create(item, level + 1))
	_shuffle(candidates, rng)
	return candidates.slice(0, data.choices)


static func _count_owned(catalog: Array[ItemData], levels: Dictionary[StringName, int], type: Script) -> int:
	var count := 0
	for item: ItemData in catalog:
		if is_instance_of(item, type) and levels.get(item.id, 0) > 0:
			count += 1
	return count


## Fisher–Yates con el generador dado (reproducible con semilla).
static func _shuffle(options: Array[LevelUpOption], rng: RandomNumberGenerator) -> void:
	for index: int in range(options.size() - 1, 0, -1):
		var other := rng.randi_range(0, index)
		var swap := options[index]
		options[index] = options[other]
		options[other] = swap
