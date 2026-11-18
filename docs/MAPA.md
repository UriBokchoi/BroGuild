# Mapa del código — Bro Guild

Para qué sirve cada carpeta y cada sistema, cómo se conectan y dónde se añade cada cosa. Es la guía para orientarse antes de tocar nada.

- **Por qué** se hizo así: `docs/DECISIONES.md`.
- **Qué** tiene que hacer el juego: `docs/GDD.md`.
- **Qué toca ahora**: `docs/ROADMAP.md`.

Se actualiza al crear, mover o quitar un sistema o una carpeta, no al cambiar detalles. Cada script tiene además su docstring `##` con su intención.

## Las cinco ideas que ordenan todo

1. **Datos fuera del código.** Cada número de balance o de feel vive en un `.tres` de `data/` (o en un `@export` de su escena). Todo número exportado de un Resource de datos es una **stat** mejorable con modificadores.
2. **Composición.** Las entidades son nodos con componentes (`StatsComponent`, `HealthComponent`, `HitboxComponent`, `HurtboxComponent`…), no clases enormes. Herencia solo en bases cortas (`State`, `Weapon`, `Enemy`).
3. **Llamar hacia abajo, señales hacia arriba.** Un nodo llama a sus hijos; los hijos avisan con señales. Entre sistemas lejanos, `EventBus`. El juice (números, bamboleos, estelas) solo escucha.
4. **Una feature, una carpeta.** El script, la escena y los Resources propios de una feature van juntos. El script de un Resource de datos va con su sistema; sus `.tres` de balance, en `data/`.
5. **Los tests replican las rutas.** `x/y/z.gd` se prueba en `tests/unit/x/y/test_z.gd` (lógica) o en `tests/integration/x/y/test_z.gd` (escenas).

## Carpetas

| Carpeta | Qué va ahí |
|---|---|
| `autoload/` | Los únicos singletons: `EventBus` (solo señales), `Rng` (todo el azar, un generador por sistema), `RunState` (partida en curso: personaje, nivel y semilla) y `Save` (lo que dura entre partidas, en `user://`; de momento, las opciones). Sin lógica de gameplay. |
| `core/` | Piezas genéricas que no saben de este juego: stats, máquina de estados, componentes de combate, pool (`NodePool`), rejilla espacial (`SpatialHash`, con marcas y tope de resultados), carga de carpetas de datos (`ResourceDir`), tabla ponderada (`WeightedTable` de `WeightedEntry`: cada uso hereda su entrada; la Suerte sube el peso de cada entrada según su `luck_scaling`), nombres de acciones y capas. |
| `entities/` | Lo que existe en el mundo: el jugador, los enemigos (y los jefes), los interactuables y los rompibles. |
| `systems/` | Reglas y sistemas que reparten trabajo entre entidades: combate (fórmulas y armas), progresión, aparición de enemigos, armas y runas (`upgrades/`), objetos pasivos (`items/`), el jefe del nivel (`boss/`), la partida (`run/`) y las opciones (`settings/`). Vacía, para más adelante: `gamble/`. |
| `data/` | Los `.tres` de balance y la traducción. Nada de código. |
| `ui/` | HUD, menús, panel de depuración, vista de stats, tema global y dueño del ratón. |
| `vfx/` | Efectos visuales: juice que reacciona a señales, shaders compartidos (desenfoque, rejilla y columna de luz) y líneas de velocidad. |
| `levels/` | Escenas jugables: `common/` (`RunSystems`, los sistemas de partida que usa cada nivel, y `layout/`, los mapas generados: `LevelLayout`, `LayoutData`, `LayoutPiece`, `ForestBuilder`, `ForestData`), el Brosque (`brosque/`), el gimnasio de pruebas con su zona de combate y la prueba de estrés. |
| `tools/` | Validación por terminal (`validate.sh`, `ci/`), generadores (`gen_themes.gd`) y la simulación de equilibrio (`sim_balance.gd`: daño por segundo de cada personaje contra una horda y contra un jefe, al empezar y con una build de mitad de partida). |
| `tests/` | GUT: `unit/` y `integration/`, con la misma ruta que el código. `hooks/` es el script de fin de ejecución. |
| `docs/` | GDD, ROADMAP, DECISIONES y este mapa. |
| `assets/` | Assets reutilizables y `CREDITS.md`. `models/props/`: piezas hechas con mallas básicas (espada, escudo, bastón, sombrero de mago, daga) con sus materiales en `materials/`; las llevan los personajes y pueden servir para otras cosas (el Archivo, botín). `textures/icons/`: iconos SVG de armas, runas, objetos pasivos y de la interfaz (candado). Audio y fuentes, aún vacíos. |

## Sistemas

### Stats — `core/stats/`
- **Para qué:** que cualquier número del juego se pueda mejorar o empeorar sin tocarlo a mano, como en Megabonk.
- `StatsComponent` (nodo) convierte en stats los números exportados de sus `sources` (Resources de datos) y guarda copias «resueltas» que el juego lee con tipo (`get_resolved(MovementData)`).
- `StatBlock` es el único sitio donde se calcula una stat: `(base + Σ planos) × (1 + Σ %) × Π multiplicadores`. El rango de cada `@export_range` es su límite en juego (`RangeHint`).
- Los modificadores son `StatModifier`; los que van juntos (un personaje, una mejora, un nivel de arma) forman un `StatModifierSet`.
- **Lo usan:** el jugador (vida, ataque, progresión, movimiento, stamina), cada arma (sus `WeaponStats`) y cada enemigo (`HealthData` + `EnemyStats`).

### Máquina de estados — `core/state_machine/`
- **Para qué:** el movimiento del jugador (y lo que venga) como estados separados, sin `if` gigantes.
- `StateMachine` aplica las reglas de entrada: gana la primera acción, solo el dash cancela, buffer al final de una acción.
- Cada `State` declara en el inspector su acción, su prioridad, si es comprometido, si cancela y a quién puede interrumpir.

### Jugador — `entities/player/`
`player.tscn` monta todos los componentes; `player.gd` solo los conecta y mueve el cuerpo (y se teletransporta y muere). Lleva un personaje: el de `RunState.character` si se eligió uno, si no el de su `character` (el gimnasio pone el Guerrero; la escena sola va sin personaje). `set_character()` lo cambia en el momento (base, arma inicial y pasiva) y guarda la elección en `RunState`.

| Subcarpeta o nodo | Para qué |
|---|---|
| `movement/` | `MovementContext` (estado compartido entre estados), `MovementData` (sus stats), `WallSensor` y `LedgeSensor` (rayos que solo miran el mundo) y `states/`: suelo, aire, salto, doble salto, dash, dash-jump, slide, slide-jump, salto en pared, caída rápida y mantle. Base común: `MovementState`. |
| `feedback/` | Lo que el cuerpo muestra: `BodyCrouch` (agacha el modelo y baja la hurtbox en el slide), `BodyFlip` (mortal hacia delante en el doble salto si el personaje lo tiene, `CharacterData.air_jump_flip`), `BodyFacing` (gira el modelo), `DashJumpCue` (aro de la ventana del dash-jump) y `SpeedTrail` (estela). |
| `stamina/` | Cargas de stamina: `StaminaPool` (lógica pura), `StaminaComponent` (nodo que recarga y avisa por EventBus) y `StaminaData`. |
| `camera/` | `CameraRig` (tercera persona, se mueve en `_process` siguiendo la posición interpolada) y `CameraData`. |
| `characters/` | `CharacterData`: las diferencias de un personaje sobre las stats básicas (su base), su color, su arma inicial, su pasiva y las piezas de su modelo. `model/`: `CharacterModel` (cuerpo que toma el color del personaje y puntos de anclaje: manos, cabeza y espalda; lo usan el jugador y los pedestales) y `ModelAttachment` (qué pieza, en qué punto y cómo colocada). `passives/`: `CharacterPassive` (base: un nodo que el jugador añade al elegir el personaje; sus modificadores se van con él) y `LevelStatPassive`, la de los iniciales: una stat que sube por cada nivel (Veterano, daño, Guerrero; Expansión arcana, área, Mago; Letal, crítico, Pícaro), cada una con su escena y sus números. |
| `player_input.gd` | Convierte el InputMap en acciones de la máquina y en la dirección pedida, relativa a la cámara. |
| `interactor.gd` | Zona que encuentra el `Interactable` más cercano y lo activa con E. |
| Nodos `Health`, `Hurtbox` y `Weapons` | Vida, zona donde recibe daño y `WeaponInventory` con sus armas. |
| `knockback_receiver.gd` | `KnockbackReceiver`: el empuje de los golpes que recibe (contacto, embestida, onda del jefe). Lo suelta sobre el cuerpo y se frena solo, aparte de la velocidad del movimiento. |

### Combate — `core/components/` y `systems/combat/`
- **Golpe:** una `HitboxComponent` toca una `HurtboxComponent`, que pasa el golpe a su `HealthComponent`.
  - La hitbox apunta con señales lo que toca y solo se procesa mientras toca algo.
  - `DamageCalc.attack()` aplica el daño % y el crítico del atacante (`OffenseData`).
  - La vida tira la esquiva y aplica la defensa (`CombatRules`, `data/combat/rules.tres`).
  - Cada golpe es un `DamageInfo`, con su empuje (`knockback`, m/s en el suelo): el de la hitbox o el proyectil (`WeaponStats.knockback` por el empuje % del atacante; los enemigos, su `EnemyStats.knockback` fijo), desde quien golpea hacia quien recibe (`DamageCalc.push`). Un enemigo lo suma a su velocidad dividido por su masa (élites y jefes se mueven menos); el jugador, con su `KnockbackReceiver`.
- **`HealthComponent`:** muere una sola vez, puede ser inmortal (el muñeco) y `reset()` la rellena (enemigos reutilizados). Tras un golpe que hace daño, no recibe más durante su `invulnerability_time` (los «i-frames»: el jugador, 0,3 s; los enemigos, 0) y lo avisa con `invulnerability_started`; el reloj es `PhysicsClock` (`core/`), sin `_process`. Solo se procesa si regenera.
- **Armas** (`systems/combat/weapons/`):
  - `WeaponData` lleva el `.tres` del arma con sus `WeaponStats` de nivel 1; sus mejoras por nivel son tiradas (ver «Objetos y runas»). `Weapon` guarda las que lleva (`add_upgrade`, `get_upgrades`); `set_level` sube con la mejora estándar o quita las últimas (la armería).
  - `Weapon` es la base: ataca sola por cadencia al más cercano desde `aim_height` y combina sus stats con las del personaje (si las tiene: un enemigo no). `disarm()` la para y retira lo que tenga en juego; `rearm(espera)` la vuelve a poner en marcha. Sin objetivo, busca cada `search_interval`.
  - `TargetFinder` hace una consulta de física y apunta al centro de la hurtbox.
  - `WeaponInventory` es el nodo que crea y quita armas: lo lleva el jugador y lo crea el enemigo que tiene armas.
  - **Las mismas armas sirven a los dos bandos:** la escena dice a quién busca (`target_mask`) y a quién da su proyectil (`hit_mask`). Las de los enemigos viven en `data/enemies/weapons/`, fuera de la armería y de la subida de nivel.
  - **Proyectiles:**
    - `ProjectileWeapon` dispara desde un pool un `Projectile` por golpe, hacia el centro del objetivo; sus stats son `ProjectileStats` (velocidad de proyectil), de los que heredan `StaffStats` y `DaggerStats`. Las del jugador tienen su propio pool (al desarmarlas, sus proyectiles desaparecen); las de los enemigos usan el `ProjectilePool` compartido.
    - `ProjectilePool`: proyectiles de muchas armas, un pool por escena y un máximo en vuelo (si se llena, el disparo no sale). Lo crea el `EnemySwarm`: así los disparos de un enemigo siguen volando aunque muera.
    - `Projectile` (base abstracta) vuela recto y traza un rayo por tick (no atraviesa nada, sin `Area3D`). Golpea con `DamageCalc` + hurtbox, igual que las hitbox. Cada proyectil decide en `_impact` qué hace al dar.
    - `Bolt` (`bolt.gd`): el proyectil más simple, da al primero que toca y termina (el disparo del tirador).
- **Espada** (`sword/`): `Sword` crea `SwordSlash`, un arco con shader y hitbox, desde un pool, inclinado hacia el objetivo.
- **Bastón** (`staff/`): `StaffOrb` explota al tocar enemigo o pared y daña a todos en `explosion_radius` × área, con su explosión en shader.
- **Daga** (`dagger/`): `DaggerBlade` da a uno y, si le quedan `bounces`, salta al más cercano dentro de `bounce_range` con todo su daño.

### Enemigos — `entities/enemies/` y `systems/spawning/`
- **Tipos:** `EnemyData` (en `data/enemies/`) lleva escena, fuentes de stats (`HealthData` y `EnemyStats`: velocidad, contacto, separación, trepar y distancia que guarda) y armas (`weapons`, opcional).
- **`Enemy`** (base de las escenas):
  - Es un `RigidBody3D` sin rotación que choca con el mundo, con el jugador y con otros enemigos.
  - Fija su velocidad horizontal con `EnemySteering`: perseguir con desvío, separarse y decidir si trepa. Con `keep_distance` se queda a esa distancia (`keep_range`) mirando al objetivo.
  - Daña al tocar y con sus armas, si tiene: las crea al prepararse, esperan un poco al aparecer (`first_attack_delay`) y paran al morir (sus disparos en vuelo siguen). Avisa de su muerte y encoge.
  - Mejoras de una vida (se quitan al volver a salir del pool): `boost(StatModifierSet)` aplica modificadores a sus stats y a las de sus armas (cada uno adonde exista su stat) y le llena la vida; `promote(EliteData)` lo hace élite.
  - Recalcula su rumbo repartido entre ticks, salvo con `steer_every_tick` (los jefes, en todos). `is_boss()` dice si es un jefe.
- **Élites** (`elite/`): `EliteData` (en `data/enemies/elite.tres`) lleva sus mejoras, su tamaño (cuerpo, zonas de golpe, modelo y masa) y su brillo (`elite_glow`, un `material_overlay`). Cualquier enemigo puede salir élite: lo decide quien lo saca (`WaveData.elite_chance`, el invocador de élites).
- **`EnemySwarm`** (en el nivel) saca enemigos de un `NodePool` por tipo y los mueve en un único bucle.
  - Usa un `SpatialHash` con los vivos, marcando los apoyados para trepar, y una sola consulta de hasta `max_neighbors` vecinos.
  - Cada enemigo recalcula su rumbo cada `steering_slices` ticks; la física lo mueve en todos.
  - Tiene el `ProjectilePool` de los enemigos (`projectile_limit` en vuelo a la vez); `clear()` retira enemigos y proyectiles (con `keep_dying`, los que están muriendo terminan de caer: el jefe vencido).
  - Puede parar el tiempo (`freeze_for`): todos los enemigos (también los que salen mientras) se congelan con `Enemy.set_frozen` (cuerpo estático, sin contacto ni armas, pero se les puede golpear) y sus disparos se paran en el aire; avisa por `time_stop_changed`.
- **Oleadas:**
  - `WaveData` (en `data/waves/`) es una ronda: curva de enemigos por segundo según la **dificultad** (la stat `difficulty` del jugador, que sube 1 por minuto y con objetos; sin bonus, dificultad = minutos), picos, máximo a la vez, distancias de aparición, `WaveEnemy` con pesos y dificultad de entrada, probabilidad de élite según la dificultad, duración de la ronda (`round_minutes`) y escalado (`StatScaling`: una stat de enemigo o de arma y su curva de multiplicador según la dificultad). `data/waves/test_gym.tres` y `brosque.tres` son la ronda normal.
  - `WaveDirector` (en `RunSystems`) los saca alrededor del jugador, en el suelo (un rayo por intento), con el escalado de la dificultad de ese momento (`boost`) y, a veces, élites. Lleva la parte del tiempo de la dificultad: un modificador +1 por minuto en la stat `difficulty` de `difficulty_stats` (el jugador), que quita al parar. Es el reloj de la ronda: avisa cada segundo por `run_clock_changed`. `spawn_around` saca enemigos alrededor de un punto con el escalado del momento, aunque no esté en marcha (los refuerzos del jefe).
- **`DamageReporter`** avisa de cada golpe con la posición de la cabeza (para los números).
- **Tipos y escenas actuales:**
  - `swarmer/`: el esbirro, rápido y frágil, ataca al tocar;
  - `shooter/`: el tirador, se queda a distancia y dispara bolas de fuego lentas (su arma y su proyectil van en la misma carpeta);
  - `sapling/`: el Bro-te, un arbolito con cinta en la frente, rápido y frágil, que solo sale como refuerzo del Ent-renador;
  - `ent_trainer/`: el Ent-renador, jefe del Brosque (ver «Jefe»);
  - `target_dummy/`: muñeco de práctica inmortal con `DpsMeter`.

### Jefe — `entities/enemies/boss/`, `systems/boss/` y el altar
- **Para qué:** el jefe de cada nivel (GDD §9). Se invoca en su altar con las llaves del nivel o sale solo al acabar la ronda; vencerlo pasa el nivel.
- **`Boss`** (`entities/enemies/boss/`, base de la escena de un jefe): un `Enemy` grande que sale del mismo enjambre y recalcula su rumbo en cada tick. Persigue y, cada `attack_interval`, hace uno de sus ataques (sus nodos hijos `BossAttack`, al azar por peso); mientras ataca, el ataque mueve el cuerpo.
  - Por debajo de `enrage_below` de su vida entra en rabia: aplica `enrage` (más rápido) sin rellenarse la vida, ataca más a menudo y se le pone `enrage_overlay`.
  - Grita al empezar cada ataque (`shouted`) y pide refuerzos con `summon_requested`.
  - La bomba no le hace nada.
- **Ataques** (`attacks/`, cada uno con sus números en `@export` de la escena del jefe):
  - `LeapAttack` (salta y, al caer, suelta una `Shockwave` por el suelo; un aro marca dónde caerá);
  - `ChargeAttack` (apunta con una franja en el suelo y embiste en línea recta, varias veces, con más daño al tocar);
  - `SummonAttack` (pide refuerzos de un `EnemyData`, más con rabia).
  - El daño de sus ataques es su daño al tocar (con el escalado) por un factor.
- **`Shockwave`** (`shockwave/`): onda que se abre hasta su radio y daña una vez a lo que alcanza su borde a ras de suelo (se esquiva saltándola o alejándose). Se ve con `vfx/shaders/ground_ring.gdshader`, que también dibuja el aro de aviso.
- **`BossData`** (`systems/boss/`, en `data/bosses/`): qué enemigo es, llaves que hacen falta, mensajes al salir, título de la victoria, sus curvas de escalado con la dificultad y el premio (oro × `early_bonus` según los minutos al vencerlo, y un objeto de su `ItemPool` de rarezas altas).
- **`BossEncounter`** (en `RunSystems`, con el `BossData` del nivel: `RunSystems.boss`):
  - cuenta las llaves (`boss_key_collected` → `boss_keys_changed`);
  - saca al jefe cuando el altar lo pide con las llaves (o forzado), una vez por partida, escalado con la dificultad de ese momento;
  - pasa al HUD su vida y sus gritos; sus refuerzos salen por `WaveDirector.spawn_around`.
  - Al vencerlo: para las oleadas, retira a los demás enemigos, da el premio (oro por `pickup_collected` y el objeto por `item_revealed`) y avisa con `boss_defeated`.
- **Altar** (`entities/interactables/boss_altar/`, `BossAltar`): pieza del mapa generado.
  - Con «interactuar» pide el jefe donde aparece (`boss_spawn`), y lo pide forzado al empezar la prórroga (`run_clock_changed`).
  - Muestra las llaves en sus ranuras y, con todas, una columna de luz. Se apaga al salir el jefe.
- **Llaves** (`entities/interactables/boss_key/`, `BossKey`): en el Brosque, tarjetas de socio que giran bajo una columna de luz. Se cogen con «interactuar» y las reparte un `BreakableScatter` del nivel.

### Interacción — `entities/interactables/`
- `Interactable` es el área con un texto y la señal `interacted`; la detecta el `Interactor` del jugador, que marca como elegido al más cercano (`focus_changed`). También avisa al activarse o desactivarse (`enabled_changed`).
- **Aviso de que se puede usar** (`InteractHint`, en `vfx/juice/interact_hint/`): encima de las mallas del objeto, un destello que lo recorre de vez en cuando y, en el elegido, un borde de luz más marcado (`interact_glint.gdshader`). Desactivado, no se ve. Lo llevan el cofre, la tragaperras, la calavera, la bolsita, la tarjeta y el altar.
- **Interactuables actuales:**
  - `teleporter/`: `Teleporter`, pisar y aparecer en su destino; también es el recogedor de caídas;
  - `armory/`: la armería de práctica (armas y runas);
  - `summoner/`: el invocador de enemigos de práctica (uno por tipo, y uno de élites; su cartel muestra el nombre del enemigo);
  - `character_pedestal/`: pedestal con el modelo vestido de un personaje; al interactuar, el jugador pasa a ser él (hasta la selección de personaje del Hito 3);
  - `slot_machine/`: tragaperras (`SlotMachine`). Aguanta `max_uses` tiradas (5) y revienta. Con «interactuar» cobra su coste (`SlotMachineData`: `base_cost` + `cost_per_difficulty` × dificultad, ×`cost_growth` por cada uso de esa máquina), saca un símbolo por rodillo de su `WeightedTable` de `SlotSymbol` y avisa por `slot_spun`. Al parar, da el premio del trío o de la pareja (`SlotOutcome`: una recompensa por `pickup_collected`, como un recogible) y lo anuncia por `slot_resolved`. No pausa. Datos en `data/slots/`;
  - `chest/`: cofre (`Chest`). Con «interactuar» cobra su coste (`ChestData`: `base_cost` + `cost_per_difficulty` × dificultad, ×`cost_growth` por cada cofre abierto en la partida; todos los cofres los cuentan por `chest_opened`), saca un objeto pasivo de su `ItemPool` con la Suerte del jugador y lo enseña por `item_revealed` (o avisa por `chest_denied` si falta oro); al acabar el revelado (`reveal_time`), el objeto pasa al `PassiveInventory` del jugador y el cofre desaparece. No pausa. Datos en `data/chests/`;
  - `wave_bell/`: la campana que arranca y para el director de oleadas.
  - `boss_altar/` y `boss_key/`: el altar y las llaves del jefe (ver «Jefe»).

### Objetos y runas — `systems/upgrades/`
- **`ItemData`** es la base de lo que el jugador lleva y sube de nivel: armas (`WeaponData`) y runas (`RuneData`). Lleva id, nombre, descripción, icono, `kind_key()` (arma o runa), su nivel máximo (`level_cap`: 10 las armas y 20 las runas) y las stats que pueden mejorar sus subidas (`upgrade_stats`: `UpgradeStat`, stat, tipo y mejora base: la de una carta rara, que la común multiplica por 0,6; los enteros se redondean y los multiplicadores escalan lo que se alejan de 1).
- **Mejoras con rareza:** cada subida de nivel es una `ItemUpgrade` (un `StatModifierSet` con su `Rarity`) tirada con `ItemData.roll_upgrade`. La `Rarity` (`data/rarities/`, en la tabla `rarities.tres`: común gris, rara verde, improbable azul, de leyenda amarilla y mítica roja) decide cuánto sale (peso), cuántas stats distintas toca (`min_stats`/`max_stats`; 0 = todas) y cuánto más fuerte es (`power`). Con Suerte, las altas salen más (`luck_scaling`; la leen `LevelUpController` y `UpgradeEffect` de las stats del jugador). `default_upgrade()` es la estándar (todas sus stats como una común): la usan la armería, las herramientas y las runas al conseguirlas.
- **Runas** (`runes/`):
  - `RuneData` (en `data/runes/`): al conseguirla da su mejora estándar y cada subida, una tirada.
  - `RuneInventory` (en el jugador) guarda las mejoras de cada runa (`add`, `upgrade`, `set_level`, `remove`) y aplica o quita sus modificadores; su nivel es cuántas lleva.
- **Subir de nivel** (`level_up/`):
  - `LevelUpData` (`data/progression/level_up.tres`): número de opciones, tabla de rarezas, ranuras de armas y de runas que hay (4 y 4) y carpetas de las que salen. Cuántas están abiertas lo dicen las stats del jugador `weapon_slots` y `rune_slots` (2 y 2 al empezar; desbloquear una es un modificador +1).
  - `LevelUpOffer` (lógica pura, con el azar inyectado) elige las opciones: subir lo que lleva sin pasar del máximo (con una mejora tirada con rareza), o algo nuevo si queda ranura abierta de su tipo.
  - `LevelUpController` (en el nivel) escucha `player_leveled_up`, y también `upgrade_choice_requested` (mejoras gratis de la tragaperras, en la misma cola y con su título), abre `LevelUpPanel` (pausa y cartas, en `ui/menus/level_up/`) y aplica la elegida a las armas o runas del jugador. Usa el flujo `GAMBLE` de `Rng`: la ruleta del Hito 4 irá encima.

### Objetos pasivos — `systems/items/`
- **`PassiveItemData`** (un `StatModifierSet` con id, nombre, descripción, icono y `rarity`): objeto de cofre y del premio del jefe. Viven en `data/items/` (15 de momento, de cultura bro: el gimnasio es solo un tema más). No ocupan ranura y se apilan.
- **`ItemPool`**: de dónde sale un objeto (una `WeightedTable` de rarezas, con la Suerte, y la carpeta de objetos). `roll` tira una rareza y elige un objeto de ella (si no hay, de las de debajo). Lo usan los cofres (`ChestData.items`) y el jefe (`BossData.reward_items`, solo rarezas altas).
- **`PassiveInventory`** (nodo `Items` del jugador): `add` aplica otra vez los modificadores de una copia (cada copia es su propio origen), `remove` quita la última, `count`, `get_items` (por orden de llegada) y `total`. Avisa con `item_changed`, que el `Player` pasa a `EventBus.player_passive_changed`.

### Rompibles — `entities/breakables/`
- **`Breakable`:** rompible del nivel (como los jarrones de Megabonk). Se rompe con «interactuar» (su `Interactable`: «Romper la calavera», «Abrir la bolsita»), una sola vez; avisa por `EventBus.breakable_broken` con su `BreakableData` (qué recogible, cuánto, en cuántos trozos y a qué distancia) y desaparece con un estallido (`PopOut`, en `vfx/juice/`).
- **Los de serie:** la calavera (`skull/`, experiencia) y la bolsita (`pouch/`, oro), con sus datos en `data/breakables/`.
- **`BreakableScatter`** (`systems/spawning/`, en el nivel): reparte al empezar las `ScatterEntry` (escena y cuántas) por un rectángulo, en sitios distintos cada partida (flujo `LOOT`). Cada uno cae sobre suelo plano o encima de una meseta, nunca dentro o encima de un árbol o un prop, separado de los demás y, si se pide (`min_center_distance`), lejos del centro. También reparte las llaves del jefe.

### Botín y progresión — `entities/pickups/` y `systems/progression/`
- **Recogibles:**
  - `PickupData` (en `data/pickups/`) lleva escena, recompensa (p. ej. `experience`, `gold`), texto breve al recogerlo (`announce_key` y su color; los power-ups), vuelo hacia quien recoge (`auto_collect`: vuela nada más salir, esté donde esté), cómo se juntan y sus niveles por valor (`tiers`).
  - `Pickup` es el nodo: tipo, valor y si ya vuela. Su giro y su balanceo van en el shader, sin `_process` por nodo.
  - `xp_gem/`: la gema de experiencia; su color (parámetro de instancia del shader) y su tamaño salen de su nivel (`PickupTier`: azul, verde desde 5, roja desde 25, morada desde 100); su brillo late y sus bordes destellan.
  - `gold_coin/`: la moneda de oro (de recogida automática), que destella al ponerse de cara;
  - los power-ups (comida, imán, bomba y bebida) llevan un `DropGlow`.
- **`PickupField`** (en el nivel): suelta recogibles en el suelo desde un pool por tipo. Cuando quien recoge está dentro de su `pickup_range` (o nada más salir, si son `auto_collect`), vuelan acelerando hacia él; al llegar, avisan por `EventBus.pickup_collected`. Todos van en un bucle y sin física. Cada `merge_interval` funde los del mismo tipo que esperan juntos (`PickupData.merge_radius` y `merge_count`) en uno con el valor sumado.
- **`LootDropper`** (en `RunSystems`): al morir un enemigo, su gema (`xp_reward`) y su moneda (`gold_reward`); al romperse un rompible, su botín (`BreakableData`, más con la dificultad) en trozos alrededor. Además, a veces, un **extra** de una `WeightedTable` de `BonusDrop` (recogible, peso y valor; `data/loot/power_ups.tres`): con la probabilidad de botín del jugador (`drop_chance`, 0,5 %) por el multiplicador de quien lo suelta (×1 un enemigo normal, `EliteData.drop_chance_multiplier` ×8, `BreakableData.drop_chance_multiplier` ×12). Lee la dificultad y la probabilidad de `player_stats`. Flujo `LOOT`.
- **Recogibles especiales** (`systems/progression/effects/`, en `RunSystems/PickupEffects`): cada uno es un `PickupData` con su recompensa y un `PickupEffect` que la escucha en `pickup_collected`: comida (`HealEffect`, cura esa parte de la vida máxima), imán (`MagnetEffect`, toda la experiencia del mapa vuela hacia ti, `PickupField.attract_all`), bomba (`BombEffect`, quita esa parte de la vida máxima a los enemigos a menos de `radius`) y bebida energética (`BuffEffect`, aplica un `StatModifierSet` —`data/pickups/energy_drink_buff.tres`— durante los segundos que vale; otra lata reinicia la cuenta, no acumula) y reloj de arena (`TimeStopEffect`, para el tiempo los segundos que vale: `EnemySwarm.freeze_for`). Sus modelos giran y flotan con `SpinBob` (`vfx/juice/`). Además: mejora gratis a elegir (`UpgradeChoiceEffect`, recompensa `upgrade`: pide elecciones como al subir de nivel por `upgrade_choice_requested`), todo mejorado (`UpgradeAllEffect`, `upgrade_all`: sube un nivel cada arma y runa que no esté al máximo, con un texto del color de su rareza), maldición de fragilidad (`BuffEffect` con `data/slots/frailty_curse.tres`, −20 % de vida máxima) y oleada de élites (`EliteWaveEffect`, `WaveDirector.spawn_elites`); los usan las tragaperras.
- **`ExperienceComponent`** (en el jugador): suma la experiencia recogida × `xp_gain` y sube de nivel con la curva de `ExperienceData` (`data/progression/experience.tres`). El jugador aleja la cámara con el nivel.
- **`WalletComponent`** (en el jugador): el oro de la partida (antes «fichas» en el GDD). Suma el recogido × `currency_gain` y lo gasta con `spend()`.
- **Stats de progresión:** `ProgressionData` (experiencia y oro ganados, suerte, radio de recogida, dificultad, probabilidad de botín y ranuras abiertas de armas y runas).

### Juice y efectos — `vfx/`
- **`juice/`**, efectos que solo escuchan señales:
  - `damage_numbers/`: números de daño con pool y estilo en `data/vfx/damage_numbers.tres`;
  - `hit_wobble.gd`: bamboleo al recibir golpes;
  - `slow_motion.gd` (`SlowMotion`, en `RunSystems`): cámara lenta en el jackpot de la tragaperras (`slot_resolved`), en segundos reales;
  - `spin_bob.gd` (`SpinBob`): giro y balanceo de los recogibles especiales y las llaves del jefe (pocos; los que salen a cientos lo hacen en su shader);
  - `pop_out.gd` (`PopOut`): estallido al desaparecer (rompibles y llaves del jefe).
  - `invulnerability_blink.gd` (`InvulnerabilityBlink`, en el jugador): el modelo parpadea mientras dura la invulnerabilidad tras un golpe;
  - `interact_hint/` (`InteractHint`): el destello de lo que se puede usar con «interactuar» (ver «Interacción»);
  - `drop_glow/` (`DropGlow`): columna de luz corta y aro que late en el suelo, del color de cada power-up, para verlos entre la horda.
- **`speed_lines/`:** líneas de velocidad en pantalla.
- **`time_stop/`:** `TimeStopFilter`, la pantalla teñida de azul mientras el tiempo está parado (una capa por debajo del HUD, con su shader).
- **`shaders/`:** shaders compartidos: desenfoque de los menús, rejilla del greybox y columna de luz (`light_beam`: teletransporte, altar, llaves del jefe y power-ups) , aro en el suelo (`ground_ring`: onda y aviso del jefe, power-ups) y destello de lo que se puede usar (`interact_glint`).
- **Shaders propios de una feature:** van con ella (tajo de la espada, plataforma del teletransporte, líneas de velocidad).

### UI — `ui/`
- **`hud/`:** bienvenida al nivel (`LevelIntro`, en el centro, se desvanece sola), vida, stamina, experiencia y nivel (arriba), oro (`GoldCounter`) y reloj de la ronda (`RunClock`, en rojo en la prórroga) y dificultad (`DifficultyCounter`, una calavera y su valor) debajo, las llaves del jefe (`BossKeyCounter`, «1/3», solo en niveles con jefe), armas y runas (`LoadoutBar`: una fila de `LoadoutSlot` por tipo, con icono y nivel; las ranuras sin abrir, con candado), objetos pasivos debajo (`PassiveBar`: icono con el borde de su rareza y «×N» si hay varias copias), el jefe (`BossBar`, arriba en el centro: su nombre, su vida y lo que grita), objetos que salen (`ChestPanel`, de un cofre o del premio del jefe por `item_revealed`, abajo en el centro: la luz recorre las rarezas, frena y se para en la del objeto, que se muestra con su nombre del color de la rareza), tragaperras (`SlotPanel`, también abajo: rodillos que paran uno tras otro y el resultado), textos breves (`AnnouncementFeed`, en el centro bajo la barra del jefe: un power-up recogido, una mejora; de su color, se apilan y se desvanecen) y aviso de interacción. Escuchan el `EventBus`.
- **`menus/pause/`:** menú de pausa con todas las stats del jugador; «Opciones» abre el `OptionsPanel`; «Reintentar» y «Salir» (al menú principal) van por `RunFlow`.
- **`menus/run_setup/`:** `RunSetup`, la selección antes de jugar: personajes a la izquierda, su modelo girando en el centro y, al pasar el ratón, su ficha a la derecha (nombre, diferencias de stats, arma principal y pasiva). Al elegir uno, la ficha se cambia por los niveles (`LevelData.is_available()`: sin escena, «próximamente» y desactivado). «Volver» o Esc retroceden. La muestra `Game` tras «Jugar».
- **`menus/main/`:** `MainMenu`, el menú principal (Jugar, Opciones, Archivo —desactivado hasta su tarea— y Abandonar), con los personajes vestidos de fondo y, abajo a la izquierda y pequeño, el selector de idioma. Lo muestra `Game`.
- **`widgets/`:** piezas de interfaz reutilizables. `LanguagePicker`: un idioma por cada traducción cargada, con su nombre en su propio idioma (`LANGUAGE_NAME`) y un globo; al elegir, lo pone y lo guarda en las opciones.
- **`menus/armory/`:** panel de la armería.
- **`menus/level_up/`:** elección al subir de nivel (`LevelUpPanel` y sus `LevelUpCard`; una mejora lleva el borde y el nombre del color de su rareza).
- **`menus/options/`:** `OptionsPanel`, opciones básicas: volumen de cada bus (`SettingsData.volume_buses`, en `default_bus_layout.tres`), pantalla completa, tamaño de la ventana y VSync. El volumen se aplica al momento; lo de pantalla espera a «Aplicar» (que lo aplica y lo guarda) y «Volver» descarta lo no aplicado. Trabaja sobre `Save.settings`. Dentro del editor (pestaña «Juego») avisa de que la ventana no se puede cambiar y desactiva esas opciones. Lo abre la pausa (y lo abrirá el menú principal).
- **`menus/results/`:** `ResultsPanel`, la pantalla de resultados al acabar la partida: al morir, una frase de muerte al azar (`death_lines`, claves `DEATH_LINE_*`); al vencer al jefe (`boss_defeated`, tras `victory_delay`), el título de la victoria («¡Brosque superado!») y el premio por rapidez. Debajo, tiempo, nivel, enemigos y élites derrotados, oro y daño (del `RunRecorder`). Lo primero que pasa manda. «Reintentar» (R) empieza otra partida y «Salir» vuelve al menú (`RunFlow`).
- **`stats/`:** `StatsView`, la lista de stats de cualquier `StatsComponent` (la usan la pausa y la armería); `StatFormat`, el formato de un valor; y `ModifierFormat`, que describe un modificador («+10 % Daño»).
- **`debug/`:** panel F3 con secciones (`DebugSection`); no se traduce.
- **`theme/`:** el tema global, generado por `tools/gen_themes.gd`.
- **`mouse_capture.gd`:** único dueño del modo del ratón.

### Partida — `systems/run/`
- **`RunRecorder`** (en el nivel): escucha el `EventBus` y apunta en un `RunStats` lo que pasa en la partida: enemigos y élites derrotados, daño infligido, oro ganado (sin restar lo gastado), nivel y tiempo (el del reloj de la ronda si la hay). Para al morir el jugador o al vencer al jefe (apunta la victoria y su premio por rapidez).
- **`Game`** (`game.tscn`, la escena principal): raíz del juego y flujo de pantallas. Empieza en el `MainMenu`; «Jugar» lleva a `RunSetup`, que fija `RunState.character` y el nivel (`RunState.level`) (`LevelData`: id, nombre y escena, en `data/levels/`; de serie, el Brosque) y empieza la partida con una semilla nueva. Cada pantalla sustituye a la anterior.
- **`RunFlow`:** reintentar y volver al menú desde la pausa o los resultados. Dentro de `Game`, por el `EventBus` (`retry_requested`, `main_menu_requested`); con el nivel ejecutado solo (F6), recarga la escena o cierra el juego.
- **Reinicio rápido:** reintentar vuelve a instanciar el nivel con otra semilla (unos 0,2 s en el gimnasio).

### Opciones — `systems/settings/` y `autoload/save.gd`
- **`SettingsData`** (`data/settings/settings.tres`): buses con volumen, valores al estrenar el juego (el idioma, español) y tamaños de ventana que se ofrecen.
- **`GameSettings`:** lo elegido (idioma, volúmenes, pantalla completa, tamaño de ventana, VSync). Se guarda en un `ConfigFile` (`user://settings.cfg`) y se aplica al motor (`apply_audio`, `apply_display`). Sin pantalla (headless) no toca nada; incrustado en el editor (`Engine.is_embedded_in_editor()`, ver `can_change_window`) solo el VSync.
- **`Save`** (autoload) lo carga y lo aplica al arrancar (también el idioma: `TranslationServer.set_locale`); quien lo cambia llama a `Save.save_settings()`. Los tests usan otro archivo (`settings_path`).

### Niveles — `levels/`
- **`common/run_systems.tscn`** (`RunSystems`): jugador, horda y oleadas, botín, subir de nivel, jefe (`BossEncounter`), HUD, pausa, resultados, números de daño y panel de depuración, ya conectados. Cada nivel pone una instancia con sus oleadas (`waves`), su jefe (`boss`, un `BossData`; vacío: sin jefe), si empiezan solas (`autostart_waves`), el personaje de serie y el punto de aparición (`spawn_point`).
- **`brosque/brosque.tscn`:** el Brosque (`data/levels/brosque.tres`), un gimnasio en el bosque de unos 150 × 150 m rodeado de paredes invisibles (a 81 m; también para los enemigos, que solo salen dentro de `RunSystems.play_area`):
  - claro central con el punto de aparición; al empezar, el HUD da la bienvenida (`RunSystems.intro_keys` → `EventBus.level_intro` → `LevelIntro`);
  - piezas: mesetas con rampa (`props/plateau_low.tscn` y `plateau_high.tscn`), pesas de piedra, bancos de tronco, ruinas pequeñas de piedra con musgo (`ruin_temple`, `ruin_wall` y `ruin_arch`, fuera del claro), tragaperras, cofres y el altar del jefe;
  - **el mapa se genera al cargar, distinto en cada partida** (`Layout`, un `LevelLayout` con `data/layouts/brosque.tres`): el altar del jefe al borde del claro y mirándolo (`LayoutPiece.ring` y `face_center`), mesetas, pesas, bancos, una tragaperras y cinco cofres por el suelo sin pisarse ni invadir el claro, tres tragaperras y dos cofres encima de mesetas y el bosque alrededor (`ForestBuilder`: árboles sueltos que esquivan las piezas, un anillo junto a las paredes que choca y una banda grande fuera que no);
  - el jefe es el Ent-renador (`data/bosses/brosque.tres`): tres tarjetas de socio (las justas) repartidas a más de 25 m del centro (`BossKeys`, un `BreakableScatter`); con ellas se invoca en el altar y, si no, sale solo en el minuto 10;
  - las oleadas empiezan solas.
- **`test_gym/test_gym.tscn`:** escena de pruebas (usa `RunSystems`; las oleadas las empieza la campana de la zona de combate). Zona de movimiento con rampas, bordes, paredes, huecos y escalones, más el pad de daño (`props/`).
- **`test_gym/zones/combat_range.tscn`:** zona de combate a 200 m del gimnasio. Muñecos, armería, invocadores (esbirros, tiradores y esbirros élite), pedestales de personaje, campana de oleadas, plataforma escalonada, teletransportes y recogedor de caídas. Las oleadas paran al volver.
- **Sistemas de partida:** viven en `RunSystems` (ver arriba): `EnemySwarm`, `WaveDirector`, `PickupField`, `LootDropper`, `LevelUpController` y `LevelUpPanel`, `RunRecorder` y `ResultsPanel`, `BossEncounter`, `DamageNumbers`, HUD, pausa y panel de depuración.
- **`stress/stress_test.tscn`:** prueba de rendimiento (herramienta, sin traducir). Mantiene 300 y luego 500 esbirros sobre un jugador inmortal con la espada, mide frames y física y sale. Comando en CLAUDE.md.

## Señales del `EventBus`

| Señal | La emite | La escucha |
|---|---|---|
| `run_started`, `run_ended` | `RunState` | (nadie aún) |
| `retry_requested`, `main_menu_requested` | `RunFlow` (pausa, resultados) | `Game` |
| `level_intro` (mensajes de bienvenida; también la llegada del jefe) | `RunSystems`, `BossEncounter` | `LevelIntro` |
| `cursor_requested` | pausa, armería, panel de depuración | `MouseCapture` |
| `player_stamina_changed` | `StaminaComponent` | `StaminaBar` |
| `player_health_changed` | `Player` | `HealthBar` |
| `player_died` | `Player` | `ResultsPanel`, `RunRecorder` |
| `enemy_damaged` | `DamageReporter` | `DamageNumbers` |
| `enemy_died` (el propio enemigo) | `Enemy` | `LootDropper` (y más adelante el Archivo) |
| `breakable_broken` (sus datos y dónde) | `Breakable` | `LootDropper` |
| `pickup_collected` | `PickupField` (y las tragaperras y el premio del jefe) | `ExperienceComponent` (la recompensa `experience`), `WalletComponent` (`gold`), los `PickupEffect` (`heal`, `magnet`, `bomb`) |
| `player_xp_changed` | `Player` | `XpBar` |
| `player_gold_changed` | `Player` | `GoldCounter` |
| `difficulty_changed` (la stat `difficulty` del jugador) | `Player` | `DifficultyCounter`, `LootDropper` |
| `player_item_changed` (arma o runa y su nivel; 0 = quitada) | `Player` (de `WeaponInventory.weapon_changed` y `RuneInventory.rune_changed`) | `LoadoutBar` |
| `player_slots_changed` (ranuras abiertas) | `Player` | `LoadoutBar` |
| `run_clock_changed` (segundos, prórroga; negativo = sin ronda) | `WaveDirector` | `RunClock`, `RunRecorder`, `BossAltar` (al empezar la prórroga, pide el jefe) |
| `player_leveled_up` | `Player` | `LevelUpController` |
| `interaction_prompt_changed` | `Interactor` | `InteractionPrompt` |
| `slot_spun`, `slot_resolved` | `SlotMachine` | `SlotPanel`, `SlowMotion` (el jackpot) |
| `chest_opened`, `chest_denied` (coste) | `Chest` | los cofres cuentan los abiertos; `ChestPanel` (el aviso de que falta oro) |
| `item_revealed` (objeto pasivo y segundos del revelado) | `Chest`, `BossEncounter` (el premio) | `ChestPanel` |
| `player_passive_changed` (objeto pasivo y copias; 0 = quitado) | `Player` (de `PassiveInventory.item_changed`) | `PassiveBar` |
| `announced` (clave, valores y color de un texto breve) | `PickupField` (los power-ups con `PickupData.announce_key`), `UpgradeAllEffect` | `AnnouncementFeed` |
| `upgrade_choice_requested` (cuántas elecciones) | `UpgradeChoiceEffect` | `LevelUpController` |
| `time_stop_changed` (si el tiempo está parado) | `EnemySwarm` | `TimeStopFilter` |
| `boss_key_collected` | `BossKey` | `BossEncounter` |
| `boss_keys_changed` (llaves que lleva y que hacen falta) | `BossEncounter` | `BossAltar`, `BossKeyCounter` |
| `boss_summon_requested` (dónde y si es forzado) | `BossAltar` | `BossEncounter` |
| `boss_spawned` (nombre del jefe) | `BossEncounter` | `BossAltar`, `BossBar`, `BossKeyCounter` |
| `boss_health_changed`, `boss_shouted` | `BossEncounter` (de su `Boss`) | `BossBar` |
| `boss_defeated` (título de la victoria, segundos y premio por rapidez) | `BossEncounter` | `ResultsPanel`, `RunRecorder`, `BossBar` |

## Capas de física (`core/physics_layers.gd`)

| Capa | Qué hay | Quién la mira |
|---|---|---|
| 1 `world` | Geometría, mesas y pedestales | Jugador, enemigos, cámara, sensores |
| 2 `player` | Cuerpo del jugador | Enemigos, teletransportes |
| 3 `enemy` | Cuerpos de enemigos y muñecos | Jugador, enemigos |
| 4 `player_hurtbox` | Donde el jugador recibe daño | Hitbox de enemigos y trampas, armas y proyectiles de enemigos |
| 5 `enemy_hurtbox` | Donde los enemigos reciben daño | Armas del jugador (hitbox, proyectiles y búsqueda de objetivos) |
| 6 `player_hitbox` | Tajos del jugador | — (ellos miran la 5) |
| 7 `enemy_hitbox` | Contacto de enemigos y trampas | — (miran la 4) |
| 8 `pickup` | — (los recogibles no usan física: los mueve `PickupField`) | — |
| 9 `interactable` | Armería, invocador… | `Interactor` del jugador |

## Recetas: cómo añadir…

- **Un arma:**
  1. Crea un `.tres` `WeaponData` en `data/weapons/` con su icono (`assets/textures/icons/weapons/`, SVG).
  2. Si ataca de otra forma, crea su escena con un script que herede de `Weapon` e implemente `_fire()`, en `systems/combat/weapons/<arma>/`.
  3. Traduce su nombre y descripción.

  Aparece sola en la armería.
- **Una runa:** crea un `.tres` `RuneData` en `data/runes/` con su icono (`assets/textures/icons/runes/`), un `StatModifierSet` por nivel (sobre stats que el jugador tenga) y traduce su nombre y descripción. Aparece sola en la armería.
- **Un objeto pasivo:** crea un `.tres` `PassiveItemData` en `data/items/` con su rareza, su icono (`assets/textures/icons/items/`, SVG redondo) y sus modificadores (sobre stats que el jugador tenga), y traduce su nombre y descripción. Sale solo en los cofres.
- **Un rompible:** crea su `BreakableData` en `data/breakables/` (recogible, valor, trozos, dispersión) y su escena con raíz `Breakable` (modelo e `Interactable` con su aviso); añádelo como `ScatterEntry` al `BreakableScatter` del nivel.
- **Un enemigo:**
  1. Crea un `.tres` `EnemyData` en `data/enemies/`.
  2. Si no reutiliza la escena de otro, crea la suya en `entities/enemies/<enemigo>/`, con raíz `Enemy`, como `swarmer.tscn`.
  3. Si ataca a distancia, dale `keep_distance` y un arma en `weapons`: un `WeaponData` en `data/enemies/weapons/` cuya escena busque `player_hurtbox` (como `shooter_gun.tscn`).
  4. Traduce su nombre y descripción (y los de su arma).
  5. Para que salga en las oleadas, añádelo como `WaveEnemy` en el `WaveData`; para probarlo, pon otro invocador en la zona de combate.
- **Un jefe:**
  1. Crea su escena en `entities/enemies/<jefe>/` con raíz `Boss` (como `ent_trainer.tscn`) y sus ataques como nodos hijos: `LeapAttack`, `ChargeAttack`, `SummonAttack` o un script nuevo que herede de `BossAttack`.
  2. Crea su `EnemyData` en `data/enemies/` y su `BossData` en `data/bosses/` (llaves, mensajes, victoria, escalado y premio).
  3. En el nivel: pon el `BossData` en `RunSystems.boss`, el altar como pieza del mapa (o en la escena) y reparte sus llaves con un `BreakableScatter`.
  4. Traduce su nombre, su descripción, sus gritos y los textos del altar y de la victoria.
- **Una stat:** añade un `@export_range` en el Resource de datos que toque (`MovementData`, `OffenseData`, `WeaponStats`, `EnemyStats`…), pon su valor en el `.tres` y su fila `STAT_<NOMBRE>` en `data/i18n/strings.csv`. Un test exige la traducción.
- **Un estado de movimiento:** crea un script en `entities/player/movement/states/` que herede de `MovementState` y añade un nodo hijo de `Movement` en `player.tscn` con su acción, prioridad y reglas.
- **Un personaje:** crea un `.tres` `CharacterData` en `data/characters/` con sus diferencias de stats, color, arma inicial, pasiva y piezas del modelo (`attachments`: escena de `assets/models/props/`, punto y colocación) y sus textos. Una pasiva que suba una stat por nivel es solo una escena con `LevelStatPassive`; otra distinta es un script que herede de `CharacterPassive` (`_activated()`, y `_set_bonus()` para su modificador) con su escena en `entities/player/characters/passives/`. Para probarlo, pon otro pedestal en la zona de combate.
- **Un interactuable:** crea una escena con un `Interactable` (capa 9, `prompt_key`) y conecta su `interacted`. Para que destelle, añádele un `InteractHint` con su modelo y los materiales de `vfx/juice/interact_hint/`.
- **Un recogible** (cura, imán…):
  1. Crea un `.tres` `PickupData` en `data/pickups/` con su escena (raíz `Pickup`) y su `reward`.
  2. Haz que el sistema que lo usa escuche `EventBus.pickup_collected` con esa recompensa.
  3. Suéltalo con `PickupField.drop()`, normalmente desde `LootDropper`.
- **Un efecto de juice:** escucha una señal (del componente o del `EventBus`) y no cambies el gameplay. Si hay muchos a la vez, usa `NodePool`.
- **Un texto de interfaz:** pon la clave en `data/i18n/strings.csv` (es y en) y la clave como texto del control, o `tr()`.
- **Una sección de depuración:** crea un `DebugSection` como hijo de las secciones del panel.
