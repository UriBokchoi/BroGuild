@abstract
class_name OnHitEffect
extends Resource
## Algo que puede pasar al golpear a un enemigo, además del golpe: lo traen los objetos pasivos
## ([member PassiveItemData.on_hit]). En cada golpe del jugador, [OnHitEffects] tira
## [member chance] (las copias del mismo objeto la suman) y, si sale, lo aplica. El daño que hace un
## efecto no vuelve a tirar efectos: no hay cadenas sin fin.

## Probabilidad por golpe, en %.
@export_range(0.0, 100.0, 0.5, "suffix:%") var chance: float = 0.0
## Tipo del daño que hace (el color de sus números de daño, ver [member DamageInfo.kind]).
@export var kind: StringName = &""
## Clave de traducción de su línea en las fichas; lleva sus números (ver [method describe]).
@export var describe_key: StringName = &""


## Lo aplica a [param target] (con su vida, [param health]), al que acaba de golpear [param hit].
@abstract func apply(effects: OnHitEffects, target: Node3D, health: HealthComponent, hit: DamageInfo) -> void


## Su línea en las fichas con [param copies] copias: p. ej. «15 % al golpear: envenena 3 s».
func describe(copies: int = 1) -> String:
	return TranslationServer.translate(describe_key) % _values(copies)


## Los números de [member describe_key], en su orden.
@abstract func _values(copies: int) -> Array


## Un número para las fichas (con el separador decimal del idioma, sin ceros de más).
static func _number(value: float) -> String:
	return StatFormat.number(value)
