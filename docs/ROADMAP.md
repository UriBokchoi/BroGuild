# ROADMAP

- La tarea actual es la **primera casilla sin marcar**. Claude la marca `[x]` al terminarla.
- Cada hito acaba con algo jugable. **Hecho** = validación sin errores + lo he probado y me convence.
- Si una tarea es grande, se parte aquí en subtareas antes de empezarla.
- Los nombres del casino ya están adaptados a la temática medieval (GDD §11): botín, el Gremio, el tahúr, el torneo y «¿Retirarse o seguir?».

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
- [x] Menú principal: Jugar, Opciones, Récords, Archivo (desactivado hasta su tarea) y Abandonar (cierra el juego). Jugar lleva a la selección de personaje y nivel
- [x] El Brosque v1 (gimnasio en el bosque, **generado al cargar, distinto en cada partida**): claro con pesas de piedra y bancos de tronco (y bienvenida en el HUD al empezar); paredes invisibles con un bosque grande detrás que tapa el borde (los enemigos salen solo dentro); mesetas con rampa; bosque low-poly de colores (generado, con MultiMesh). Los sistemas de partida van en `RunSystems`, común a todos los niveles. Jugar lo carga y las oleadas empiezan solas
- [x] Rompibles: calaveras (experiencia) y bolsitas (oro) repartidas por el nivel en sitios distintos cada partida (30 y 20 en el Brosque), que se rompen con E
- [x] Dificultad como stat del jugador: sube sola 1 por minuto y con objetos o runas; las oleadas (cantidad, enemigos, élites, vida y daño) van según ella y calaveras y bolsitas dan más con ella; indicador en el HUD
- [x] Recogibles del suelo: imán (atrae toda la experiencia), comida (cura un 25 %) y bomba (mata a los enemigos cercanos), que salen a veces de rompibles (3, 3 y 2 %) y élites (10, 15 y 10 %)
- [x] Probabilidad de botín (stat, 0,5 %; élites ×8 y rompibles ×12) que tira de una tabla ponderada (`WeightedTable`) de power-ups; nuevo power-up: bebida energética (más velocidad, velocidad de ataque y daño 10 s)
- [x] Tragaperras (GDD §5.3; adelantadas del Hito 7): 4 en el Brosque (claro y mesetas); 5 tiradas y revientan; coste en oro que sube con la dificultad y con cada uso; moneda, corazón, estrella y calavera con premio de pareja y de trío (oro, cura, mejoras gratis, maldición de −vida máxima u oleada de élites); rodillos en el HUD sin pausar y cámara lenta en el jackpot
- [x] Rarezas de las mejoras (común gris, rara verde, improbable azul, de leyenda amarilla y mítica roja) en datos: cada subida de nivel es una mejora tirada que toca de 1 a todas las stats del arma o runa, más fuerte cuanto más rara; borde de la carta del color de la rareza. Nivel máximo: armas 10, runas 20
- [x] Suerte (stat): cada entrada de una tabla ponderada gana peso con ella según su `luck_scaling`; las rarezas altas suben más (con 100, la mítica pasa del 1 al 3,7 %). La usan las cartas de subir de nivel y las mejoras gratis
- [x] Cofres y objetos pasivos: cofres por el nivel (5 en el suelo y 2 en mesetas del Brosque) que cuestan oro (sube con la dificultad y con cada cofre abierto) y dan un objeto pasivo con rareza (la Suerte ayuda), revelado en el HUD sin pausar; 15 objetos de cultura bro que se apilan, a la vista bajo las runas
- [x] Jefe del Brosque, el Ent-renador (un árbol entrenador personal): altar (hoy portal) al borde del claro que lo invoca con las 3 tarjetas de socio del mapa (las justas) o se activa solo al minuto 10; ataques Burpee (salto con onda), Series (embestidas) y Bro-tes (refuerzos) y rabia por debajo de la mitad de su vida; su barra y sus gritos en el HUD; vencerlo da oro × rapidez (×3 al empezar, ×1 desde el minuto 10) y un objeto de rareza alta, y pasa el nivel (pantalla de victoria «¡Brosque superado!»)
- [x] Taberna en el centro de la pared norte del Brosque (no se entra): cura la mitad de la vida por oro, cada vez más cara y más con la dificultad. Charquitos de agua con una flor por el suelo, de decorado
- [x] Círculo de setas (2 por el Brosque): elegir 1 de 3 objetos pasivos (la Suerte ayuda), una vez cada uno. 8 objetos medievales más (23 en total)
- [x] Récords: las 20 mejores partidas en local, por enemigos derrotados, con personaje, tiempo, nivel, mapa y resultado; en el menú principal y, al acabar, el puesto en los resultados
- [x] Selección de personaje: lista a la izquierda, modelo 3D en el centro, a la derecha (al pasar el ratón) nombre, stats, arma principal y habilidad pasiva
- [x] Selección de nivel (sustituye al panel de info al elegir personaje): el Brosque; la Torre del Mago y la Mazmorra salen como «próximamente» hasta que existan
- [x] Catálogo de contenido (`data/content.tres`) y `Save` con lo descubierto entre partidas (los desbloqueos de personajes y armas, en el Hito 8)
- [x] Archivo: personajes, armas, runas, objetos y enemigos; se descubren al jugar con el personaje, al conseguirlos o al derrotar al enemigo («?» y una pista mientras tanto); ficha con lo que hace cada uno

## Hito 4 — Apuestas v1
- [x] GDD adaptado a la temática medieval: botín, el Gremio, el tahúr, el torneo, «¿Retirarse o seguir?» y luz de antorchas
- [x] Ruleta de nivel: las cartas de mejora giran por las rarezas y se paran una tras otra (clic o Espacio para pararlas); «volver a tirar» por oro, 10 y ×1,5 cada vez en la partida
- [x] Doble o nada sobre la opción elegida: 50 % de subirla una rareza (más con Suerte) o perderla; la carta gira entre las dos rarezas
- [x] 3 mejoras con sinergia de movimiento, como objetos pasivos: Zapatillas en llamas (rastro de fuego al deslizarte), Bocina de estadio (onda al hacer dash) y Cinturón de campeón (explosión al caer)
- [x] Más armas en `.tres`: hacha arrojadiza (va y vuelve atravesando), nube de colonia (aura de pulsos) y martillo de guerra (cae sobre el grupo más denso)
- [x] Pantalla de estadísticas (Tab, mientras se mantiene y sin pausar), reutilizando la lista de stats de la pausa

## Hito 5 — Juice y look
- [x] Entorno según la dirección visual del GDD: sol de media tarde, cielo azul con horizonte cálido, niebla dorada, ACES, glow, SSAO y hierba con manchas (compartido por el Brosque y el menú)
- [x] Color propio por tipo de enemigo y por rareza: cada enemigo con el suyo (también en sus datos, `EnemyData.color`, para sus efectos), élites con brillo y rarezas iguales en cartas, cofres, HUD y Archivo
- [x] Feedback al golpear y al recibir: números de daño (Hito 2), temblor de pantalla, borde rojo y destello blanco (tras el Hito 3). Hit-stop descartado: el diseñador no quiere parones al golpear
- [x] Balanceo al andar y correr: el cuerpo rebota a cada paso y se mece, más cuanto más rápido vas
- [x] Partículas: humo al morir (del color del enemigo), chispas al golpear, restos al romper, destellos al abrir un cofre y polvo de las ondas de suelo (las monedas ya saltaban como botín)
- [x] Alcance de la nube de colonia: un dibujo en el suelo que gira despacio (como en Megabonk), en vez de la burbuja
- [x] Límite del mapa: un muro que solo se ve al acercarte
- [x] Power-ups con su efecto al cogerlos: la bomba, una explosión nuclear (destello, hongo y onda); el imán, la comida, la bebida energética y el reloj de arena, el suyo
- [x] Enemigos que aparecen con una animación: salen del suelo creciendo, con polvo (los jefes, más despacio y desde más hondo)
- [x] Hojitas que caen de las copas de los árboles al meterte dentro
- [x] Polvo pequeño a cada paso (con el aviso de pasos del balanceo). Lo último del hito, a petición del diseñador
- [x] UI animada: botones que crecen y se hunden, paneles que aparecen, contadores y casillas que saltan, experiencia que se llena suave y vida con rastro de lo perdido (los sonidos llegaron tras el Hito 3)
- [x] Rendimiento: 300+ enemigos a 60 fps (medido: 300 a 120 fps de media en el equipo de desarrollo)

## Hito 5b — Pulido tras las pruebas (2026-11-23)
Lo que salió al probar la partida; va antes que el resto de hitos.
- [x] Opciones: la resolución que se ve es la de verdad (en pantalla completa, la de la pantalla)
- [x] El tejado de la taberna choca (se podía atravesar subiendo encima)
- [x] Los jefes no hablan: fuera sus gritos
- [x] Barras de jefe más pequeñas y claras: nombre a la izquierda, vida en números («4530 / 5000») a la derecha y una barra fina
- [x] Barra de experiencia abajo, fina y minimalista
- [x] Ver tus stats al subir de nivel y al elegir un objeto
- [x] Elegir nivel: su objetivo (en el Brosque, vencer al Ent-renador) y una descripción con su lore
- [x] `docs/LORE.md`: el lore del juego en un archivo para leerlo y cambiarlo a mano (los textos del juego, con su clave en `data/i18n/strings.csv`, se apuntan ahí)
- [x] Hacha arrojadiza: gira tumbada (en horizontal) y es más grande (×1,7 y su filo, 1,2 m); crece con el área
- [x] Mejoras con el valor actual y el que queda (p. ej. «Daño 18 → 22»), para ver cuánto se gana: cartas de subir de nivel, de elegir objeto y revelado de cofres

## Hito 5c — Pulido tras las pruebas (2) (2026-11-24)
Lo que salió en la segunda tanda de pruebas; va antes que el resto.
- [x] Elegir nivel: primero se elige el nivel (clic), debajo su objetivo y su lore, y abajo «Jugar» encima de «Volver»
- [x] Estadísticas: solo las que se pueden mejorar (fuera las fijas), para que se vean las importantes
- [x] El rastro de fuego del slide escala con las stats del jugador
- [x] Optimizar: el ordenador va a tope jugando. Límite de FPS (de serie, 60), enemigos y objetos redondos con menos polígonos, bosque por trozos (un 83 % menos de triángulos)

## Hito 5d — Pedidos tras las pruebas (3) (2026-11-24)
- [x] Pesas de piedra que se activan como los santuarios de Megabonk: quedarse cerca 5 s (de base) da a elegir una de 3 mejoras de stats, con rarezas
- [x] Subir de nivel: con «Quedármela» y «Doble o nada» a la vista, el clic derecho deshace la elección y deja escoger otra carta
- [x] Árboles alrededor de los trolls de piedra (ahora están en un claro pelado)

## Hito 6 — Niveles
- [x] El Brosque más grande: paredes a 110 m (antes 80), casi el doble de área, con más piezas, rompibles y árboles en proporción
- [ ] El Brosque: más detalle (decoración, variedad del suelo, props de gimnasio, sonido ambiente); la v1 llegó en el Hito 3
- [x] Brosque: el miniboss Trolleador Cara a los 4:30 (barra propia bajo la del jefe, porrazo en área y salto) y dos trolls de piedra fuera de la pared este (guiño a El Hobbit); los jefes ya trepan por las pesas
- [ ] La Torre del Mago
- [ ] La Mazmorra
- [ ] Tiers de nivel: cada nivel tiene 3 (Brosque tier 1, tier 2 y tier 3). El tier 2 se abre al pasar el tier 1 y es el mismo nivel, pero distinto. Lo detallará el diseñador más adelante
- [ ] Élites con afijos (rápido, vampiro, explosivo…), solo en tier 2 o más; con más probabilidad de soltar cofre que un élite normal

## Hito 7 — El torneo
- [x] Élites: todos tienen una probabilidad de soltar un cofre
- [x] Apuntar: mantener el clic derecho apunta con el ratón (las armas van a por lo que miras); el clic central fija al jefe como objetivo
- [x] Racha como power-up de 30 s, sin botín: matar seguido sube el multiplicador de oro, experiencia y Suerte; un golpe lo baja
- [x] Pactos del Gremio: un heraldo aparece cada 1000 enemigos derrotados y ofrece pactos (una maldición a cambio de un premio), que se pueden rechazar
- [x] Pactos: valores fijos y «volver a tirar» por oro (10, ×1,5 por uso en la partida), que trae otros pactos
- [x] Objetos con efectos además de stats: veneno con probabilidad al golpear, y más del estilo (Pre-entreno caducado: veneno; Cable pelado: rayo; Spray de frío: frena)

## Hito 8 — Cierre de partida y meta
- [x] Portal del jefe en lugar del altar: el jefe se invoca en él y, tras vencerlo, hay que cruzarlo para pasar el nivel. Al vencerlo, un texto lo explica y una flecha amarilla señala el portal unos 3 s
- [x] Pasado el minuto 10, con el jefe vencido, morir también cuenta como victoria
- [ ] Jefes de la Torre del Mago y la Mazmorra (el del Brosque llega en el Hito 3)
- [ ] ¿Retirarse o seguir? y torneos siguientes
- [ ] Resumen de partida
- [ ] Desbloqueos (personajes, armas, ventajas) y condiciones para conseguirlos
- [ ] Más opciones (sensibilidad, remapeo)

## Mantenimiento (siempre)
- [x] Repaso del código para que se lea como escrito a mano: comentarios que expliquen el porqué en lo que no se entiende solo, comentarios de documentación más cortos y sin jerga (primera pasada: las cabeceras de clase de 97 scripts; la norma, en CLAUDE.md)

## Orden de trabajo acordado (2026-11-23)
1. Hito 5b (pulido tras las pruebas).
2. Del Hito 8: el portal del jefe y la victoria al morir tras el minuto 10.
3. Del Hito 5: colonia, límite del mapa, power-ups y aparición de enemigos.
4. Hito 5c (segunda tanda de pruebas): elegir nivel, stats importantes, fuego del slide y optimizar.
5. Del Hito 5: las hojas de los árboles.
6. Del Hito 6: el Brosque más grande.
7. Del Hito 7: objetos con efectos.
8. Polvo de los pasos (Hito 5) y repaso del código.
9. Hito 5d: pesas que activan mejoras, deshacer la elección con clic derecho y árboles en los trolls.
10. Hito 7 (2026-11-24): cofres de élite, apuntar y fijar al jefe, racha como power-up y pactos con el heraldo. Los afijos y los tiers, más adelante (Hito 6).

## Backlog (sin orden)
- Física de la horda: con 180 esbirros apretados, la física se lleva unos 4–6 ms por tick (el rumbo del enjambre, 1 ms; el resto, el motor). Mirar con el profiler del editor si hiciera falta (formas más simples, menos contactos)
- Raíles/ziplines y plataformas de salto
- Más armas, enemigos y personajes con movimiento propio
- Nuevas arenas; generación procedural
- Retos diarios con semilla compartida
- Soporte de mando
- Actualizar a Godot 4.8 cuando sea estable
