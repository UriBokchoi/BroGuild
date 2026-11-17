class_name EliteWaveEffect
extends PickupEffect
## Oleada de élites (maldición de la tragaperras): el director de oleadas saca de golpe tantos
## élites como vale, alrededor del jugador y con la dificultad de ese momento.

@export var director: WaveDirector


func apply(amount: float) -> void:
	director.spawn_elites(maxi(roundi(amount), 1))
