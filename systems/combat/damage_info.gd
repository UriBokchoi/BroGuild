class_name DamageInfo
extends RefCounted
## Un golpe: cuánto daño lleva (ya con el daño y el crítico del atacante), si es crítico y de
## dónde viene. Lo crea quien ataca y lo recibe la vida del objetivo.

var amount: float = 0.0
var critical: bool = false
## Nodo que hace el daño (un arma, un enemigo, una trampa…). Puede ser null.
var source: Node


static func create(damage: float, is_critical: bool = false, from: Node = null) -> DamageInfo:
	var info := DamageInfo.new()
	info.amount = damage
	info.critical = is_critical
	info.source = from
	return info
