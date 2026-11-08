class_name StatModifier
extends Resource
## Cambio sobre una stat de un [StatBlock]. Mejoras, rasgos de personaje, pactos y efectos
## temporales son listas de modificadores: nunca tocan una stat a mano (CLAUDE.md, regla 7).
## Una vez aplicado se trata como inmutable: para cambiarlo, quítalo y aplica otro.

## Cómo se combina con la base. Valor final:
## [code](base + Σ FLAT) × (1 + Σ PERCENT) × Π MULTIPLIER[/code].
enum Kind {
	FLAT, ## Se suma a la base: [code]1[/code] = +1 salto, [code]2[/code] = +2 m/s.
	PERCENT, ## Se suma a los demás porcentajes: [code]0.25[/code] = +25 %, [code]-0.1[/code] = −10 %.
	MULTIPLIER, ## Multiplica el resultado: [code]1.5[/code] = ×1,5; [code]0.5[/code] = la mitad.
}

## Nombre de la stat: el de la propiedad en su Resource de datos (p. ej. [code]run_speed[/code]).
@export var stat: StringName = &""
@export var kind: Kind = Kind.FLAT
@export var value: float = 0.0


## Crea un modificador desde código (efectos generados durante la partida y tests).
static func create(stat_name: StringName, modifier_kind: Kind, amount: float) -> StatModifier:
	var modifier := StatModifier.new()
	modifier.stat = stat_name
	modifier.kind = modifier_kind
	modifier.value = amount
	return modifier
