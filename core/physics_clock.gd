class_name PhysicsClock
## Reloj de la física: segundos de física desde que arrancó el juego. No depende de si quien lo
## consulta se procesa o no (una hitbox que no toca nada, una vida que no regenera), así que sirve
## para esperas sin [code]_process[/code] por nodo.


## Segundos de física desde que arrancó el juego.
static func now() -> float:
	return float(Engine.get_physics_frames()) / Engine.physics_ticks_per_second
