extends Node
## Bus global de señales entre sistemas lejanos. Solo declara señales tipadas:
## nunca guarda estado ni tiene lógica. Quien emite y quien escucha no se conocen.

# Las señales se emiten desde otros scripts; sin esto, Godot avisa con
# UNUSED_SIGNAL en cada una.
@warning_ignore_start("unused_signal")

## Ha empezado una partida con la semilla indicada.
signal run_started(run_seed: int)
## La partida en curso ha terminado.
signal run_ended
