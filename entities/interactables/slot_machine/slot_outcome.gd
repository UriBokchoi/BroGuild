class_name SlotOutcome
extends Resource
## Lo que da una tirada de tragaperras (GDD §5.3): una recompensa por el
## [code]EventBus.pickup_collected[/code], como un recogible (el oro lo suma el monedero, la cura
## y la maldición las aplican sus [PickupEffect]…), y el texto que lo anuncia.

## Recompensa que da ([code]gold[/code], [code]heal[/code], [code]upgrade[/code]…).
@export var reward: StringName = &""
## Cuánto (o, con [member scale_with_cost], cuántas veces lo que costó la tirada).
@export_range(0.0, 1000.0, 0.01, "or_greater") var amount: float = 0.0
## Si [member amount] multiplica lo que costó la tirada (el oro).
@export var scale_with_cost: bool = false
## Clave de traducción del anuncio; si lleva [code]%d[/code], se pone lo que vale.
@export var text_key: StringName = &""


## Lo que vale si la tirada costó [param cost].
func value_for(cost: float) -> float:
	return amount * cost if scale_with_cost else amount
