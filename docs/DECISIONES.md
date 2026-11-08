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
