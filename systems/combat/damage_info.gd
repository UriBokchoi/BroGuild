class_name DamageInfo
extends RefCounted
## Un golpe: cuánto daño lleva (ya con el daño y el crítico del atacante), si es crítico, de dónde
## viene y cuánto empuja. Lo crea quien ataca y lo recibe la vida del objetivo.

var amount: float = 0.0
var critical: bool = false
## Nodo que hace el daño (un arma, un enemigo, una trampa…). Puede ser null.
var source: Node
## Empuje: la velocidad que da a quien lo recibe (m/s en el suelo; un cuerpo pesado se mueve menos).
var knockback: Vector3 = Vector3.ZERO


static func create(damage: float, is_critical: bool = false, from: Node = null, push: Vector3 = Vector3.ZERO) -> DamageInfo:
	var info := DamageInfo.new()
	info.amount = damage
	info.critical = is_critical
	info.source = from
	info.knockback = push
	return info
