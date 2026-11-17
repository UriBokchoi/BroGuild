class_name PickupData
extends Resource
## Un tipo de recogible (gema de experiencia, oro; más adelante curas…): su escena, qué da al
## recogerlo y cómo vuela hacia quien lo recoge. Los valores viven en [code]data/pickups/[/code];
## aquí todo vale 0 o vacío a propósito.

## Identificador estable (pool).
@export var id: StringName = &""
## Escena del recogible: su raíz es un [Pickup].
@export var scene: PackedScene
## Qué da al recogerlo. Lo escucha el sistema que lo usa por [code]EventBus.pickup_collected[/code]
## (p. ej. [code]experience[/code] → [ExperienceComponent]).
@export var reward: StringName = &""

@export_group("magnet")
## Vuela hacia quien lo recoge nada más salir, esté donde esté (el oro: se cobra solo al matar).
## Si no, espera en el suelo a que entre en su radio de recogida.
@export var auto_collect: bool = false
## Velocidad a la que empieza a volar hacia quien lo recoge.
@export_range(0.0, 50.0, 0.1, "or_greater", "suffix:m/s") var start_speed: float = 0.0
## Aceleración mientras vuela (cuanto más tarda, más rápido va).
@export_range(0.0, 500.0, 1.0, "or_greater", "suffix:m/s²") var acceleration: float = 0.0
## Distancia a la que se recoge.
@export_range(0.05, 5.0, 0.05, "or_greater", "suffix:m") var collect_radius: float = 0.0
## Altura sobre los pies de quien lo recoge hacia la que vuela (el pecho).
@export_range(0.0, 3.0, 0.05, "suffix:m") var target_height: float = 0.0

@export_group("merge")
## Lado de la zona en la que los de este tipo que esperan en el suelo se juntan en uno solo con su
## valor sumado (las gemas: menos en pantalla, y de más valor). 0 = no se juntan.
@export_range(0.0, 20.0, 0.1, "or_greater", "suffix:m") var merge_radius: float = 0.0
## Cuántos tiene que haber juntos para fundirse.
@export_range(0, 100, 1) var merge_count: int = 0

@export_group("tiers")
## Cómo se ve según lo que vale (de menor a mayor [member PickupTier.min_amount]). Vacío: siempre
## como su escena.
@export var tiers: Array[PickupTier] = []


## El nivel con el que se ve un recogible que vale [param amount] (el de mayor
## [member PickupTier.min_amount] que no lo pasa), o [code]null[/code] si no tiene niveles.
func tier_for(amount: float) -> PickupTier:
	var best: PickupTier = null
	for tier: PickupTier in tiers:
		if tier.min_amount <= amount and (best == null or tier.min_amount > best.min_amount):
			best = tier
	return best
