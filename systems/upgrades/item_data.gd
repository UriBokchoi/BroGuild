@abstract
class_name ItemData
extends Resource
## Algo que el jugador lleva y sube de nivel durante una partida: un arma ([WeaponData]) o una runa
## ([RuneData]). Es lo que ofrecen la elección de subir de nivel, el Archivo y la armería de
## práctica. Cada nivel por encima del 1 es una mejora tirada ([method roll_upgrade]): una rareza
## decide cuántas de sus [member upgrade_stats] toca y cuánto.

## Identificador estable (guardado, desbloqueos): no cambia aunque cambie el nombre.
@export var id: StringName = &""
## Clave de traducción del nombre (p. ej. [code]WEAPON_SWORD_NAME[/code]).
@export var name_key: StringName = &""
## Clave de traducción de la descripción.
@export var description_key: StringName = &""
## Icono (HUD, cartas de subir de nivel). Los de serie están en
## [code]assets/textures/icons/[/code].
@export var icon: Texture2D
## Nivel máximo.
@export_range(1, 100, 1) var level_cap: int = 0
## Stats que pueden mejorar sus subidas de nivel, con la mejora de una carta común.
@export var upgrade_stats: Array[UpgradeStat] = []


## Nivel máximo.
func max_level() -> int:
	return level_cap


## Clave de traducción de qué es (arma, runa…), para mostrarlo.
@abstract func kind_key() -> StringName


## Mejora tirada con [param rarity]: toca al azar tantas de sus [member upgrade_stats] como diga la
## rareza, cada una con su fuerza.
func roll_upgrade(rarity: Rarity, rng: RandomNumberGenerator) -> ItemUpgrade:
	var upgrade := ItemUpgrade.new()
	upgrade.rarity = rarity
	var pool := upgrade_stats.duplicate()
	for _stat: int in rarity.roll_count(pool.size(), rng):
		var chosen: UpgradeStat = pool.pop_at(rng.randi_range(0, pool.size() - 1))
		upgrade.stat_modifiers.append(chosen.modifier(rarity.power))
	return upgrade


## Mejora estándar (sin rareza): todas sus [member upgrade_stats] con la fuerza de una común. La
## usan la armería de práctica y las herramientas; cada llamada da una nueva.
func default_upgrade() -> ItemUpgrade:
	var upgrade := ItemUpgrade.new()
	for upgrade_stat: UpgradeStat in upgrade_stats:
		upgrade.stat_modifiers.append(upgrade_stat.modifier(1.0))
	return upgrade
