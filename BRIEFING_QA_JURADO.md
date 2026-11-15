# ATLANIA — Briefing para preguntas del jurado

Documento interno del equipo. Todas las cifras de aquí salen del código (`engine/asi_engine.py`) y del dataset generado (`frontend/public/data/analogs.json`). Si un juez pregunta algo que no está aquí, la regla es: **decir lo que sí sabemos, admitir lo que no, y explicar cómo lo resolveríamos.**

---

## 1. Lo que los 4 deben poder decir de memoria (30 segundos)

> ATLANIA es un atlas que compara sitios de la Tierra con 6 lugares reales de la Luna y Marte. Para cada sitio cruzamos clima de **NASA POWER** y relieve del **Copernicus DEM GLO-90**, y calculamos un índice de similitud de 0 a 100 en 5 dimensiones: topografía, geología, térmica, hidrología/hielo y entorno subterráneo. Además de dar el puntaje, el sistema dice explícitamente **en qué falla la analogía** (gravedad, atmósfera, radiación). El resultado más fuerte para Ecuador: los **tubos de lava de Galápagos** son el segundo mejor análogo de los **60 sitios del catálogo**, comparados con los pozos de lava de **Mare Tranquillitatis** en la Luna (87.5/100).

---

## 2. Cifras clave (hoja de referencia rápida)

| Dato | Valor |
| :--- | :--- |
| Sitios terrestres evaluados | **60** (**12 en Ecuador**) |
| Blancos extraterrestres | **6** (3 Luna, 3 Marte) |
| Sitios con clima real de NASA POWER | **60 / 60** |
| Sitios con relieve real del DEM | **60 / 60** |
| Parámetros de NASA POWER | **7**: `T2M_MAX`, `T2M_MIN`, `PRECTOTCORR`, `WS10M`, `RH2M`, `ALLSKY_SFC_SW_DWN`, `PS` |
| Muestreo de relieve | 5 puntos (centro, N, S, E, O) separados 0.01° (~1.1 km) |
| Pruebas automatizadas | **270** tests en Python (`pytest`) + **53** tests en el frontend (`node --test`) |
| Mejor sitio global | Mauna Loa / HI-SEAS (EE. UU.) — 89.1 vs Mare Tranquillitatis |
| Mejor sitio de Ecuador | Galápagos Lava Tubes — **87.5** vs Mare Tranquillitatis (**#2 de 60**) |
| Gravedad | Tierra 9.81 · Marte 3.71 · Luna 1.62 m/s² |
| Presión | Tierra 101.3 kPa · Chimborazo (~5000 m) ~56 kPa · Marte ~0.65 kPa · Luna 0 |

### Los 6 blancos

| Blanco | Cuerpo | Por qué importa | Instrumento de referencia |
| :--- | :--- | :--- | :--- |
| Shackleton Crater | Luna | Polo sur, trampas frías con posible hielo (Artemis) | LRO Diviner + LOLA |
| Mare Tranquillitatis | Luna | Pozos que podrían dar acceso a tubos de lava (refugio para bases) | LRO LROC + Diviner |
| Mons Mouton | Luna | Meseta plana y muy iluminada, zona candidata de Artemis III | LRO LOLA + Diviner |
| Jezero Crater | Marte | Antiguo delta de lago, donde está Perseverance | Perseverance MEDA + MRO CRISM |
| Olympus Mons (flanco) | Marte | Volcán escudo, coladas de lava y posibles tubos | MGS MOLA + MRO HiRISE |
| Valles Marineris | Marte | Cañón tectónico profundo con sulfatos y paredes estratificadas | MRO HiRISE + CRISM |

### Los 12 sitios de Ecuador (resultados reales)

| Sitio | ASI | Mejor análogo de |
| :--- | :--- | :--- |
| Galápagos Lava Tubes (Santa Cruz / Isabela) | **87.5** | Mare Tranquillitatis (Luna) |
| Sierra Negra (Isabela) | 76.7 | Mare Tranquillitatis (Luna) |
| Quilotoa | 68.4 | Valles Marineris (Marte) |
| El Reventador | 63.1 | Valles Marineris (Marte) |
| Fernandina Caldera (Galápagos) | 62.2 | Mare Tranquillitatis (Luna) |
| El Altar (Laguna Amarilla) | 61.5 | Valles Marineris (Marte) |
| Alcedo Hydrothermal Caldera (Isabela) | 61.2 | Valles Marineris (Marte) |
| Antisana | 59.9 | Shackleton (Luna) |
| Chimborazo | 59.6 | Shackleton (Luna) |
| Cotopaxi | 59.5 | Mons Mouton (Luna) |
| Cayambe | 58.3 | Shackleton (Luna) |
| Sangay | 58.0 | Valles Marineris (Marte) |

---

## 3. Cómo funciona, explicado en dos niveles

### Versión simple (para jueces no técnicos)
1. Elegimos un punto en la Tierra.
2. Le pedimos a la NASA su clima promedio de décadas (temperatura, lluvia, viento, humedad, sol, presión).
3. Le pedimos a un modelo de elevación global la altura del punto y de 4 puntos vecinos, y con eso calculamos qué tan empinado y rugoso es el terreno.
4. Comparamos esos números con el perfil de cada lugar de la Luna y Marte.
5. Damos un puntaje de 0 a 100 y una lista de en qué se parece y en qué no.

### Versión técnica (para jueces ingenieros o científicos)
- **Clima:** endpoint de climatología puntual de NASA POWER (`community=RE`). Si viene el valor anual (`ANN`) se usa; si no, se promedian los 12 meses ponderando por días (año de 365 días). Si **un solo** parámetro falta o es inválido, se descarta toda la respuesta para no mezclar datos reales con datos de respaldo.
- **Reintentos:** 3 intentos con espera de 1 s y 2 s ante errores de red, `429` o `5xx`. Si falla, se usa un clima de respaldo **etiquetado como `fallback`** con el motivo.
- **Relieve:** Copernicus DEM GLO-90 a través de la API de elevación de Open-Meteo. 5 puntos en cruz separados 0.01°. Pendiente por diferencias centrales (corrigiendo la distancia este-oeste por `cos(latitud)`); rugosidad = desviación estándar de las 5 alturas.
- **Puntaje:** 5 dimensiones, cada una de 0 a 100, combinadas con pesos distintos según el blanco (ver sección 4).
- **Agrupamiento:** K-Means (k=3, semilla fija 42) y vecinos más cercanos (k=3) sobre las 5 dimensiones + elevación + pendiente, estandarizadas con z-score. Implementado sin librerías externas, determinista.
- **Frontend:** Next.js 16 + MapLibre GL (mapa 3D) + Three.js. Las rutas `/api/evaluate` (un punto) y `/api/evaluate-region` (grilla de 2×2 hasta 10×10 puntos) aplican la misma lógica del motor, reescrita en TypeScript, para responder en vivo.
- **Exportación:** JSON, GeoJSON (se abre directo en QGIS) y Markdown.

---

## 4. La fórmula del ASI (por si piden el detalle)

Similitud base entre dos valores: `sim(a, b, escala) = max(0, 1 − |a − b| / escala)`. Lineal y acotada: 1 si son iguales, 0 si la diferencia supera la escala.

| Dimensión | Cómo se calcula |
| :--- | :--- |
| Topografía | 50% pendiente (escala 30°) + 50% rugosidad |
| Geología | Jaccard ponderado sobre 5 tipos: basalto, regolito, sedimentario, evaporitas, impacto (`Σ min / Σ max`) |
| Térmica | 60% temperatura media (escala 100 °C) + 40% amplitud térmica (escala 100 °C) |
| Hidrología / hielo | 40% aridez + 40% hielo/permafrost + 20% historia acuosa. Aridez = `1 / (1 + lluvia mm/día)` |
| Subterráneo | 70% tubos de lava + 30% refugio |

**Pesos por blanco** (topografía, geología, térmica, hidrología, subterráneo). Siempre suman 1.0:

| Blanco | Topo | Geo | Térm | Hidro | Subt | Lógica |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Shackleton | .25 | .20 | .20 | **.30** | .05 | Lo que importa es el hielo en trampas frías |
| Mare Tranquillitatis | .15 | **.30** | .15 | .10 | **.30** | Basalto + tubos de lava como refugio |
| Mons Mouton | **.30** | .25 | .20 | .20 | .05 | Zona de aterrizaje: pendiente baja es crítica |
| Jezero | .20 | **.35** | .15 | .25 | .05 | Mineralogía del delta (arcillas, carbonatos) |
| Olympus Mons | .25 | **.30** | .15 | .10 | .20 | Basalto volcánico + tubos |
| Valles Marineris | .25 | **.30** | .15 | .20 | .10 | Estratigrafía y sulfatos en paredes empinadas |

En sondeos de coordenadas nuevas, la aridez se corrige por humedad: `aridez × (1 − 0.5 × humedad/100)`. Así un lugar húmedo y verde no parece un desierto solo porque llueve poco.

---

## 5. Qué es medido y qué es supuesto (lo más importante para no caer en trampas)

Un juez científico va a buscar exactamente esto. **Hay que decirlo con seguridad, no como disculpa.** Ser transparentes en esto es lo que pide el reto.

| Dato | Origen | Estado |
| :--- | :--- | :--- |
| Clima (7 parámetros) | NASA POWER, en vivo | **Medido** (60/60 sitios) |
| Elevación, pendiente, rugosidad | Copernicus DEM GLO-90, en vivo | **Medido** (60/60 sitios) |
| Geología, hielo, historia acuosa, tubos de lava, refugio de los 60 sitios del catálogo | Asignados por el equipo según literatura | **Supuesto documentado** (en el código se llaman "scenario priors") |
| Perfiles de la Luna y Marte | Constantes y rangos de misiones (LRO, MRO, Perseverance) | Referencia de literatura, no datos extraídos píxel a píxel |
| Geología en un punto nuevo (sondeo) | No se inventa | Se pone **en cero** (desconocido, no "ausente") |
| Satélites Landsat 9, Sentinel-1, Suomi NPP | Perfil recomendado de observación por sitio | **No entran al puntaje.** No procesamos imágenes todavía |
| Pesos de cada blanco | Criterio del equipo, justificado por misión | No aprendidos con datos (no existe una "verdad" de análogos para entrenar) |

**Frase modelo:** *"El clima y el relieve son datos reales de NASA y Copernicus para los 60 sitios. La geología del catálogo la asignamos nosotros a partir de la literatura y está marcada así en el código. En puntos nuevos no la inventamos: la dejamos en cero. Reemplazar eso con datos espectrales es nuestro siguiente sprint."*

---

## 6. Banco de preguntas difíciles, por categoría

### A. Ciencia y validez

**"¿Cómo validaron que el índice funciona?"**
No existe un conjunto oficial de "análogos correctos" para comparar. Nuestra validación es de coherencia: los sitios que la comunidad científica ya usa como análogos (Mauna Loa / HI-SEAS, Craters of the Moon, tubos de Timanfaya) salen arriba en el ranking sin haberlos forzado. Que Galápagos aparezca justo al lado de ellos es el hallazgo. El siguiente paso es validar en campo con universidades.

**"Chimborazo está a −8 °C y Shackleton a −183 °C. ¿Cómo pueden ser análogos?"**
No lo son en temperatura, y el sistema lo dice: la dimensión térmica da un puntaje muy bajo. El parecido viene de la pendiente, el terreno volcánico y el permafrost, que es lo que pesa para ese blanco. Por eso el ASI de Chimborazo es 59.6 y no 90. El índice no esconde la diferencia, la cuantifica.

**"¿Por qué esos pesos y no otros?"**
Cada peso sale del objetivo de la misión. Para Shackleton lo crítico es el hielo (30% hidrología). Para Mare Tranquillitatis, los tubos de lava como refugio (30% subterráneo). Para Mons Mouton, que es zona de aterrizaje, la pendiente (30% topografía). Están en el código, suman 1 y se pueden cambiar. No hicimos todavía un análisis de sensibilidad formal; es trabajo pendiente.

**"¿Por qué similitud lineal y no algo más sofisticado?"**
Porque es interpretable: cada punto del puntaje se puede explicar. En un hackathon preferimos un modelo que un científico pueda auditar a una caja negra. La estructura permite cambiar la función sin tocar el resto.

**"La Tierra tiene atmósfera, campo magnético y vida. ¿No invalida todo?"**
Ningún análogo terrestre es perfecto, y por eso cada evaluación trae una sección de "dónde se rompe la analogía": gravedad (9.81 contra 1.62 o 3.71), vacío o atmósfera de CO₂, radiación, y meteorización por agua y biología. Los análogos sirven para probar partes del problema (movilidad, perforación, navegación, instrumentos), no para simular el planeta entero.

**"¿La resolución de 1.1 km sirve para planear un rover?"**
No para planear la ruta del rover. Sirve para **filtrar regiones** candidatas a escala global. Para el detalle a escala de rover se necesita LiDAR o drones en campo. ATLANIA dice dónde vale la pena ir a medir.

**"¿El clima de POWER representa el interior de un tubo de lava?"**
No. POWER da la temperatura del aire a 2 m sobre la superficie. El código lo advierte explícitamente: no valida estabilidad térmica de cuevas ni el ciclo día-noche lunar. Para eso se necesitan sensores dentro de la cueva.

### B. Datos de la NASA

**"¿Qué datos de NASA usaron exactamente?"**
NASA POWER (Prediction Of Worldwide Energy Resources), endpoint de climatología puntual, 7 parámetros. Para los blancos, citamos productos de LRO (LOLA, Diviner, LROC), MRO (HiRISE, CRISM), MGS MOLA y Perseverance MEDA, con sus identificadores del PDS en el código.

**"El DEM es de la ESA, no de la NASA."**
Correcto: Copernicus DEM es de la ESA, y el reto lo lista como recurso oficial junto con los de NASA, CSA y JAXA. Lo elegimos por su cobertura global uniforme a 90 m.

**"¿Por qué no usaron imágenes de Landsat o Sentinel directamente?"**
Por tiempo del hackathon priorizamos datos que se pueden consultar por API en segundos para cualquier punto del mundo. Para cada sitio ya dejamos definido qué sensor serviría y para qué (Landsat óptico y térmico, Sentinel-1 radar), con sus limitaciones. Integrar esos datos es el siguiente sprint.

**"Los satélites en la portada, ¿los usan?"**
Son el perfil de observación recomendado para cada sitio. Hoy no procesamos sus imágenes ni entran al puntaje; decirlo así evita que parezca que exageramos.

**"¿Qué pasa si la API de NASA se cae durante la demo?"**
Reintenta 3 veces. Si sigue fallando, usa un clima de respaldo y lo marca como `fallback` con el motivo. Además, los 60 sitios ya están precalculados con datos reales, así que el catálogo funciona sin internet.

### C. Técnica e ingeniería

**"¿Qué construyeron ustedes y qué es librería?"**
Nuestro: el motor de puntaje completo, el muestreo y cálculo de pendiente del DEM, la lectura y validación de POWER, el K-Means y k-NN (sin scikit-learn), las rutas de la API, el mapa interactivo y la exportación. Librerías: Next.js, MapLibre GL, Three.js y `httpx` para las llamadas HTTP.

**"¿Por qué implementar K-Means a mano?"**
Para que el motor no dependa de librerías pesadas, sea reproducible (semilla fija, orden fijo por ID) y fácil de auditar. Son unas 70 líneas.

**"¿Cómo garantizan que el código es correcto?"**
270 tests en Python y 53 tests en el frontend (5 archivos de prueba), ejecutados en GitHub Actions en cada cambio. Validamos rangos de entrada (latitud, temperatura, humedad, presión) y rechazamos valores inválidos en vez de calcular con basura.

**"¿Escala a miles de puntos?"**
El cuello de botella son las llamadas a las APIs externas, no el cálculo. La búsqueda en grilla está limitada a 10×10 por eso. Para escalar: caché de resultados por coordenada y procesamiento en lote.

**"¿Por qué Python y TypeScript a la vez?"**
Python para el motor científico y generar el dataset; TypeScript para que la web responda sondeos en vivo sin un servidor Python aparte. La lógica es la misma en ambos.

### D. Impacto y viabilidad

**"¿Quién usaría esto realmente?"**
Equipos de robótica universitarios que necesitan dónde probar rovers, grupos de investigación planetaria, programas de entrenamiento de agencias y gobiernos locales que quieran posicionar sitios como laboratorios naturales.

**"¿Qué ganaría Ecuador?"**
Visibilidad científica para sitios que casi no aparecen en la literatura de análogos, potencial de campañas de investigación internacionales y turismo científico. Galápagos ya compite con los análogos clásicos en nuestro ranking.

**"Galápagos es área protegida. ¿Es realista hacer pruebas ahí?"**
Es una restricción real, y el sistema la lista en la sección de limitaciones del sitio. Por eso también aparece Sierra Negra y sitios continentales. Cualquier campaña requiere permisos del Parque Nacional; ATLANIA identifica el valor científico, no autoriza el acceso.

**"¿Cómo se sostiene después del hackathon?"**
Código abierto con licencia MIT, sin costos de APIs (POWER y Open-Meteo son gratuitas) y con hosting estático posible. El camino natural es alianza con universidades para validación en campo.

### E. Creatividad y competencia

**"¿Qué los hace distintos de otros mapas de análogos?"**
Tres cosas: (1) un puntaje cuantitativo y reproducible en vez de una lista curada, (2) poder evaluar **cualquier punto del planeta** en vivo, y (3) decir explícitamente dónde falla cada analogía. La mayoría de catálogos solo dicen "este sitio se parece a Marte".

**"¿No es solo un buscador de lugares fríos y secos?"**
No. Si fuera así, la Antártida ganaría todo. El ranking lo lidera un sitio volcánico tropical (Mauna Loa) y el segundo es Galápagos, porque para la base lunar en tubos de lava lo que más pesa es geología y refugio subterráneo, no el frío.

### F. Preguntas trampa o de presión

**"Esto lo hizo una IA, ¿verdad?"**
Usamos herramientas de asistencia como cualquier equipo de ingeniería hoy, pero las decisiones son nuestras: qué datos usar, cómo pesar cada blanco, qué marcar como supuesto. Ofrecer explicar cualquier función del código en el momento.

**"Si tuvieran que eliminar una dimensión, ¿cuál?"**
La térmica es la más débil frente a la Luna, porque ningún sitio terrestre se acerca a −183 °C. Pero quitarla escondería una diferencia real, y nuestro principio es mostrar las diferencias, no ocultarlas.

**"¿Cuál es la mayor debilidad del proyecto?"**
Responder sin titubear: *"La geología del catálogo es asignada por nosotros y no medida. Es lo primero que reemplazaríamos con datos espectrales orbitales."* Admitir la debilidad con un plan concreto suma puntos.

**"¿Qué harían con 6 meses más?"**
(1) Mineralogía con datos espectrales (ASTER, Sentinel-2), (2) análisis de sensibilidad de los pesos, (3) validación en campo con universidades ecuatorianas, (4) catálogo abierto a contribuciones revisadas.

---

## 7. Cosas que NO hay que decir

| No decir | Decir en su lugar |
| :--- | :--- |
| "Galápagos es igual a la Luna" | "Galápagos es el segundo mejor análogo de 60 para los tubos de lava de Mare Tranquillitatis" |
| "Procesamos imágenes de Landsat y Sentinel" | "Definimos qué sensor usar en cada sitio; integrarlo es el siguiente paso" |
| "Usamos inteligencia artificial / machine learning" | "Usamos agrupamiento K-Means y vecinos cercanos para comparar sitios" |
| "Todos los datos son medidos" | "Clima y relieve son medidos; la geología del catálogo es asignada y está documentada" |
| "Es seguro para aterrizar o construir" | "Es un índice para priorizar dónde investigar, no una certificación" |
| "Nadie ha hecho esto" | "No encontramos herramientas que combinen puntaje cuantitativo, evaluación en vivo y límites explícitos" |
| "Atacama, Hawái, Islandia y Antártida tienen toda la literatura" | "Concentran gran parte de la literatura de análogos" |

---

## 8. Quién responde qué en el Q&A

Para no pisarse ni quedarse callados, cada pregunta tiene un dueño. Si el dueño no sabe, pasa la palabra con una frase corta ("Eso lo explica mejor X").

| Tema de la pregunta | Responde primero | Respaldo |
| :--- | :--- | :--- |
| Problema, contexto, por qué importa | Persona 1 | Persona 4 |
| Datos NASA, fórmula, pesos, limitaciones científicas | Persona 2 | Persona 3 |
| Código, arquitectura, APIs, tests, demo | Persona 3 | Persona 2 |
| Impacto, Ecuador, usuarios, futuro | Persona 4 | Persona 1 |

**Reglas:**
- Responder en 20–30 segundos máximo. Si el juez quiere más, pregunta.
- Si no sabes: *"No lo medimos todavía; lo haríamos con [método]."* Nunca inventar un número.
- No contradecir a un compañero frente al jurado. Si algo quedó mal, completar con "Y para agregar…".

---

## 9. Si falla la demo

1. No disculparse más de una vez. Decir: *"Pasamos al respaldo grabado."*
2. Abrir el video de respaldo (tenerlo descargado, no en streaming).
3. Si tampoco hay video: mostrar `docs/presentacion_jurado.html` y narrar los 3 clics de la lámina 5.
4. El catálogo de 60 sitios funciona sin internet porque está precalculado; solo el sondeo de coordenadas nuevas necesita red.

---

## 10. Dónde está cada cosa (por si piden ver código)

| Qué | Archivo |
| :--- | :--- |
| Motor de puntaje, blancos, sitios | `engine/asi_engine.py` |
| Fórmula de cada dimensión | `score_target` en `engine/asi_engine.py` |
| Lectura de NASA POWER y reintentos | `parse_power`, `fetch_climatology`, `_get_with_retry` |
| Cálculo de pendiente con el DEM | `fetch_dem` |
| K-Means y k-NN | `analyze_analog_clusters_and_knn` |
| Sondeo de un punto y grilla | `score_custom_coordinates`, `grid_search_region` |
| Tests | `engine/tests/test_asi_engine.py`, `frontend/tests/` |
| API web | `frontend/src/app/api/evaluate/route.ts`, `frontend/src/app/api/evaluate-region/route.ts` |
| Dataset generado | `frontend/public/data/analogs.json`, `analogs.geojson` |
