class_name SfxRecipe
extends Resource
## Receta de un efecto de sonido sintetizado (al estilo de sfxr): una onda con su tono, que se
## desliza de [member start_frequency] a [member end_frequency], con saltos de arpegio, vibrato,
## algo de ruido, un filtro de graves y su envolvente (ataque, sostén y caída). [SfxSynth] la
## convierte en muestras y [code]tools/gen_sfx.gd[/code] la guarda como [code].wav[/code] en
## [code]assets/audio/sfx/[/code]. Para retocar un sonido: cambia su receta y vuelve a generar.

enum Wave { SQUARE, SAW, SINE, TRIANGLE, NOISE }

## Forma de la onda.
@export var wave: Wave = Wave.SQUARE
## Ancho del pulso de la onda cuadrada (0,5 = cuadrada; menos, más nasal).
@export_range(0.05, 0.95, 0.01) var duty: float = 0.5

@export_group("pitch")
## Tono al empezar.
@export_range(20.0, 8000.0, 1.0, "suffix:Hz") var start_frequency: float = 440.0
## Tono al acabar (se desliza de uno a otro, en escala musical).
@export_range(20.0, 8000.0, 1.0, "suffix:Hz") var end_frequency: float = 440.0
## Saltos de tono: x = segundo en que salta, y = cuánto multiplica el tono (los saltos se acumulan:
## 1,26 y luego 1,19 suben una tercera y luego otra, hasta la quinta).
@export var arpeggio: PackedVector2Array = PackedVector2Array()
## Vibrato: cuánto oscila el tono (parte de él) y cuántas veces por segundo.
@export_range(0.0, 1.0, 0.01) var vibrato_depth: float = 0.0
@export_range(0.0, 60.0, 0.1, "suffix:Hz") var vibrato_speed: float = 0.0
## Parciales que suenan a la vez, para timbres metálicos (una moneda): x = cuánto multiplica el tono
## y y = su volumen. Vacío = solo la onda. Los de una moneda no son múltiplos exactos (inarmónicos).
@export var partials: PackedVector2Array = PackedVector2Array()

@export_group("envelope")
## Segundos que tarda en subir el volumen.
@export_range(0.0, 2.0, 0.001, "suffix:s") var attack: float = 0.0
## Segundos a todo volumen.
@export_range(0.0, 2.0, 0.001, "suffix:s") var sustain: float = 0.1
## Golpe al empezar el sostén (sube el volumen y baja durante el sostén).
@export_range(0.0, 1.0, 0.01) var punch: float = 0.0
## Segundos que tarda en apagarse.
@export_range(0.0, 3.0, 0.001, "suffix:s") var decay: float = 0.1
## Forma de la caída: 1 = recta; más, se apaga deprisa al principio y luego se arrastra (como el
## metal al sonar).
@export_range(0.25, 8.0, 0.05) var decay_curve: float = 1.0

@export_group("color")
## Cuánto ruido se mezcla con la onda (0 = nada, 1 = solo ruido).
@export_range(0.0, 1.0, 0.01) var noise: float = 0.0
## Corte del filtro de graves (más bajo, más sordo; 0 = sin filtro).
@export_range(0.0, 20000.0, 10.0, "suffix:Hz") var low_pass: float = 0.0
## Volumen final.
@export_range(0.0, 1.0, 0.01) var volume: float = 0.5
## Semilla del ruido (el mismo sonido cada vez que se genera).
@export var noise_seed: int = 1


## Segundos que dura.
func duration() -> float:
	return attack + sustain + decay
