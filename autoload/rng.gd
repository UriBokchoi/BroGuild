extends Node
## Fuente única de azar del juego. Cada sistema tiene su propio generador,
## sembrado a partir de la semilla de la partida: los bugs se reproducen con la
## misma semilla y el azar de un sistema no altera la secuencia de otro.
## La lógica pura no llama a este autoload: recibe el RandomNumberGenerator por
## parámetro, así se testea sin estado global.

## Un generador por sistema. Cada semilla se deriva del NOMBRE del valor, así que
## añadir o reordenar valores no cambia las secuencias existentes.
enum Stream {
	LOOT, ## Botín: cofres y drops.
	WAVES, ## Director de oleadas.
	GAMBLE, ## Apuestas: ruleta, tragaperras, pactos, doble o nada.
	COMBAT, ## Críticos, dispersión y probabilidades de efectos.
	ENEMIES, ## Afijos de élite y variaciones de enemigos.
	COSMETIC, ## Efectos visuales y sonido; nunca decide nada de gameplay.
}

## Semilla de la partida actual (la que hay que apuntar para reproducir un bug).
var run_seed: int = 0

var _streams: Dictionary[Stream, RandomNumberGenerator] = {}


func _ready() -> void:
	# Hasta que empiece una partida, los generadores tienen que ser utilizables.
	seed_run(make_seed())


## Semilla nueva no determinista, para empezar una partida.
func make_seed() -> int:
	var source := RandomNumberGenerator.new()
	source.randomize()
	return source.randi()


## Vuelve a sembrar todos los generadores a partir de la semilla de la partida.
func seed_run(new_seed: int) -> void:
	run_seed = new_seed
	_streams.clear()
	for id: Stream in Stream.values():
		var generator := RandomNumberGenerator.new()
		generator.seed = derive_seed(new_seed, id)
		_streams[id] = generator


## Generador del sistema indicado.
func stream(id: Stream) -> RandomNumberGenerator:
	return _streams[id]


## Semilla de un generador concreto a partir de la semilla de la partida.
static func derive_seed(base_seed: int, id: Stream) -> int:
	return hash("%d:%s" % [base_seed, Stream.find_key(id)])
