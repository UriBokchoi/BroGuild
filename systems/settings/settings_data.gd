class_name SettingsData
extends Resource
## Cómo son las opciones del juego: qué buses de audio tienen volumen, los valores al estrenar el
## juego (también el idioma) y las resoluciones de ventana que se ofrecen. Los valores viven en
## [code]data/settings/settings.tres[/code]; aquí todo vale 0 o vacío a propósito.

## Buses de audio con control de volumen ([code]default_bus_layout.tres[/code]). En las opciones se
## llaman [code]OPTIONS_VOLUME_<BUS>[/code].
@export var volume_buses: Array[StringName] = []
## Volumen de cada bus al estrenar el juego (de 0 a 1).
@export_range(0.0, 1.0, 0.05) var default_volume: float = 0.0
## Cuánto cambia el volumen con cada paso del deslizador.
@export_range(0.01, 0.25, 0.01) var volume_step: float = 0.0
## VSync al estrenar el juego.
@export var default_vsync: bool = false
## Tamaños de ventana que se ofrecen (solo los que caben en la pantalla).
@export var resolutions: Array[Vector2i] = []
## Partidas que guarda la clasificación (las mejores).
@export_range(1, 200, 1) var leaderboard_size: int = 0
## Idioma al estrenar el juego (código de [TranslationServer]: [code]es[/code], [code]en[/code]…).
@export var default_locale: String = ""
