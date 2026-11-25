class_name MetaUpgradeData
extends Resource
## Una mejora permanente de la pestaña «Mejoras» del menú: se compra con bro-monedas, nivel a nivel, y
## en cada partida suma a la base del jugador lo de su nivel (como el personaje: no cuenta como
## mejora de la partida). Se puede reembolsar. Los valores viven en data/meta/upgrades.tres.

## Identificador estable (el perfil guarda el nivel por él).
@export var id: StringName = &""
## Clave de traducción del nombre.
@export var name_key: StringName = &""
## Clave de traducción de lo que hace.
@export var description_key: StringName = &""
@export var icon: Texture2D

@export_group("effect")
## Stats del jugador que cambia (todas con el mismo valor).
@export var stats: Array[StringName] = []
@export var kind: StatModifier.Kind = StatModifier.Kind.FLAT
## Lo que suma en total en cada nivel (el primero, el del nivel 1). Tantos niveles como valores.
@export var values: PackedFloat32Array = []
## Cómo se muestra el valor: clave con un [code]%s[/code] y por cuánto se multiplica (100 si guarda
## porcentajes como 0,01).
@export var value_key: StringName = &"UPGRADE_VALUE_FLAT"
@export_range(1.0, 100.0, 1.0) var display_scale: float = 1.0

@export_group("cost")
## Bro-monedas que cuesta cada nivel (el primero, comprar el nivel 1).
@export var costs: PackedInt32Array = []


## Nivel máximo: tantos como valores con su coste.
func max_level() -> int:
	return mini(values.size(), costs.size())


## Bro-monedas que cuesta subir a [param level] (desde 1); 0 fuera de rango.
func cost_of(level: int) -> int:
	if level < 1 or level > max_level():
		return 0
	return costs[level - 1]


## Bro-monedas gastadas en total para llegar a [param level] (lo que devuelve el reembolso).
func spent_up_to(level: int) -> int:
	var total := 0
	for step: int in range(1, mini(level, max_level()) + 1):
		total += cost_of(step)
	return total


## Lo que suma a [param level] (0 sin comprar).
func value_at(level: int) -> float:
	level = mini(level, max_level())
	return values[level - 1] if level >= 1 else 0.0


## Sus modificadores a [param level] (ninguno sin comprar).
func modifiers_at(level: int) -> Array[StatModifier]:
	var modifiers: Array[StatModifier] = []
	if level < 1:
		return modifiers
	for stat: StringName in stats:
		modifiers.append(StatModifier.create(stat, kind, value_at(level)))
	return modifiers


## Su valor a [param level] para mostrarlo («+3 %»).
func value_text(level: int) -> String:
	return tr(value_key) % StatFormat.number(value_at(level) * display_scale)
