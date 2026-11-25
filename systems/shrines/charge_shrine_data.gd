class_name ChargeShrineData
extends Resource
## Cómo es un santuario de carga (las pesas del Brosque): cuánto hay que quedarse cerca, a qué
## distancia y qué mejoras ofrece al cargarse. Los valores viven en data/shrines/; aquí todo vale 0
## o vacío a propósito.

## Segundos dentro de su zona para cargarlo.
@export_range(0.5, 60.0, 0.5, "suffix:s") var charge_time: float = 0.0
## Radio de su zona.
@export_range(0.5, 20.0, 0.1, "suffix:m") var reach: float = 0.0
## Cuántas mejoras ofrece para elegir.
@export_range(1, 6, 1) var choices: int = 0
## Las stats que puede ofrecer, con su fuerza en una rareza rara (las demás la multiplican).
@export var stats: Array[UpgradeStat] = []
## Rarezas de las mejoras y cuánto sale cada una.
@export var rarities: WeightedTable
