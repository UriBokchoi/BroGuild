class_name SfxBank
extends Resource
## Qué suena con cada cosa del juego ([SoundCue]); lo usa el autoload [code]Sfx[/code]. Un hueco
## vacío no suena. Vive en [code]data/audio/sfx_bank.tres[/code].

## Bus por el que suenan (su volumen está en las opciones).
@export var bus: StringName = &"Effects"
## Sonidos que pueden sonar a la vez en total.
@export_range(1, 64, 1) var voices: int = 24
## Volumen de todos los efectos, sumado al de cada uno: baja o sube la mezcla entera sin tocar las
## proporciones entre ellos.
@export_range(-40.0, 12.0, 0.5, "suffix:dB") var volume_db: float = 0.0

@export_group("player")
@export var player_hurt: SoundCue
@export var player_died: SoundCue
@export var level_up: SoundCue

@export_group("combat")
@export var enemy_hit: SoundCue
@export var enemy_died: SoundCue
@export var boss_spawned: SoundCue
## Llega un miniboss (el Trolleador Cara).
@export var mini_boss_spawned: SoundCue
## Llega un heraldo del Gremio.
@export var herald_arrived: SoundCue
## Se sella un pacto del Gremio.
@export var pact_sealed: SoundCue
@export var boss_defeated: SoundCue

@export_group("pickups")
## Por la recompensa del recogible ([member PickupData.reward]: experience, gold, heal…).
@export var pickups: Dictionary[StringName, SoundCue] = {}
## Recompensa que sube de tono si se recoge seguida (la experiencia).
@export var streak_reward: StringName = &""
## Segundos entre una recogida y la siguiente para que cuente como seguida.
@export_range(0.0, 2.0, 0.05, "suffix:s") var streak_window: float = 0.0
## Semitonos que sube como mucho (cada recogida seguida, uno más).
@export_range(0, 24, 1) var streak_max_semitones: int = 0

@export_group("loot")
@export var breakable_broken: SoundCue
@export var chest_opened: SoundCue
## Al revelarse el objeto (cuando la luz se para en su rareza).
@export var item_revealed: SoundCue
@export var chest_denied: SoundCue
@export var slot_spun: SoundCue
## Resultado de la tragaperras sin jackpot, por su texto ([signal EventBus.slot_resolved]); el que no
## esté aquí, [member slot_won].
@export var slot_results: Dictionary[StringName, SoundCue] = {}
@export var slot_won: SoundCue
@export var slot_jackpot: SoundCue

@export_group("hordes")
## Aviso de que viene una horda (un cuerno de guerra).
@export var horde_incoming: SoundCue

@export_group("movement")
## El golpe de una mejora de movimiento, por la stat de su daño ([signal EventBus.synergy_released]:
## dash_wave_damage, slam_damage).
@export var synergies: Dictionary[StringName, SoundCue] = {}

@export_group("roulette")
## Doble o nada ganado y perdido.
@export var double_won: SoundCue
@export var double_lost: SoundCue
## Cada paso de una carta de la ruleta al girar (el tic-tic).
@export var upgrade_spin_tick: SoundCue
## Una carta de la ruleta se para en su rareza.
@export var upgrade_revealed: SoundCue
## Tono de [member upgrade_revealed] por rareza (su id): cuanto más rara, más agudo.
@export var reveal_pitches: Dictionary[StringName, float] = {}

@export_group("ui")
## Cualquier botón de la interfaz al pulsarlo.
@export var button_pressed: SoundCue
