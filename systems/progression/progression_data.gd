class_name ProgressionData
extends Resource
## Stats de progresión y botín: experiencia y oro ganados, suerte, radio de recogida, dificultad,
## probabilidad de botín y ranuras abiertas de armas y runas. Los valores viven en
## [code]data/player/progression.tres[/code]; aquí todo vale 0 a propósito. Su efecto exacto está en
## el GDD (§6, «Stats del personaje»).

@export_group("progression")
## Multiplica la experiencia que ganas.
@export_range(0.0, 1000.0, 1.0, "or_greater", "suffix:%") var xp_gain: float = 0.0
## Multiplica el oro que ganas.
@export_range(0.0, 1000.0, 1.0, "or_greater", "suffix:%") var currency_gain: float = 0.0
## Multiplica las bro-monedas que ganas (las de fuera de la partida).
@export_range(0.0, 1000.0, 1.0, "or_greater", "suffix:%") var bro_coin_gain: float = 0.0
## Suerte: desplaza los pesos de las rarezas hacia arriba (GDD §5).
@export_range(0.0, 100.0, 1.0, "or_greater") var luck: float = 0.0
## Distancia desde la que se recogen experiencia y objetos (el oro llega solo).
@export_range(0.5, 50.0, 0.1, "or_greater", "suffix:m") var pickup_range: float = 0.0
## Dificultad: hace a los enemigos más numerosos y fuertes y sube el botín de los rompibles. Sube
## sola 1 por minuto (se la suma el director de oleadas) y con objetos o runas: más riesgo, más
## recompensa. Las curvas de [WaveData] van según ella.
@export_range(0.0, 100.0, 0.1, "or_greater") var difficulty: float = 0.0
## Probabilidad de botín: la de que un enemigo normal suelte un extra (un power-up; más adelante,
## cofres). Élites y rompibles la multiplican ([member EliteData.drop_chance_multiplier]). Muy baja de
## serie; la suben objetos y runas.
@export_range(0.0, 100.0, 0.01, "suffix:%") var drop_chance: float = 0.0

@export_group("slots")
## Armas que puede llevar a la vez: las ranuras abiertas. Nunca pasan de las que hay
## ([member LevelUpData.max_weapon_slots]); el resto se ven cerradas en el HUD.
@export_range(1, 4, 1, "or_greater") var weapon_slots: int = 0
## Runas que puede llevar a la vez (como [member weapon_slots]).
@export_range(1, 4, 1, "or_greater") var rune_slots: int = 0
## Veces por partida que puede saltarse una elección al subir de nivel (sin coger nada).
@export_range(0, 10, 1, "or_greater") var skips: int = 0
## Veces por partida que puede vetar una carta al subir de nivel (no vuelve a salir; salen otras).
@export_range(0, 10, 1, "or_greater") var bans: int = 0
## Niveles de más sobre el máximo de cada arma ([method ItemData.max_level_with]).
@export_range(0, 20, 1, "or_greater") var weapon_level_bonus: int = 0
## Niveles de más sobre el máximo de cada runa.
@export_range(0, 40, 1, "or_greater") var rune_level_bonus: int = 0
