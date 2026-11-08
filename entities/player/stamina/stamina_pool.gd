class_name StaminaPool
extends RefCounted
## Cargas de stamina, lógica pura. Las cargas pueden ser fraccionarias (el ½ del salto en pared
## o una carga a medio recargar).

## Margen para que los errores de coma flotante al recargar no impidan gastar una carga entera.
const CHARGE_EPSILON := 1e-6

## Cargas máximas. Si bajan, las cargas actuales no pasan del nuevo máximo.
var max_charges: int = 0:
	set(value):
		max_charges = maxi(value, 0)
		charges = minf(charges, max_charges)
var charges: float = 0.0


## Llena todas las cargas.
func fill() -> void:
	charges = max_charges


func can_spend(cost: float) -> bool:
	return charges + CHARGE_EPSILON >= cost


## Gasta [param cost] cargas si las hay. Devuelve si las gastó.
func spend(cost: float) -> bool:
	if not can_spend(cost):
		return false
	charges = maxf(charges - cost, 0.0)
	return true


## Recarga [param delta] segundos, a una carga cada [param seconds_per_charge]. Devuelve si
## cambió algo.
func recharge(delta: float, seconds_per_charge: float) -> bool:
	if charges >= max_charges or seconds_per_charge <= 0.0:
		return false
	charges = minf(charges + delta / seconds_per_charge, max_charges)
	return true
