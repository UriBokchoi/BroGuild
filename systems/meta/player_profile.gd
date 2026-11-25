class_name PlayerProfile
extends RefCounted
## Lo que el jugador tiene fuera de las partidas: sus bro-monedas (y, más adelante, las mejoras que
## compre con ellas). Se guarda en un ConfigFile (write_to, read_from); lo carga y lo guarda Save.

const SECTION := "profile"

## Bro-monedas que tiene para gastar.
var bro_coins: int = 0


## Suma [param amount] bro-monedas (nunca resta).
func add_bro_coins(amount: int) -> void:
	bro_coins += maxi(amount, 0)


func write_to(config: ConfigFile) -> void:
	config.set_value(SECTION, "bro_coins", bro_coins)


func read_from(config: ConfigFile) -> void:
	var saved: Variant = config.get_value(SECTION, "bro_coins", 0)
	bro_coins = maxi(saved as int, 0) if saved is int else 0
