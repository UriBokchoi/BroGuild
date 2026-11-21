class_name SoundCue
extends Resource
## Un sonido del juego: su audio, cómo suena (volumen y variación de tono al azar) y cuánto se deja
## repetir (voces a la vez y separación mínima), para que cien enemigos muriendo a la vez no saturen.

@export var stream: AudioStream
@export_range(-40.0, 12.0, 0.5, "suffix:dB") var volume_db: float = 0.0
## Variación de tono al azar en cada vez: 0,1 = ±10 %.
@export_range(0.0, 0.5, 0.01) var pitch_variation: float = 0.0
## Cuántas veces puede sonar a la vez (0 = sin límite).
@export_range(0, 32, 1) var max_voices: int = 0
## Segundos mínimos entre una vez y la siguiente.
@export_range(0.0, 1.0, 0.005, "suffix:s") var min_interval: float = 0.0
