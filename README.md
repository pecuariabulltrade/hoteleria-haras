# Hotelería El Haras — facturación mensual de hoteleros

App web de un solo archivo (`index.html`, HTML + JS sin framework) que asigna el alimento del mes a cada hotelero según su tratamiento, calcula hotelería y sanidad de ingreso y emite la liquidación. Misma arquitectura que el portal PEGSA y Caravanas Pecuaria: front en GitHub Pages, datos en Supabase, y un servicio Python en la PC de la oficina que responde al botón «Tomar información» (no corre solo).

## Archivos

| Archivo | Qué es |
|---|---|
| `index.html` | La app completa. Trae embebido el ejemplo de agosto 2026 (se carga solo la primera vez). |
| `supabase_schema.sql` | Tablas y políticas para el proyecto Supabase. |
| `data/agosto_2026.json` | Agosto 2026 extraído del Excel, en el formato que consume la app. |
| `tools/extraer_agosto.py` | Extrae el JSON a partir de `consumo Agosto 26estimativo.xlsx` (sirve de referencia del formato). |
| `tools/motor_ref.py` | Motor de cálculo de referencia en Python; da exactamente lo mismo que el motor JS. |
| `tools/build.py` | Reensambla `index.html` a partir de `src/` (solo si se modifica el código). |
| `sync/servicio_hoteleria.py` + `SERVICIO_HOTELERIA.bat` | Servicio local para «Tomar información»: lee Nutrir FL y WinCampo y devuelve el JSON del mes. |
| `sync/wincampo/` | Carpeta donde el servicio busca las exportaciones de WinCampo mientras no esté la consulta directa (ver ejemplos). |

## Reglas de cálculo (por día)

1. **Alimento cierto**: kilos reales de los corrales asignados al hotelero (de la base Nutrir FL), multiplicados por `(kg + ajuste kg/día) / kg` si hay ajuste. Se restan del total del día junto con sus cabezas.
2. **kg/cab base** = (kg del día − kg de los ciertos) ÷ (cabezas de todos los hoteleros propios, no propios y residual).
3. **Alimento propio**: kg/cab base × cabezas del hotelero ese día.
4. **No propio**: kg/cab base × (1 + % ajuste) × cabezas.
5. **Residual** (PEGSA): total del día − todo lo anterior, insumo por insumo. Así la suma de todos los hoteleros cierra contra lo alimentado (pestaña Control del mes, columna Dif. = 0).
6. Los kilos de los propios/no propios se abren por insumo con la proporción del día (sin los corrales ciertos). Los ciertos llevan la composición real de sus corrales.
7. **$ Alimento** = Σ kg insumo × precio del día del insumo × (1 + markup). Los precios diarios se calculan según la forma de precio de cada insumo (pestaña *Parámetros y precios*):
   - *Fijo mensual + merma* (gluten, núcleo, harina): precio base del mes × (1 + % merma, p. ej. 5 % o 10 %).
   - *Maíz (cotización)*: cotización del mercado del día ($/tn, importada del Excel del Mercado de Cañuelas o cargada a mano) − un valor a restar (63.181 en agosto) + un valor a sumar (26.573), ÷ 1000, con un piso en $/kg; los días sin cotización repiten la última, y antes de la primera del mes se usa la primera.
   - *Silo (fórmula sobre maíz)*: (maíz del día + adicional) × rendimiento × factor ÷ 10.000 (en agosto: 14,5 · 7350 · 0,87).
   - *Manual por día*: se tipea en la grilla.
   Con la configuración extraída de la hoja DATOS, la app reproduce los 248 precios diarios de agosto exactamente.
8. **Hotelería** = cabezas al cierre de cada día × $/cab/día (sin markup).
9. **Sanidad de ingreso** = cabezas de cada ingreso marcado «sanidad» × precio sanidad × (1 + markup).
10. IVA sobre el subtotal neto.

Stock diario = stock inicial del mes + ingresos − egresos − mortandad. El stock inicial lo fija el usuario (el sistema solo sugiere el de WinCampo, columna «Sugerido sistema» con botón «usar»). Un hotelero puede tener precio de hotelería propio (FERIA: $50.000/cab/día); en blanco usa el general del mes. Los tratamientos sanitarios individuales no se facturan por ahora.

## Validación con agosto 2026

Con el JSON extraído del Excel el motor reproduce la hoja `resumen`: 2.840.183 kg totales, cierre diario 0 en los 31 días, hotelería (incluida la de FERIA, $800.000) y sanidad de ingreso idénticas por hotelero. Diferencias esperables y explicadas:

- BULLTRADE y LA TAPERA dan exactamente los mismos kg que la planilla si el stock de PEGSA se corrige en +15 cabezas (la hoja FEEDLOT arranca con 5.896 cabezas pero las hojas de hoteleros suman 5.881). Tal cual está, la diferencia es 0,26 %.
- DARWASH y UGMA: la planilla sumaba +4 kg/cab (y no en todos los días); la app aplica +25 %. Diferencia 0,5–0,7 %.
- El importe en $ de los propios queda ~0,9 % más alto que en la planilla porque la app ya no les reparte el silo de la feria (la planilla usaba la proporción del día incluyendo feria).

## Puesta en marcha

1. **Supabase**: las tablas `hot_*` ya están creadas en el proyecto de Caravanas Pecuaria (xqcipsnyvnozkvehpzsk) con `supabase_schema.sql`; los usuarios son los mismos de Caravanas (Authentication > Users).
2. **Front**: publicado en GitHub Pages desde el repo `pecuariabulltrade/hoteleria-haras` → https://pecuariabulltrade.github.io/hoteleria-haras/. La app ya viene configurada contra el Supabase de Caravanas (tablas `hot_`); solo hay que ingresar con un usuario de Caravanas en *Datos y conexión*.
3. **Primer mes**: cargar el ejemplo de agosto o un JSON, revisar hoteleros, parámetros y precios, «Subir período actual».
4. **Mes siguiente**: botón «+ Mes» en la barra superior: crea el mes con el stock final del anterior como inicial (editable) y copia hoteleros, insumos y últimos precios.
5. **Tomar información**: en la PC de la oficina dejar corriendo `sync/SERVICIO_HOTELERIA.bat` (queda escuchando en `http://localhost:8766`). Abrir la app en esa misma PC y apretar «⟳ Tomar información»: trae la alimentación del mes (reemplaza la anterior), los movimientos del sistema (reemplaza solo los de origen «sistema», los cargados a mano se conservan) y el stock sugerido. Si el servicio no está corriendo, la app lo avisa y se puede importar el JSON a mano desde *Datos y conexión*.

En modo local (sin Supabase) todo queda en el navegador; conviene descargar el JSON del período antes de cerrar el mes.

## Servicio «Tomar información» (sync/servicio_hoteleria.py)

- **Nutrir FL** (`Base FL Mobilia.mdb`, ruta en `NUTRIR_MDB`): `Lectura_Viajes` ⋈ `Lectura_Descarga` (kg por corral) ⋈ `Lectura_Carga` (kg por insumo). Para cada viaje, los kg de cada insumo se prorratean a cada corral según `Kg_Real` del corral / total descargado del viaje. Los viajes con receta `feria` van al corral virtual `FERIA` (que es el corral del hotelero cierto FERIA). Resultado: filas `{fecha, corral, insumo, kg}`. En Windows usa `pyodbc` con el driver de Access; en Linux `mdb-export`.
- **WinCampo** (API de WinCampo Web, cuenta elgarabi = feedlot El Haras; credenciales en `sync/.env`, ver `.env.ejemplo`): ingresos desde `lst_trazabilidad` (reporte ingreso_caravana, una fila por animal → cabezas por hotelero, fecha y N° de tropa, con sanidad de ingreso marcada), egresos y muertes desde `lst_egresos_hacienda` (MOTIVO M = mortandad, V/T = egreso), y stock sugerido al 1° del mes = `caravanas_stock` actual − ingresos desde el 1° + egresos y muertes desde el 1°. **Solo se toman las filas cuyo `NRO_CORRAL` está entre 1 y 199 (El Haras)**; las de otros corrales (otros campos) se excluyen y el servicio informa cuántas fueron (`CORRAL_HARAS` en el script). El mapeo HOTELERO → id está en `MAPA_HOTELEROS`. Sin credenciales, el servicio lee `sync/wincampo/movimientos_AAAA-MM.csv|xlsx` y `stock_AAAA-MM.csv|xlsx` (hay `*_EJEMPLO.csv`), tomando solo filas cuyo establecimiento contiene «EL HARAS».
- Prueba sin servidor: `python servicio_hoteleria.py --json 2026-08 > salida.json` (ese JSON se puede importar desde la app).
- El navegador tiene que abrir la app en la misma PC donde corre el servicio (localhost). Si la app está en GitHub Pages (https), Chrome permite igual la llamada a `http://localhost` porque el servicio responde con los encabezados CORS y `Access-Control-Allow-Private-Network`.
