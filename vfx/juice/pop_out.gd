class_name PopOut
extends RefCounted
## Estallido al desaparecer: el modelo crece un poco y encoge a nada, y luego se libera su dueño. Lo
## usan los rompibles y las llaves del jefe.


## [param visual] crece hasta [param grow] veces su tamaño y encoge a nada en [param time] segundos
## (mitad y mitad); luego se libera [param owner].
static func play(owner: Node, visual: Node3D, grow: float, time: float) -> void:
	var pop := owner.create_tween()
	pop.tween_property(visual, ^"scale", visual.scale * grow, time * 0.5)
	pop.tween_property(visual, ^"scale", Vector3.ZERO, time * 0.5)
	pop.tween_callback(owner.queue_free)
