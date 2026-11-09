# Decisiones

Registro de decisiones de arquitectura y de proyecto: fecha, decisión y por qué.
Las nuevas van al final. Si una decisión se revierte, se añade otra que lo diga; las antiguas no se borran.

## 2026-11-06 · Nombre definitivo «Bro Guild» y temática medieval con humor
- **Decisión:** el juego se llama **Bro Guild** (`config/name` en `project.godot`). La temática pasa de casino-neón a **medieval con humor moderno**, sin realismo. Las apuestas siguen siendo el corazón del juego, pero sin casino; las **tragaperras repartidas por el mapa se quedan**. El repo de GitHub (`DuskTower`) y la carpeta local (`dusk-tower`) conservan el nombre anterior.
- **Por qué:** decisión del diseñador. El GDD aún usa nombres de casino (fichas, La Banca, crupier, mesa…); se adaptarán en una sesión de diseño aparte y están listados como pendientes en `GDD.md` §11.

## 2026-11-06 · Identificadores de código según la mecánica, no la temática
- **Decisión:** en código, señales y datos se nombra la mecánica (`currency`, `gamble`, `streak`, `pot`, `boss`…), nunca el disfraz temático (`chips`, `la_banca`…). Los nombres visibles para el jugador viven en las traducciones (`data/i18n/`).
- **Por qué:** la temática ya ha cambiado una vez. Así un cambio de nombres o de ambientación solo toca textos y assets, no código ni `.tres`.

## 2026-11-06 · Carpeta de datos de usuario fija: `bro_guild`
- **Decisión:** `application/config/use_custom_user_dir=true` y `custom_user_dir_name="bro_guild"`. En Windows, `user://` queda en `%APPDATA%/bro_guild`.
- **Por qué:** por defecto Godot deriva la carpeta de `config/name`; si el título cambiara, guardados, ajustes y remapeos quedarían huérfanos.

## 2026-11-06 · Arranque del repositorio
- **Decisión:** `main` parte del commit inicial que GitHub creó con el `README.md`. Todo lo demás entra por PR desde ramas `feat/…`, `fix/…`, `refactor/…` o `docs/…`. Los commits de este repo usan el email noreply de GitHub (`git config user.email` local).
- **Por qué:** cumple la regla «nunca commits directos a `main`» sin excepciones y no expone el email personal en un repo público.

## 2026-11-06 · Estructura: `addons/`, `tools/` y dónde van los Resources
- **Decisión:** a la estructura de `CLAUDE.md` se añaden `addons/` (solo GUT) y `tools/` (validación por terminal). El script que define un Resource (`class_name MovementData`) vive con su feature o sistema (`entities/player/`, `systems/combat/`…); las instancias de balance (`.tres`) viven en `data/`. Las carpetas vacías llevan `.gitkeep` hasta que reciben contenido.
- **Por qué:** «contenido = datos» pide un único sitio donde ajustar el balance (`data/`), y «lo de una feature va junto» pide que el código no se separe de su escena. Separar clase (código) e instancias (balance) cumple ambas.

## 2026-11-06 · Escena de pruebas: medidas provisionales del greybox
- **Decisión:** `levels/test_gym/test_gym.tscn` es la escena principal hasta que exista un menú. 1 unidad = 1 m. Piezas (CSG con colisión, capa 1 = mundo), casi todas con su medida en el nombre del nodo o en el de su grupo:
  - suelo de 100×100 m con rejilla de 1 m (líneas fuertes cada 5 m);
  - rampas de 10/20/30/40/50° hasta una terraza de 3 m (50° supera el `floor_max_angle` por defecto, 45°);
  - pendiente de 15° y 30 m para el slide;
  - bordes de 0,5 a 2,5 m (mantle);
  - chimeneas de 3 y 5 m de ancho y 8 m de alto, y un muro de 20×6 m (saltos en pared);
  - plataformas a 2 m con huecos de 3/5/7/9 m;
  - escalones flotantes cada 1,5 m hasta 7,5 m;
  - pista de 60 m entre dos pórticos.
- **Por qué:** el GDD no fija métricas y el jugador aún no existe. Un rango de valores permite calibrar el movimiento del Hito 1 sin rehacer la escena. Colores: suelo gris, rampas azules, paredes marrones, plataformas claras, marcas naranjas.

## 2026-11-06 · Rutas `res://` (no `uid://`) en `project.godot`
- **Decisión:** escena principal y autoloads se registran con ruta `res://`.
- **Por qué:** comprobado en 4.7.2: en un clon recién hecho (sin `.godot/`) una escena principal `uid://` aborta y un autoload `uid://` queda a `null` sin error de salida. Contrapartida: si se mueve uno de esos archivos, hay que actualizar la ruta a mano.

## 2026-11-06 · Validación por terminal: `tools/validate.sh`
- **Decisión:** un único script hace importación → carga de todos los scripts, escenas, recursos y shaders (`tools/ci/check_project.gd`) → smoke test de la escena principal → GUT, y falla si un paso sale con código ≠ 0 o si su salida contiene `ERROR`, `WARNING` o `Parse Error`. La ruta de Godot llega por la variable `GODOT`.
- **Por qué (comprobado en 4.7.2):**
  - Godot sale con 0 con errores de script en tiempo de ejecución, con scripts que no compilan durante `--import` o el smoke test, y con errores de shader.
  - Los warnings de GDScript solo se imprimen con el depurador local (`-d`), que hay que combinar con `--ignore-error-breaks` para que no se quede en bucle ante un error.
  - `--check-only` da «Identifier not found» en cualquier script que use un autoload, así que se sustituye por un runner que carga cada script sin caché.
  - GUT sale con 0 si un test no compila (lo ignora), si falta la caché de clases o si no se ejecuta nada; por eso se exige además el mensaje «All tests passed». Y solo falla un test por errores dentro de su cuerpo: el hook `tests/hooks/post_run.gd` hace fallar la ejecución por errores en `before_*`/`after_*` y por `push_warning`, respetando los esperados (`assert_push_error`).
  - Un asset que no se importa deja su `.import` con `valid=false` y Godot no lo reintenta: se busca esa marca tras cada importación.
  - Un shader no se compila al cargarlo, sino al pedir sus parámetros; el comprobador lo fuerza para que aparezcan sus errores.
  - Las escenas y los `.tres` que la escena principal no usa también se cargan, para que una referencia rota no pase desapercibida.

## 2026-11-06 · Warnings estrictos de GDScript
- **Decisión:** `untyped_declaration` = error; `unsafe_property_access`, `unsafe_method_access` y `unsafe_call_argument` = warning (la validación los rechaza igual). `unsafe_cast` queda desactivado. Los addons siguen excluidos (`directory_rules` por defecto; en 4.7 ya no existe `exclude_addons`).
- **Por qué:** hace cumplir el tipado estático de `CLAUDE.md` en vez de confiar en la disciplina. `unsafe_cast` avisaría en cada `as` sobre un `Variant`, que es justo la forma correcta de tipar.

## 2026-11-06 · Autoloads del Hito 0: `EventBus`, `Rng`, `RunState`
- **Decisión:** solo estos tres, en ese orden; `Audio` llegará con el sonido (Hito 4) y `Save` con el guardado (Hito 6). Sus scripts no llevan `class_name` (Godot da error si coincide con el nombre del autoload); se usan por su nombre global, que ya está tipado.
  - `EventBus`: solo señales tipadas; `@warning_ignore_start("unused_signal")` porque se emiten desde fuera.
  - `Rng`: un `RandomNumberGenerator` por sistema (`Rng.Stream`: LOOT, WAVES, GAMBLE, COMBAT, ENEMIES, COSMETIC). Semilla de cada uno = `hash("<semilla>:<NOMBRE>")`, así que añadir o reordenar generadores no cambia los existentes. COSMETIC existe para que los efectos no consuman azar de gameplay. La lógica pura recibe el generador por parámetro.
  - `RunState`: ciclo de vida de la partida (`start_run(seed)` siembra `Rng` y emite `run_started`; `end_run()`). Empezar con una partida en curso la termina antes (reinicio).
- **Por qué:** autoloads mínimos y sin lógica de gameplay (`CLAUDE.md` regla 5); generadores separados para que los bugs sean reproducibles (regla 8). Pendiente para cuando haya partidas: forzar la semilla desde la línea de comandos para reproducir un bug.

## 2026-11-06 · Tests con GUT 9.7.1, copiado en el repo
- **Decisión:** GUT 9.7.1 (rama `godot_4_7`) copiado tal cual en `addons/gut/` desde el zip oficial (sha256 `14969aa4…4086`), con el plugin activado para el panel del editor. Configuración en `.gutconfig.json`; tests en `tests/unit/`.
- **Por qué:** es la versión que GUT marca para Godot 4.7; la Asset Library solo ofrece la 9.6.1 (para 4.6). Copiado en el repo, cualquier clon tiene los tests sin pasos extra. Comprobado en 4.7.2: importación limpia y sin warnings con el tipado estricto. Para actualizarlo: rama propia, sustituir la carpeta entera y pasar `validate.sh`.

## 2026-11-06 · InputMap: una acción por tecla, con teclas físicas
- **Decisión:** 10 acciones del GDD §8: `move_forward/back/left/right` (WASD), `jump` (Espacio), `dash` (Shift), `slide` (Ctrl), `interact` (E), `show_stats` (Tab), `pause` (Esc). Teclas físicas, dispositivo «todos» y zona muerta 0,2 (lo mismo que escribe el editor de 4.7). Los nombres viven en `core/input_actions.gd` (`InputActions.JUMP`…); un test comprueba que coinciden en ambos sentidos con Project Settings.
- **Por qué:** una tecla con varios usos es una sola acción que cada estado interpreta (Espacio = salto, doble salto, salto en pared, dash-jump, slide-jump y mantle; Ctrl = slide o caída rápida; E = interactuar o, manteniendo, cobrar). Dos acciones en la misma tecla se descuadrarían al remapear. Mirar con el ratón no es una acción (`InputEventMouseMotion`, sensibilidad en datos). Acciones de depuración, cartas, reroll o pactos se añadirán con su sistema.

## 2026-11-06 · Capas de física con nombre
- **Decisión:** 1 `world`, 2 `player`, 3 `enemy`, 4 `player_hurtbox`, 5 `enemy_hurtbox`, 6 `player_hitbox`, 7 `enemy_hitbox`, 8 `pickup`, 9 `interactable`. Constantes y nombres en `core/physics_layers.gd`; un test comprueba que coinciden con Project Settings. Convención: **hitbox hace daño, hurtbox lo recibe**.
- **Por qué:** separar cuerpo y hurtbox permite cambiar la forma que recibe daño (la hurtbox baja del slide) sin tocar la colisión con el mundo. Previsto para el rendimiento con 300+ enemigos: los enemigos no chocarán entre sí (su máscara no incluirá `enemy`; la separación se hará en el steering) y la cámara solo chocará con `world`; se decide del todo en el Hito 2.

## 2026-11-07 · Nombre confirmado; carpeta y repo renombrados
- **Decisión:** el nombre definitivo es **Bro Guild** (descartado «Bro Code»). La carpeta local pasa de `dusk-tower` a `bro-guild` y el repo de GitHub, de `DuskTower` a `BroGuild` (GitHub redirige las URL antiguas).
- **Por qué:** decisión del diseñador. Sustituye a la parte de la entrada del 2026-11-06 que decía que el repo y la carpeta conservaban el nombre anterior. El proyecto hay que volver a añadirlo en el gestor de proyectos de Godot (Importar → `D:/Documentos/bro-guild/project.godot`).

## 2026-11-08 · Versiones: etiquetas por hito y ramas fusionadas
- **Decisión:** al cerrar un hito, su último commit en `main` lleva una etiqueta anotada `hito-N` (`hito-0` = `880208e`). GitHub borra la rama de un PR al fusionarlo (`delete_branch_on_merge`); `feat/cimientos` se borró a mano por la misma razón.
- **Por qué:** el diseñador prefiere no borrar nada que no esté guardado. Una rama fusionada es obsoleta: sus commits siguen en `main` y GitHub la puede restaurar desde su PR. Las etiquetas dejan cada versión jugable a mano (`git switch --detach hito-0`).

## 2026-11-08 · Stats: StatBlock, StatModifier y StatsComponent
- **Decisión:**
  - Valor final = (base + Σ planos) × (1 + Σ porcentajes) × Π multiplicadores, limitado a [mínimo, máximo] y, si la stat es entera, redondeado al más cercano (x,5 sube). Se recalcula solo al cambiar sus modificadores y se guarda; `stat_changed(stat, value, previous)` solo se emite si el valor cambia.
  - Todo `float`/`int` con `@export` o `@export_range` de un Resource de datos es una stat, con su valor como base. El `@export_range` es también el límite en juego (`or_greater`/`or_less` lo abren; con `radians_as_degrees` se pasa a radianes). Los `int` son stats enteras; enums, bools y curvas no son stats.
  - Cada modificador se aplica con su origen (la mejora, el pacto, el rasgo…) y se quita por origen; una vez aplicado es inmutable. Una stat que no existe es un error, para cazar erratas en los `.tres`.
  - `StatsComponent` junta las stats de los Resources de datos de una entidad y mantiene una copia resuelta de cada uno: el juego lee `move.run_speed` con tipo, y el `.tres` original no cambia nunca.
- **Por qué:** añadir una stat es añadir un `@export` al Resource, sin registrarla en ningún otro sitio, y mejoras y personajes la modifican por su nombre desde sus `.tres`. Las copias resueltas evitan una lista de constantes que repita los nombres y dan autocompletado y comprobación de tipos. Usar el rango del inspector como límite evita una segunda fuente de verdad e impide, por ejemplo, que una maldición deje una velocidad en negativo.

## 2026-11-08 · Valores de datos solo en el `.tres`
- **Decisión:** los scripts de Resources de datos (`CameraData`, `MovementData`…) declaran los campos con valor neutro (0, `false` o `null`), y los valores de verdad van en su `.tres` de `data/`. Ese valor neutro no se cambia nunca.
- **Por qué:** Godot no guarda en el `.tres` las propiedades que coinciden con el valor por defecto del script (comprobado en 4.7.2). Si el script trae valores de balance, el `.tres` sale casi vacío, el valor real queda escondido en el código y cambiar un valor por defecto cambiaría el juego sin tocar `data/`. Con valores neutros, todo lo ajustado es distinto del defecto y siempre queda escrito en el `.tres`.

## 2026-11-08 · Interpolación de física
- **Decisión:** `physics/common/physics_interpolation = true` y `physics_jitter_fix = 0` (la documentación de Godot pide quitar la corrección de tirones al interpolar). Lo que se mueve en `_process` (cámaras) va con `physics_interpolation_mode = OFF` y sigue `get_global_transform_interpolated()` de su objetivo. Al teletransportar algo (aparecer, reaparecer), `reset_physics_interpolation()`.
- **Por qué:** la física va a 60 ticks por segundo. Sin interpolar, en monitores de 144 Hz el jugador y la cámara se moverían a saltos.

## 2026-11-08 · Cámara en tercera persona
- **Decisión:** `CameraRig` (`entities/player/camera/`) es una escena propia con `top_level`. Sigue a su `target` a la altura del pivote, gira con el ratón y se aleja con el nivel: distancia = `base_distance` × `distance_by_level(nivel)`. La curva va del nivel 1 al 100 y, pasado el último punto, se queda en su valor. Un `SpringArm3D` con una esfera de 0,25 m que solo choca con `world` la acerca en vez de atravesar paredes y suelo. Valores de partida en `data/player/camera.tres`: 5 m a nivel 1 y ×1,4 lineal hasta 7 m a nivel 100 (2 cm por nivel); pivote a 1,6 m; FOV 75°; sensibilidad 0,15 °/px; inclinación entre −70° y 35°, empezando en −15°.
- **Convenciones:** los ángulos de los datos se guardan en radianes con `radians_as_degrees` (el inspector muestra grados, como en los nodos de Godot). La sensibilidad va en grados por píxel y usa `screen_relative`, que no cambia con el escalado de la ventana. Hasta el Hito 2 el nivel se cambia en `CameraRig.level` desde el inspector remoto; luego lo pondrá la progresión.
- **Por qué:** una escena propia permite reutilizar la cámara y probarla sola. Una curva multiplicadora permite cambiar la distancia base sin rehacer la forma.

## 2026-11-08 · Captura del ratón
- **Decisión:** `MouseCapture` (`ui/mouse_capture.gd`) va en la escena principal: captura el ratón al empezar, Esc (`pause`) lo suelta y un clic lo vuelve a capturar. El clic no es una acción del InputMap, igual que mirar con el ratón. Es provisional: el menú de pausa se quedará con Esc.
- **Por qué:** el modo del ratón es de toda la partida (menús, ruleta de nivel, pausa), no del jugador. Además, así los tests que instancian al jugador no capturan el ratón.

## 2026-11-08 · Tests de integración
- **Decisión:** los tests que instancian escenas van en `tests/integration/`, con la misma ruta que el código (`entities/player/player.tscn` → `tests/integration/entities/player/test_player_scene.gd`). `tests/unit/` queda para lógica pura.
- **Por qué:** separar lo que depende de escenas deja claro qué se rompe cuando cambia una escena y qué cuando cambia la lógica.

## 2026-11-08 · Máquina de estados y reglas de las acciones
- **Decisión:**
  - `StateMachine` y `State` (`core/state_machine/`) son genéricos, para el jugador y para futuras IAs. Cada estado es un nodo hijo con su script y declara en el inspector cómo participa en las acciones: `trigger_action`, `priority`, `committed`, `cancels_committed` e `interrupts`.
  - La máquina guarda las acciones pedidas (`request`) en orden y aplica las reglas del GDD:
    - gana la primera que puede ejecutarse, y como mucho entra una por tick;
    - entre estados de la misma acción entra el de mayor prioridad que pueda;
    - un estado comprometido solo lo cancelan los estados que cancelan (el dash) o los que lo listan en `interrupts` (el slide-jump al slide);
    - lo pulsado durante un estado comprometido se guarda si le quedan `committed_end_buffer` segundos o menos y si no, se descarta;
    - lo que todavía no puede entrar espera `buffer_time` segundos (el jump buffer).
  - Los dos tiempos salen de `movement.tres` (`input_buffer_time` 0,12 s y `action_end_buffer_time` 0,1 s), y `Player` los pasa a la máquina en cada tick.
  - Se puede volver a entrar en el estado activo (dash sobre dash). Los estados no cambian de estado en `enter`/`exit`, solo en `physics_update`.
- **Jugador:**
  - `player.gd` solo monta el `MovementContext` (cuerpo, stats resueltas y estados neutros Suelo/Aire), avanza la máquina y llama a `move_and_slide()`, el único sitio donde se hace.
  - `PlayerInput` reenvía las pulsaciones de las acciones que activan algún estado, así que un estado nuevo con su acción no obliga a tocarlo.
  - Los estados heredan de `MovementState` (contexto tipado, `settle()` para volver a Suelo o Aire, `apply_gravity()`).
- **Gravedad:** sale del salto. Con `jump_height` y `jump_time_to_apex`, la gravedad es 2h/t² y la velocidad de salto 2h/t, con un tope de caída `max_fall_speed`. Valores de partida: 2 m en 0,35 s (≈ 32,7 m/s² y 11,4 m/s) y caída máxima de 40 m/s.
- **Por qué:** las reglas viven en un solo sitio y cada mecánica solo declara sus datos. Un estado nuevo (un gancho, por ejemplo) es un nodo con su script, sin tocar los demás. Definir el salto por altura y tiempo permite ajustar el feel con dos números que se entienden; la gravedad cuadra sola.

## 2026-11-08 · Arrays tipados con la propia clase
- **Decisión:** `State.interrupts` es `Array[Node]`, no `Array[State]`.
- **Por qué:** en 4.7.2, un array tipado con la propia clase del script (`Array[State]` dentro de `State`) hace que el script se referencie a sí mismo, y Godot avisa al salir de que `state.gd` sigue en uso y hay instancias perdidas. `validate.sh` lo detecta. Se tipa con la clase nativa y se documenta qué contiene.

## 2026-11-08 · Correr, saltar y control aéreo
- **Decisión:**
  - **Dirección pedida:** WASD (`Input.get_vector`) girado según el giro horizontal de la cámara (`CameraRig.get_yaw()`). `Player` la deja cada tick en `MovementContext.wish_direction`, así que los estados no leen el Input y se pueden probar sin teclado.
  - **Suelo:** acelera hacia `wish × run_speed` con `ground_acceleration` y frena con `ground_deceleration` al soltar.
  - **Aire:** acelera hacia la dirección pedida con `air_acceleration`, apuntando a la mayor de `run_speed` y la velocidad que ya se lleva. Así se puede girar y frenar (pidiendo lo contrario), pero no se pierde de golpe el impulso por encima de la carrera, y tampoco se gana velocidad haciendo zigzag en el aire. Sin dirección, frena con `air_deceleration` (0 de partida: se conserva todo).
  - **Salto:** `JumpState` da `jump_velocity()` al entrar y pasa al aire en el mismo tick. Entra si hay suelo o queda coyote time: `coyote_time` arranca al dejar el suelo sin saltar y lo gasta el salto. El jump buffer es el `input_buffer_time` de la máquina.
  - **Modelo:** `BodyFacing` gira el modelo (no el cuerpo físico) hacia la velocidad horizontal a `turn_speed`.
  - **Valores de partida:** carrera 9 m/s (aceleración 60 m/s², frenada 50 m/s²), aire 30 m/s², coyote 0,12 s y giro 720 °/s. Al integrar por ticks, el salto de 2 m llega a ≈ 2,09 m.
- **`StatsComponent`** registra sus datos en `_enter_tree` en vez de en `_ready`. Así cualquier nodo los lee en su `_ready` sin depender del orden de los hermanos.
- **Por qué:** el GDD pide carrera rápida, mucho control aéreo y que el impulso no se pierda de golpe; esa regla del aire deja que el dash y el dash-jump conserven su velocidad sin trucos aparte. Todos los números son stats, así que mejoras y personajes pueden cambiarlos.

## 2026-11-09 · Panel de depuración
- **Decisión:**
  - **Panel:** `DebugPanel` (`ui/debug/`) es un `CanvasLayer` que F3 (acción `toggle_debug`) muestra u oculta. Solo existe en builds de depuración y solo se actualiza mientras se ve.
  - **Secciones:** cada bloque es un `DebugSection`, hijo de `%Sections`, que recibe al jugador en `setup()` y se refresca cada frame. Un sistema nuevo añade su sección sin tocar el panel. De partida hay tres:
    - movimiento (estado, velocidades, suelo, coyote);
    - cámara (deslizador de nivel hasta el último punto de la curva);
    - stats: todas las del jugador con su valor y su base, y botones ±10 % que aplican un `StatModifier` en nombre del panel, como haría una mejora; «reset» los quita.
  - **Textos:** muestra nombres internos sin traducir (excepción a la regla 14).
  - **Foco:** sus botones y deslizadores no cogen el foco, para que Espacio siga saltando.
  - **Accesos nuevos:** `Player.context` es público para leer; `StatsComponent` y `StatBlock` dan `get_stats()` y `get_base()`.
- **Por qué:** el diseñador quiere que todas las stats sean mejorables, como en Megabonk (GDD §5). La sección de stats lo deja probar ya, antes de que exista el sistema de mejoras (Hito 3), y cualquier stat nueva aparece en el panel sin tocarlo. Un modificador en % sobre una base 0 (p. ej. `air_deceleration`) no cambia nada; para esas stats, las mejoras usarán modificadores planos.

## 2026-11-09 · Menú de pausa
- **Decisión:**
  - **Apertura:** Esc (`pause`) abre `PauseMenu` (`ui/menus/pause/`). Pausa el árbol (`get_tree().paused`), pide el cursor y deja el foco en «Continuar» para manejarlo también con el teclado. Funciona en pausa con `process_mode = ALWAYS`.
  - **Izquierda:** título y botones Continuar, Opciones (desactivado hasta que tenga función), Reintentar (por ahora recarga la escena; en el Hito 2 pasará por `RunState`) y Salir.
  - **Derecha:** un panel fijo con `StatsView`: todas las stats del jugador agrupadas como en sus datos, con nombre traducido, unidad (sacada del `@export_range`) y scroll. Las que difieren de su base salen resaltadas, con la base al lado. Encabezados y filas salen solos de los datos: una stat nueva solo necesita su traducción.
  - **Cierre:** al cerrar se suelta el foco; si no, Espacio pulsaría el botón en vez de saltar. «Continuar» no estaba en el pedido: se añadió porque es lo normal en una pausa (Esc también cierra).
- **Por qué:** lo pidió el diseñador, con las stats visibles como en Megabonk. `StatsView` es reutilizable para la pantalla de stats (Tab) del Hito 3.

## 2026-11-09 · Ratón con un solo dueño (sustituye a «Captura del ratón»)
- **Decisión:** `MouseCapture` captura el ratón salvo mientras alguna interfaz pida el cursor con `EventBus.cursor_requested(requester, wants_cursor)`. Lo piden el menú de pausa y el panel de depuración (F3), así que ya no hace falta Esc para pulsar los botones del panel. Se conecta en `_enter_tree` para no perder peticiones y olvida a quien pidió el cursor y ya no existe. Desaparecen «Esc suelta el ratón» y «clic para recapturar».
- **Por qué:** cada interfaz futura (ruleta de nivel, cofres, tragaperras) solo emite la señal; el modo del ratón se decide en un único sitio.

## 2026-11-09 · Textos traducibles y Theme global
- **Decisión:**
  - **Textos:** viven en `data/i18n/strings.csv` (`keys,es,en`).
    - Godot genera los `.translation` al importar (están en `.gitignore`; un clon nuevo necesita `--import`, que ya hace `validate.sh`). Sin el idioma del sistema, se usa el inglés.
    - En las escenas, el texto de un control es la clave y Godot lo traduce solo. Las etiquetas de números desactivan la autotraducción.
    - Las stats se traducen como `STAT_<NOMBRE>` y sus grupos como `STAT_GROUP_<GRUPO>`, por eso los `@export_group` de los datos usan identificadores (`run`, `jump`, `air`, `input`). Un test exige que cada stat del jugador tenga su nombre en todos los idiomas.
  - **Estilo:** `ui/theme/main_theme.tres` (`gui/theme/custom`) tiene una paleta pizarra oscura con acentos dorados y la fuente por defecto de Godot en negrita (`FontVariation`, sin assets externos). Lleva variaciones de tipo para títulos, encabezados, filas de stats y espaciados de menú (`ScreenMargin`, `MenuList`, `StatList`), y estilos de botón, panel y barra de scroll.
  - **Panel de depuración:** usa su propio tema compacto (`ui/debug/debug_theme.tres`) y no se traduce.
  - **Fondo de los menús:** `vfx/shaders/screen_blur.gdshader` difumina y tiñe lo que hay detrás.
- **Por qué:** era la tarea siguiente del ROADMAP y el menú de pausa es la primera interfaz de verdad; así nace ya traducible y con estilo en un solo sitio.
- **Comprobado en 4.7.2:**
  - Los Resources traen sus propios grupos de propiedades (`Resource`), sin stats: el panel solo pone un encabezado cuando el grupo tiene alguna stat.
  - `String.num(9.0, 2)` devuelve `"9.0"`: `StatFormat` quita los ceros del final.
  - Un script lanzado con `-s` se compila antes que los autoloads: si nombra una clase que usa uno (p. ej. `PauseMenu` usa `EventBus`), esa clase no compila. En esos scripts hay que usar `call()`.

## 2026-11-09 · Stamina por cargas y HUD mínimo
- **Decisión:**
  - **Datos:** `StaminaData` (`data/player/stamina.tres`) es la segunda fuente de stats del jugador: `max_charges` (entera) y `recharge_time` por carga. Valores de partida del GDD: 3 cargas, 3 s por carga. Al ser stats, salen solas en el menú de pausa y en F3, y son mejorables (+1 carga con un modificador plano).
  - **Lógica:** `StaminaPool` es lógica pura con cargas fraccionarias (el ½ del salto en pared) y recarga continua; tiene un margen de 1e-6 para que los errores de coma flotante no impidan gastar una carga recién recargada.
  - **Componente:** `StaminaComponent` lo actualiza con las stats en cada tick, así que una mejora del máximo se nota al momento. Avisa con su señal `changed` y con `EventBus.player_stamina_changed` para la interfaz. Los estados de movimiento la encuentran en `MovementContext.stamina`; el coste de cada acción será una stat de esa acción.
  - **HUD:** `ui/hud/hud.tscn` con `StaminaBar`: una barra por carga (variación `ChargeBar` del Theme), la que recarga a medias. Se rehace si cambia el máximo. Escucha desde `_enter_tree`, así que recibe el primer aviso, que se emite en el `_ready` del jugador.
- **Por qué:** el GDD define la stamina por cargas que se regeneran y pide decidir cuándo gastar la última. La barra a medias deja ver cuánto falta. Separar sus datos de `MovementData` deja cada Resource con un solo tema y demuestra que el jugador admite varias fuentes de stats.

## 2026-11-09 · Dash, picado y doble salto
- **Decisión:**
  - **Dash** (`DashState`; en la escena: acción `dash`, comprometido, cancela):
    - va en la dirección pedida o, sin dirección, hacia donde mira la cámara (`MovementContext.view_forward`), a `dash_speed` durante `dash_duration`;
    - en el aire va recto, sin gravedad;
    - al terminar, la velocidad horizontal se queda en `dash_exit_speed` como mucho;
    - gasta `dash_cost`.
  - **Picado** (`DownDashState`; misma acción con prioridad 10, comprometido, cancela):
    - entra si estás en el aire, sin dirección y a menos de `down_dash_window` de un dash que empezó en el aire;
    - va hacia abajo a `down_dash_speed` durante `down_dash_duration`, o hasta tocar suelo;
    - gasta `down_dash_cost` además del dash.
    - El contexto guarda un reloj de juego (`elapsed`) y el momento y el lugar del último dash.
  - **Doble salto** (`DoubleJumpState`; acción `jump`, prioridad 10):
    - entra en el aire si no queda coyote time (con coyote, Espacio es el salto normal), quedan `air_jumps` y hay stamina;
    - sube `air_jump_height` con la gravedad del salto;
    - los saltos en el aire se recuperan al entrar en Suelo.
  - **Prioridades de la acción `jump`:** Jump 0 y doble salto 10. Quedan libres 20 (dash-jump), 30 (salto en pared) y 40 (mantle), para el orden del GDD.
  - **Valores de partida:**
    - dash: 28 m/s durante 0,2 s (≈ 5,6 m) y salida a 12 m/s; 1 dash en el aire por salto (`air_dashes`, añadido a petición del diseñador: los dashes totales los limita la stamina y los del aire, esta stat; el picado no cuenta);
    - picado: 30 m/s durante 0,2 s, con ventana de 0,3 s;
    - doble salto: 1 salto de 2 m;
    - todo cuesta 1 carga.
- **Por qué:** el GDD define las acciones, sus teclas y su coste; lo que no decía (el dash recto en el aire, la velocidad de salida, la duración y la ventana del picado, la altura del doble salto) queda en datos con valores razonables, para ajustarlo jugando o desde F3. Sin salida limitada, el control aéreo conservaría los 28 m/s del dash hasta aterrizar.
- **Tests:** con física real, cada `await wait_physics_frames(1)` en bucle avanza unos 2 ticks de GUT. Los tests comprueban en momentos con margen, no en ticks exactos.

## 2026-11-09 · Stats de combate y progresión
- **Decisión:**
  - Tres Resources de datos nuevos, fuentes de stats del jugador junto a movimiento y stamina:
    - `HealthData` (`core/components/health/`, genérico para jugador y enemigos): vida máxima, regeneración, defensa, esquiva (como mucho 90 %) y robo de vida;
    - `OffenseData` (`systems/combat/`): daño, crítico, daño crítico, velocidad de ataque, proyectiles extra, velocidad de proyectil, área, duración y retroceso;
    - `ProgressionData` (`systems/progression/`): experiencia y fichas ganadas, suerte y radio de recogida.
  - Instancias en `data/player/{health,offense,progression}.tres`. Las fuentes van en ese orden y luego movimiento y stamina, así que el menú de pausa muestra primero lo de combate.
  - **Unidades:** los porcentajes se guardan como porcentaje (100 = normal, 5 = 5 %). Así una mejora de «+10 % de daño» es PERCENT 0.1 y «+5 % de crítico», FLAT 5, y el menú los muestra tal cual.
  - **Valores de partida y fórmulas:** en la tabla «Stats del personaje» del GDD (§6).
  - **Sin lógica todavía:** no hay sistemas que las usen; vida, armas, experiencia y botín llegan en el Hito 2 y leerán estas stats. Las fórmulas se escriben en código cuando exista lo que las usa, para no dejar constantes de balance sueltas antes de tiempo.
- **Por qué:** el diseñador quiere las stats típicas de Megabonk o Vampire Survivors (daño, crítico, proyectiles, defensa, vida, multiplicador de experiencia…), mejorables y visibles desde ya. Al ser datos, una stat nueva es un `@export` más y su traducción.

## 2026-11-09 · Slide y slide-jump
- **Decisión:**
  - **Slide** (`SlideState`; acción `slide`, comprometido):
    - entra en el suelo a partir de `slide_min_speed` y conserva la velocidad que llevas;
    - cada tick suma el tirón de la pendiente (`slide_gravity` × la componente de la gravedad sobre el suelo: acelera cuesta abajo, frena cuesta arriba, nada en llano) y frena con `slide_friction`, sin pasar de `slide_max_speed`;
    - termina al soltar Ctrl (`MovementContext.slide_held`, que pone `Player` cada tick), al bajar de la velocidad mínima o al dejar el suelo (pasa al aire con coyote time).
  - **Dash → slide:** `DashState.slide` apunta al slide. Si al acabar el dash se mantiene Ctrl y el slide puede entrar, pasa a él sin el recorte de salida: el slide alarga el dash.
  - **Slide-jump** (`SlideJumpState`; acción `jump`, prioridad 5, `interrupts = [Slide]`): solo entra mientras interrumpe al slide (`interrupts.has(current)`, sin una referencia aparte). Da la velocidad del salto normal y conserva todo el impulso horizontal.
  - **Agachado:** `BodyCrouch` agacha el modelo, solo visual, con suavizado y los pies en el suelo, mientras el estado es uno de `crouch_states` (en la escena, el slide). La colisión no cambia; la hurtbox baja llegará con el combate.
  - **Valores de partida:** mínima 6 m/s, máxima 22 m/s, frenada 5 m/s² y tirón 30 m/s². Elegidos para que la rampa de 15° del gimnasio acelere (comprobado: de 9 a 14,6 m/s bajándola) y en llano el slide dure algo más de medio segundo desde la carrera.
- **Por qué:** el GDD pide un slide gratis que acelere cuesta abajo y frene cuesta arriba, el slide-jump con impulso y que dash → slide alargue el dash. Que el slide-jump use `interrupts` confirma que la regla «nada se cancela salvo con el dash» admite continuaciones diseñadas sin excepciones en la máquina.

## 2026-11-09 · Personajes: stats básicas y diferencias
- **Decisión:**
  - Las stats de `data/player/*.tres` son las básicas, comunes a todos los personajes.
  - Un personaje es un `CharacterData` (`entities/player/characters/`, instancias en `data/characters/`): un `StatModifierSet` (lista de `StatModifier` que se aplican y se quitan juntos) con las claves de traducción de su nombre y su descripción.
  - `StatBlock` tiene dos capas. Los modificadores de base (`add_base_modifier`) cambian la base con la misma fórmula; las mejoras (`add_modifier`) se calculan encima. `get_base` devuelve la base del personaje, así que el menú solo resalta lo que cambian las mejoras.
  - `StatsComponent.base_sets` aplica los personajes al entrar en el árbol, justo después de definir las stats; en la escena del jugador, el personaje base.
  - **Cambiar de personaje:** elegirlo será poner otro `CharacterData` en `base_sets` antes de crear al jugador. Los gimmicks que no sean stats (habilidades propias) se añadirán al `CharacterData` cuando lleguen.
  - Solo existe el personaje base, sin diferencias: los personajes concretos los decide el diseñador. Un test comprueba que cada personaje de `data/characters/` tiene su nombre y su descripción traducidos y que solo toca stats que existen.
- **Por qué:** el diseñador quiere unas stats básicas y que cada personaje varíe un poco según su gimmick. Como diferencias sobre una base común, un personaje nuevo es un `.tres` con 2-3 modificadores, y cambiar una stat básica afecta a todos.

## 2026-11-09 · Dash-jump
- **Decisión:**
  - **Ventana:** `DashState` apunta en el contexto la dirección del dash y, al acabar (no si otro dash o el picado lo cancelan), el momento (`dash_end_time`). `MovementContext.is_dash_jump_open()` dice si la ventana está abierta: el dash fue en el suelo y no han pasado más de `dash_jump_window` segundos.
  - **Estado** (`DashJumpState`; acción `jump`, prioridad 20, `interrupts = [Slide]`):
    - entra con la ventana abierta y stamina para `dash_jump_cost`;
    - da la velocidad del dash en su dirección y sube `dash_jump_height`; el control aéreo conserva esa velocidad;
    - gasta la ventana.
  - **Casos que salen solos de las reglas:**
    - pulsar en los últimos 0,1 s del dash lo guarda hasta que acaba;
    - en dash → slide funciona dentro de la ventana;
    - sin stamina, entra el salto normal.
  - **Aviso visual:** `DashJumpCue` enseña un aro dorado en los pies mientras `is_dash_jump_open()`. Solo lee el contexto.
  - **Valores de partida:** ventana 0,15 s, altura 2 m y coste 1 carga. Con el dash a 28 m/s, el salto mide ≈ 21 m (medido en el gimnasio), de sobra para el hueco de 9 m. Se ajusta en los datos.
- **Por qué:** el GDD pide el dash-jump justo tras el dash, con ventana corta y aviso visual, y que conserve la velocidad del dash. La ventana se mide desde el final del dash para que encaje con la regla de que nada interrumpe al dash.

## 2026-11-09 · Girar durante el slide
- **Decisión:** el slide se curva con WASD. Cada tick, `SlideState.steer()` gira la parte horizontal de la velocidad hacia la dirección pedida, como mucho `slide_turn_speed` (180 °/s de partida), sin cambiar su rapidez ni la parte vertical. Sin dirección, sigue recto. Pedir hacia atrás lo da la vuelta poco a poco; la frenada sigue siendo la del slide.
- **Por qué:** lo pidió el diseñador: moverse mientras desliza, como en Deadlock, y no ir siempre hacia delante. Girar sin perder velocidad mantiene el slide como forma rápida de moverse y de esquivar.

## 2026-11-09 · Plan: movimiento, combate y menús
- **Decisión:**
  - **Orden:** el diseñador decide terminar el movimiento y después el combate (Hito 2, en la zona de pruebas), y luego los menús y el flujo de partida (Hito 3). Los mapas de los tres niveles iniciales (el Brosque, la Torre del Mago y la Mazmorra) van después del juice (Hito 6).
  - **Movimiento pendiente:** cancelar el dash con un slide (solo en el suelo, con la velocidad del dash), salto en pared al estilo Deadlock, caída rápida, mantle y sensación de velocidad.
  - **Combate:**
    - personajes iniciales: Guerrero (espada), Mago (bastón de mago) y Pícaro (daga);
    - armas automáticas con 4 ranuras de armas y 4 de runas, nivel máximo 5 (valores por defecto, en datos);
    - subir de nivel = elegir 1 de 3;
    - runas: Fuerza, Amplitud, Prisa, Vigor y Multiplicidad (cantidad de proyectiles, que también afecta a la espada; el nombre es provisional).
  - **Menús:**
    - menú principal: Jugar, Archivo y Abandonar;
    - selección de personaje con panel de info al pasar el ratón y modelo 3D en el centro;
    - selección de nivel en el lugar del panel de info;
    - Archivo con desbloqueos por conseguir o derrotar.
  - **Arquitectura prevista:**
    - `WeaponData` y `RuneData` con un `StatModifierSet` por nivel;
    - `EnemyData` con `HealthData`;
    - `LevelData`;
    - un catálogo `data/content.tres` del que salen los menús, el Archivo y las opciones al subir de nivel;
    - `Save` para los desbloqueos;
    - escena raíz `Game` con el flujo de pantallas.
- **Por qué:** lo pidió el diseñador. Todo lo nuevo es contenido en datos sobre los sistemas que ya existen (stats con dos capas, conjuntos de modificadores), así que añadir un arma, una runa, un enemigo o un nivel será crear su `.tres`.
