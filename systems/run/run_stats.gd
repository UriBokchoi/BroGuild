class_name RunStats
extends RefCounted
## Lo que pasó en una partida, para la pantalla de resultados (y más adelante el Archivo y el bote):
## tiempo, nivel, enemigos y élites derrotados, oro ganado y daño infligido. Lo rellena un
## [RunRecorder].

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
