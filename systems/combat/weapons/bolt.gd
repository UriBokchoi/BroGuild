class_name Bolt
extends Projectile
## Proyectil sencillo: da al primero que toca con el daño de su arma y termina. Lo usan el tirador
## y cualquier arma que solo necesite un disparo recto.


func _impact(hurtbox: HurtboxComponent, _point: Vector3) -> void:
	strike(hurtbox)
	_finish()
