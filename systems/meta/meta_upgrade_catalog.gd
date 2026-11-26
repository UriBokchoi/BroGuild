class_name MetaUpgradeCatalog
extends Resource
## Las mejoras permanentes de la pestaña «Mejoras», en el orden en que salen. Con los niveles
## comprados de un perfil arma lo que suman a la base del jugador en cada partida (build_set). Los
## valores viven en data/meta/upgrades.tres.

@export var upgrades: Array[MetaUpgradeData] = []


## La mejora con [param id] (o [code]null[/code]).
func find(id: StringName) -> MetaUpgradeData:
	for upgrade: MetaUpgradeData in upgrades:
		if upgrade.id == id:
			return upgrade
	return null


## Lo que suman las mejoras a los niveles de [param levels] (por id), como un conjunto que se pone en
## la base del jugador ([member StatsComponent.base_sets]).
func build_set(levels: Dictionary[StringName, int]) -> StatModifierSet:
	var bonuses := StatModifierSet.new()
	for upgrade: MetaUpgradeData in upgrades:
		bonuses.stat_modifiers.append_array(upgrade.modifiers_at(levels.get(upgrade.id, 0) as int))
	return bonuses
