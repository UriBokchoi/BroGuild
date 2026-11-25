class_name PlayerProfile
extends RefCounted
## Lo que el jugador tiene fuera de las partidas: sus bro-monedas y el nivel de cada mejora permanente
## que compró con ellas (comprar, reembolsar). Se guarda en un ConfigFile (write_to, read_from); lo
## carga y lo guarda Save.

const SECTION := "profile"

## Bro-monedas que tiene para gastar.
var bro_coins: int = 0
## Nivel comprado de cada mejora permanente (por id; sin entrada, 0).
var upgrades: Dictionary[StringName, int] = {}


## Suma [param amount] bro-monedas (nunca resta).
func add_bro_coins(amount: int) -> void:
	bro_coins += maxi(amount, 0)


## Nivel comprado de [param id] (0 sin comprar).
func level_of(id: StringName) -> int:
	return upgrades.get(id, 0)


## ¿Puede comprar el siguiente nivel de [param upgrade]? (No está al máximo y le llegan las monedas.)
func can_buy(upgrade: MetaUpgradeData) -> bool:
	var next := level_of(upgrade.id) + 1
	return next <= upgrade.max_level() and bro_coins >= upgrade.cost_of(next)


## Compra el siguiente nivel de [param upgrade] si puede ([method can_buy]); si no, no hace nada y
## devuelve [code]false[/code].
func buy(upgrade: MetaUpgradeData) -> bool:
	if not can_buy(upgrade):
		return false
	var next := level_of(upgrade.id) + 1
	bro_coins -= upgrade.cost_of(next)
	upgrades[upgrade.id] = next
	return true


## Deshace todas las mejoras de [param catalog] y devuelve las bro-monedas que costaron (y cuántas
## son). Las que no están en el catálogo se quedan: no se sabe lo que costaron.
func refund(catalog: MetaUpgradeCatalog) -> int:
	var refunded := 0
	for upgrade: MetaUpgradeData in catalog.upgrades:
		refunded += upgrade.spent_up_to(level_of(upgrade.id))
		upgrades.erase(upgrade.id)
	bro_coins += refunded
	return refunded


func write_to(config: ConfigFile) -> void:
	config.set_value(SECTION, "bro_coins", bro_coins)
	var saved := {}
	for id: StringName in upgrades:
		saved[String(id)] = upgrades[id]
	config.set_value(SECTION, "upgrades", saved)


func read_from(config: ConfigFile) -> void:
	var saved: Variant = config.get_value(SECTION, "bro_coins", 0)
	bro_coins = maxi(saved as int, 0) if saved is int else 0
	upgrades.clear()
	var levels: Variant = config.get_value(SECTION, "upgrades", {})
	if not levels is Dictionary:
		return
	for key: Variant in levels:
		var level: Variant = (levels as Dictionary)[key]
		if (key is String or key is StringName) and level is int and level > 0:
			upgrades[StringName(str(key))] = level
