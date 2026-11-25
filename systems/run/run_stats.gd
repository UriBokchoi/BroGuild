class_name RunStats
extends RefCounted
## Lo que pasó en una partida, para la pantalla de resultados (y más adelante el Archivo y el bote):
## tiempo, nivel, enemigos y élites derrotados, oro ganado, daño infligido, si se venció al jefe su
## premio por rapidez y, en un nivel con tiers, hasta qué fase se llegó. Lo rellena un [RunRecorder].

## Segundos de partida.
var seconds: float = 0.0
## Nivel alcanzado.
var level: int = 1
## Enemigos derrotados (élites incluidos).
var kills: int = 0
## Élites derrotados.
var elite_kills: int = 0
## Oro ganado en total (aunque se haya gastado).
var gold_earned: float = 0.0
## Daño hecho a enemigos (tras su defensa).
var damage_dealt: float = 0.0
## Se pasó el nivel venciendo al jefe.
var won: bool = false
## Multiplicador del premio del jefe por rapidez (si se venció).
var boss_bonus: float = 0.0
## Fase a la que se llegó en un nivel con tiers (su nombre; vacío: un nivel sin tiers).
var stage_key: StringName = &""
## Bro-monedas ganadas (por élites y jefes).
var bro_coins: int = 0
