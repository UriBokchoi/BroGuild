class_name HurtboxComponent
extends Area3D
## Zona donde una entidad recibe daño: las [HitboxComponent] que la tocan le pasan sus golpes y ella
## se los da a su vida. Su capa de física dice de quién es ([code]player_hurtbox[/code],
## [code]enemy_hurtbox[/code]). Puede ser distinta del cuerpo: la del jugador baja en el slide.

## Recibió un golpe; [param amount] es el daño que hizo de verdad (0 si se esquivó).
signal hurt(info: DamageInfo, amount: float)

@export var health: HealthComponent


func _ready() -> void:
	# La detección la hacen las hitbox: esta solo tiene que ser detectable.
	monitoring = false
	monitorable = true


## Pasa el golpe a la vida. Devuelve el daño que hizo de verdad.
func receive(info: DamageInfo) -> float:
	var amount := health.take_damage(info)
	hurt.emit(info, amount)
	return amount
