class_name HealEffect
extends PickupEffect
## Comida: cura al jugador una parte de su vida máxima (lo que vale el recogible: 0,25 = un 25 %).

## Vida que se cura.
@export var health: HealthComponent


func apply(amount: float) -> void:
	health.heal(health.get_maximum() * amount)
