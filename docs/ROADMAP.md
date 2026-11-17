# ROADMAP

- La tarea actual es la **primera casilla sin marcar**. Claude la marca `[x]` al terminarla.
- Cada hito acaba con algo jugable. **Hecho** = validación sin errores + lo he probado y me convence.
- Si una tarea es grande, se parte aquí en subtareas antes de empezarla.
- Los nombres que vienen del casino (bote, La Banca, mesa…) están pendientes de adaptar a la temática medieval (GDD §11). Las fichas ya son oro.

## Hito 0 — Cimientos
- [x] Proyecto Godot 4.7 (Forward+) con `.gitignore` y `.gitattributes`; git y GitHub funcionando (push y PR)
- [x] Comandos de Godot verificados y anotados en `CLAUDE.md`
- [x] Estructura de carpetas de `CLAUDE.md`
- [x] Autoloads tipados: `EventBus`, `RunState`, `Rng` (con semilla)
- [x] InputMap con todas las acciones del GDD y capas de física con nombre
- [x] GUT instalado con un test de ejemplo que pase
- [x] Escena de pruebas en gris: suelo, rampas, bordes, paredes y plataformas
- [x] `docs/DECISIONES.md` con las primeras decisiones

## Hito 1 — Movimiento (si no se siente bien, no se avanza)
- [x] `StatBlock` + `StatModifier` (con tests): los parámetros de movimiento se leen como stats, para que mejoras y personajes los modifiquen
- [x] Jugador (`CharacterBody3D`) y cámara en tercera persona con ratón (distancia que crece con el nivel, curva en datos; interpolación de física activada); Esc suelta el ratón (aún sin menú de pausa)
- [x] Máquina de estados + `data/player/movement.tres` (gana la primera acción; nada se cancela salvo con el dash)
- [x] Correr, saltar, coyote time, jump buffer y control aéreo
- [x] Panel de depuración con F3 (velocidad, estado, suelo/coyote y nivel de la cámara; cada sistema nuevo añade lo suyo), con las stats modificables como haría una mejora
- [x] Textos traducibles (CSV en `data/i18n/`, español e inglés) y `Theme` global, antes del primer HUD
- [x] Menú de pausa (Esc): continuar, opciones (aún sin función), reintentar y salir, con un panel fijo de todas las stats del jugador (con scroll)
- [x] Stamina por cargas + HUD mínimo
- [x] Dash (suelo y aire), picado (doble Shift en el aire sin dirección) y doble salto
- [x] Slide con pendientes y slide-jump
- [x] Dash-jump con ventana y aviso visual
- [x] Cancelar el dash con un slide (solo en el suelo), que sigue con la velocidad del dash
- [x] Salto en pared al estilo Deadlock (el primero gratis; encadenados sin tocar suelo, media carga)
- [x] Caída rápida (Ctrl en el aire)
- [x] Mantle (subir bordes a media altura; con Ctrl sale deslizando)
- [x] Sensación de velocidad: FOV dinámico, estela de dash, líneas de velocidad
- [x] Toque Deadlock: arranque progresivo, sprint tras unos segundos, velocidad mínima para el dash en el suelo, caída rápida con doble Ctrl (sustituye al picado de doble Shift) y slides encadenados al aterrizar con Ctrl

## Hito 2 — Combate en la zona de pruebas
- [x] Stats de combate y progresión del personaje en datos (vida, regeneración, defensa, esquiva, robo de vida, daño, crítico, velocidad de ataque, proyectiles, área, duración, retroceso, experiencia, fichas, suerte, radio de recogida), visibles en la pausa y en F3
- [x] Personajes en datos: stats básicas comunes y cada personaje con sus diferencias (`data/characters/`; de momento solo el personaje base)
- [x] Vida, daño y muerte: `HealthComponent`, `HitboxComponent`, `HurtboxComponent` con las fórmulas del GDD (defensa, esquiva, crítico); hurtbox baja en el slide
- [x] Armas: `WeaponData` (stats del arma y mejoras por nivel) y base de arma automática (cadencia y objetivo); la espada (cuerpo a cuerpo)
- [x] Zona de práctica de combate en el gimnasio: teletransporte de ida y vuelta, muñecos (cuentan como enemigos, no mueren ni se mueven, muestran su DPS) y armería para equipar, quitar y cambiar de nivel las armas; números de daño (blancos, críticos amarillos y más grandes)
- [x] Enemigo cuerpo a cuerpo con `EnemyData`, steering simple y pooling; barra de vida en el HUD (la del jugador, hecha con «Vida, daño y muerte»); invocador de enemigos en la zona de práctica
- [x] Director de oleadas en la zona de pruebas (curva en datos) y escena de estrés con 300 y 500 enemigos y fps medidos (se repite al cerrar cada hito). Primera medición: 300 a 130 fps y 500 a 57 fps (RX 6800 XT, ver DECISIONES)
- [x] Experiencia: gemas atraídas por el radio de recogida, niveles con curva en datos (la cámara ya se aleja con el nivel); barra de experiencia y nivel arriba en el HUD
- [x] Subir de nivel: elegir 1 de 3 entre armas y runas nuevas o mejorarlas; 4 ranuras de armas y 4 de runas, nivel máximo 5
- [x] Runas: `RuneData` (modificadores por nivel) y las 5 iniciales: Fuerza (daño), Amplitud (área), Prisa (velocidad de ataque), Vigor (vida) y Multiplicidad (cantidad de proyectiles); también en la armería de práctica. Se hizo antes que «Subir de nivel», para que la elección tenga opciones
- [x] Bastón de mago (proyectiles que explotan al contacto con daño en área) y daga (proyectil rápido a un objetivo; sus mejoras pueden subir su rebote, que da todo el daño al enemigo más cercano dentro de una distancia máxima)
- [x] Segundo enemigo: el tirador, que se queda a distancia y dispara bolas de fuego lentas. Los enemigos pueden llevar armas desde sus datos (`EnemyData.weapons`), con el mismo sistema que las del jugador
- [x] Oro (antes «fichas»): cada enemigo lo suelta y vuela solo hacia el jugador al matarlo, sin pasar por encima; contador en el HUD
- [x] Gemas de experiencia por niveles: las que están juntas se funden en una de otro color con su valor sumado
- [x] Élites: cada enemigo tiene un % de salir élite (más grande, pega más, más vida y suelta más experiencia y oro)
- [x] Dificultad: ronda normal de 10 minutos; enemigos más fuertes con el tiempo y, desde el minuto 10, muy duros (hace falta buena build para aguantar); curva de experiencia del jugador ajustada a esa duración; reloj de la ronda en el HUD
- [x] Muerte, resultados y reinicio rápido: al morir, pantalla de resultados (tiempo, nivel, enemigos y élites derrotados, oro y daño) y «Reintentar» (R) en unos 0,2 s; HUD de experiencia, nivel, oro y tiempo
- [x] Personajes iniciales: Guerrero (espada), Mago (bastón) y Pícaro (daga), cada uno con sus diferencias de stats, su rasgo de movimiento y su habilidad pasiva (Aguante, Eco arcano y Letal); pedestales en la zona de combate para cambiar de personaje

## Hito 3 — Menús, flujo de partida y el Brosque
- [x] Aspecto de cada personaje: su color y sus piezas en el modelo (Guerrero: espada y escudo; Mago: bastón y sombrero; Pícaro: dos dagas), en el jugador y en los pedestales. Las piezas son assets reutilizables (`assets/models/props/`)
- [x] HUD de armas y runas: ranuras con su icono y su nivel; al empezar, 2 de cada abiertas y 2 bloqueadas (se desbloquearán más adelante). Las cartas de subir de nivel también llevan el icono
- [x] Opciones básicas (desde la pausa): volumen (general, música y efectos), resolución, pantalla completa y VSync, guardadas entre partidas (`Save`)
- [x] Escena raíz `Game` con el flujo de pantallas; `RunState` guarda personaje, nivel y semilla; «Salir» de la pausa vuelve al menú
- [x] Menú principal: Jugar, Opciones, Archivo (desactivado hasta su tarea) y Abandonar (cierra el juego). Jugar lleva a la selección de personaje y nivel
- [x] El Brosque v1 (gimnasio en el bosque, **generado al cargar, distinto en cada partida**): claro con pesas de piedra y bancos de tronco (y bienvenida en el HUD al empezar); paredes invisibles con un bosque grande detrás que tapa el borde (los enemigos salen solo dentro); mesetas con rampa; bosque low-poly de colores (generado, con MultiMesh). Los sistemas de partida van en `RunSystems`, común a todos los niveles. Jugar lo carga y las oleadas empiezan solas
- [x] Rompibles: calaveras (experiencia) y bolsitas (oro) repartidas por el nivel en sitios distintos cada partida (30 y 20 en el Brosque), que se rompen con E
- [x] Dificultad como stat del jugador: sube sola 1 por minuto y con objetos o runas; las oleadas (cantidad, enemigos, élites, vida y daño) van según ella y calaveras y bolsitas dan más con ella; indicador en el HUD
- [x] Recogibles del suelo: imán (atrae toda la experiencia), comida (cura un 25 %) y bomba (mata a los enemigos cercanos), que salen a veces de rompibles (3, 3 y 2 %) y élites (10, 15 y 10 %)
- [x] Probabilidad de botín (stat, 0,5 %; élites ×8 y rompibles ×12) que tira de una tabla ponderada (`WeightedTable`) de power-ups; nuevo power-up: bebida energética (más velocidad, velocidad de ataque y daño 10 s)
- [x] Tragaperras (GDD §5.3; adelantadas del Hito 7): 4 en el Brosque (claro y mesetas); 5 tiradas y revientan; coste en oro que sube con la dificultad y con cada uso; moneda, corazón, estrella y calavera con premio de pareja y de trío (oro, cura, mejoras gratis, maldición de −vida máxima u oleada de élites); rodillos en el HUD sin pausar y cámara lenta en el jackpot
- [x] Rarezas de las mejoras (común gris, rara verde, improbable azul, de leyenda amarilla y mítica roja) en datos: cada subida de nivel es una mejora tirada que toca de 1 a todas las stats del arma o runa, más fuerte cuanto más rara; borde de la carta del color de la rareza. Nivel máximo: armas 10, runas 20
- [x] Suerte (stat): cada entrada de una tabla ponderada gana peso con ella según su `luck_scaling`; las rarezas altas suben más (con 100, la mítica pasa del 1 al 3,7 %). La usan las cartas de subir de nivel y las mejoras gratis
- [x] Cofres y objetos pasivos: cofres por el nivel (5 en el suelo y 2 en mesetas del Brosque) que cuestan oro (sube con la dificultad y con cada cofre abierto) y dan un objeto pasivo con rareza (la Suerte ayuda), revelado en el HUD sin pausar; 15 objetos de cultura bro que se apilan, a la vista bajo las runas
- [x] Jefe del Brosque, el Ent-renador (un árbol entrenador personal): altar al borde del claro que lo invoca con las 3 tarjetas de socio del mapa (las justas) o se activa solo al minuto 10; ataques Burpee (salto con onda), Series (embestidas) y Bro-tes (refuerzos) y rabia por debajo de la mitad de su vida; su barra y sus gritos en el HUD; vencerlo da oro × rapidez (×3 al empezar, ×1 desde el minuto 10) y un objeto de rareza alta, y pasa el nivel (pantalla de victoria «¡Brosque superado!»)
- [x] Selección de personaje: lista a la izquierda, modelo 3D en el centro, a la derecha (al pasar el ratón) nombre, stats, arma principal y habilidad pasiva
- [x] Selección de nivel (sustituye al panel de info al elegir personaje): el Brosque; la Torre del Mago y la Mazmorra salen como «próximamente» hasta que existan
- [ ] Catálogo de contenido (`data/content.tres`) y `Save` con desbloqueos persistentes
- [ ] Archivo: personajes, armas, runas y enemigos; se desbloquean al conseguirlos o al derrotar al enemigo («???» mientras tanto)

## Hito 4 — Apuestas v1
- [ ] GDD adaptado a la temática medieval (pendientes de §11)
- [ ] Ruleta de nivel: las 3 opciones de subir de nivel giran como rodillos; reroll de coste creciente
- [ ] Doble o nada sobre la opción elegida
- [ ] Más armas y runas en `.tres` (3 con sinergia de movimiento)
- [ ] Pantalla de estadísticas (Tab), reutilizando la lista de stats de la pausa

## Hito 5 — Juice y look
- [ ] Entorno según la dirección visual del GDD (luz, glow y tonemapping)
- [ ] Materiales con color propio por tipo de enemigo y rareza
- [ ] Hit-stop, screen shake y flash (los números de daño llegaron en el Hito 2)
- [ ] Partículas: muertes, monedas, cofres, impactos
- [ ] Sonidos con tono creciente y UI animada
- [ ] Rendimiento: 300+ enemigos a 60 fps

## Hito 6 — Niveles
- [ ] El Brosque: más detalle (decoración, variedad del suelo, props de gimnasio, sonido ambiente); la v1 llegó en el Hito 3
- [ ] La Torre del Mago
- [ ] La Mazmorra

## Hito 7 — La mesa de juego
- [ ] Racha y bote (niveles, multiplicador, cobrar, perder al ser golpeado)
- [ ] Pactos de la Banca
- [ ] Élites con afijos que sueltan cofres

## Hito 8 — Cierre de partida y meta
- [ ] Jefes de la Torre del Mago y la Mazmorra (el del Brosque llega en el Hito 3)
- [ ] ¿Cobrar o Doblar? y mesas siguientes
- [ ] Resumen de partida
- [ ] Desbloqueos (personajes, armas, ventajas) y condiciones para conseguirlos
- [ ] Más opciones (sensibilidad, remapeo)

## Backlog (sin orden)
- Raíles/ziplines y plataformas de salto
- Más armas, enemigos y personajes con movimiento propio
- Nuevas arenas; generación procedural
- Retos diarios con semilla compartida
- Soporte de mando
- Actualizar a Godot 4.8 cuando sea estable
