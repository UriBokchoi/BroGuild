class_name StatOffer
extends RefCounted
## Una mejora de stats que se ofrece para elegir (la de una pesa-santuario): una stat de su lista y
## la rareza que le tocó, que da su fuerza.

var stat: UpgradeStat
var rarity: Rarity


## Hasta [param count] ofertas con stats distintas de [param pool], cada una con una rareza tirada de
## [param rarities] (la Suerte, [param luck], sube las altas).
static func roll(
	pool: Array[UpgradeStat],
	count: int,
	rarities: WeightedTable,
	luck: float,
	rng: RandomNumberGenerator,
) -> Array[StatOffer]:
	var left := pool.duplicate()
	var offers: Array[StatOffer] = []
	while offers.size() < count and not left.is_empty():
		var offer := StatOffer.new()
		offer.stat = left.pop_at(rng.randi_range(0, left.size() - 1))
		offer.rarity = rarities.pick(rng, luck) as Rarity
		offers.append(offer)
	return offers


## El modificador que da, con la fuerza de su rareza.
func modifier() -> StatModifier:
	return stat.modifier(rarity.power)
