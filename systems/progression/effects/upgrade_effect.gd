class_name UpgradeEffect
extends PickupEffect
## Mejora gratis (premio de la tragaperras): sube un nivel a un arma o runa que lleve el jugador y
## no esté al máximo, al azar, tantas veces como vale el premio. Si ya lo tiene todo al máximo, no
## hace nada.

## Armas del jugador.
@export var weapons: WeaponInventory
## Runas del jugador.
@export var runes: RuneInventory

## Azar de la elección. Si no se asigna antes de entrar en el árbol, el flujo de apuestas de
## [code]Rng[/code].
var rng: RandomNumberGenerator


func _ready() -> void:
	if rng == null:
		rng = Rng.stream(Rng.Stream.GAMBLE)


func apply(amount: float) -> void:
	for _upgrade: int in maxi(roundi(amount), 1):
		var options := _upgradable()
		if options.is_empty():
			return
		options[rng.randi_range(0, options.size() - 1)].call()


## Una llamada por cada arma o runa que se puede subir (sube un nivel).
func _upgradable() -> Array[Callable]:
	var options: Array[Callable] = []
	for weapon: Weapon in weapons.get_weapons():
		if weapon.level < weapon.data.max_level():
			options.append(weapon.set_level.bind(weapon.level + 1))
	for rune: RuneData in runes.get_runes():
		var level := runes.get_level(rune)
		if level < rune.max_level():
			options.append(runes.set_level.bind(rune, level + 1))
	return options
