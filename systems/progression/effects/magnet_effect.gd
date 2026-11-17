class_name MagnetEffect
extends PickupEffect
## Imán: todos los recogibles de [member attracts] que hay en el mapa (la experiencia) vuelan hacia
## el jugador a la vez.

## Dónde están los recogibles.
@export var field: PickupField
## Recompensa de los recogibles que atrae.
@export var attracts: StringName = &"experience"


func apply(_amount: float) -> void:
	field.attract_all(attracts)
