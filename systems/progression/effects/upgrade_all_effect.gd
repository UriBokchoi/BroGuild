class_name UpgradeAllEffect
extends PickupEffect
## Todo mejorado (el trío de estrellas de la tragaperras): sube un nivel, con una mejora tirada con
## su rareza (con Suerte, las altas salen más), a cada arma y runa del jugador que no esté al máximo,
## tantas veces como vale el premio. Cada subida sale en el HUD ([signal EventBus.announced]) del
## color de su rareza.

## Armas del jugador.
@export var weapons: WeaponInventory
## Runas del jugador.
@export var runes: RuneInventory
## Rarezas de las mejoras.
@export var rarities: WeightedTable
## Stats del jugador, de donde sale su Suerte. Sin ellas, Suerte 0.
@export var stats: StatsComponent
## Texto de cada subida (clave con un [code]%s[/code], el nombre, y un [code]%d[/code], el nivel).
@export var announce_key: StringName = &""

## Azar de las mejoras. Si no se asigna antes de entrar en el árbol, el flujo de apuestas de
## [code]Rng[/code].
var rng: RandomNumberGenerator


func _ready() -> void:
	if rng == null:
		rng = Rng.stream(Rng.Stream.GAMBLE)


func apply(amount: float) -> void:
	for _round: int in maxi(roundi(amount), 1):
		for weapon: Weapon in weapons.get_weapons():
			if weapon.level < weapon.max_level():
				var upgrade := _roll(weapon.data)
				weapon.add_upgrade(upgrade)
				_announce(weapon.data, weapon.level, upgrade)
		for rune: RuneData in runes.get_runes():
			if runes.get_level(rune) < rune.max_level_with(stats):
				var upgrade := _roll(rune)
				runes.upgrade(rune, upgrade)
				_announce(rune, runes.get_level(rune), upgrade)


func _roll(item: ItemData) -> ItemUpgrade:
	var luck := stats.get_value(&"luck") if is_instance_valid(stats) else 0.0
	return item.roll_upgrade(rarities.pick(rng, luck) as Rarity, rng)


func _announce(item: ItemData, level: int, upgrade: ItemUpgrade) -> void:
	if not announce_key.is_empty():
		EventBus.announced.emit(announce_key, [item.name_key, level], upgrade.rarity.color)
