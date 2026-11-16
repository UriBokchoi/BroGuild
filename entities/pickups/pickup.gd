class_name Pickup
extends Node3D
## Un recogible en el mundo (gema de experiencia…): su tipo, lo que vale y si ya vuela hacia quien
## lo recoge. Se ve con el color y el tamaño del nivel de su valor ([member PickupData.tiers]). No
## se mueve solo: un [PickupField] lo saca de su pool, lo mueve, lo junta con otros y lo recoge. El
## giro y el balanceo van en su shader, para que cientos de ellos no cuesten un
## [code]_process[/code] cada uno.

## Altura sobre el suelo a la que flota.
@export_range(0.0, 2.0, 0.05, "suffix:m") var float_height: float = 0.35
## Modelo: toma el color (parámetro de instancia [code]color[/code] de su shader) y el tamaño de su
## nivel. Vacío: siempre igual.
@export var visual: GeometryInstance3D

## Tipo de recogible (lo pone el [PickupField] al crearlo).
var data: PickupData
## Lo que vale (experiencia, oro…). Para cambiarlo, [method set_amount].
var amount: float = 0.0
## Ya vuela hacia quien lo recoge (no se suelta aunque se aleje).
var attracted: bool = false
## Velocidad actual del vuelo.
var speed: float = 0.0


## Lo pone en el mundo sobre [param ground] con el valor [param value].
func activate(ground: Vector3, value: float) -> void:
	process_mode = Node.PROCESS_MODE_INHERIT
	visible = true
	global_position = ground + Vector3.UP * float_height
	attracted = false
	speed = 0.0
	set_amount(value)
	reset_physics_interpolation()


## Cambia lo que vale (al juntarse con otros) y se ve con el nivel que le toca.
func set_amount(value: float) -> void:
	amount = value
	var tier := data.tier_for(value) if data else null
	if visual == null or tier == null:
		return
	visual.set_instance_shader_parameter(&"color", tier.color)
	visual.scale = Vector3.ONE * tier.scale


## Lo saca del mundo hasta el siguiente [method activate].
func deactivate() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
