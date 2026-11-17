class_name SlotSymbol
extends WeightedEntry
## Un símbolo de los rodillos de una tragaperras: su icono, cuánto sale (su peso) y qué da si salen
## dos ([member pair]) o tres iguales ([member jackpot]).

@export var icon: Texture2D
## Lo que da con dos iguales.
@export var pair: SlotOutcome
## Lo que da con tres iguales (el jackpot).
@export var jackpot: SlotOutcome
