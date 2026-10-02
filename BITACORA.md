# Bitácora — Hotelería El Haras

Sistema de facturación de hotelería de Pecuaria El Garabí S.A. (PEGSA), establecimiento El Haras, Vicuña Mackenna. Reemplaza la planilla mensual "consumo <mes> estimativo.xlsx". Responsable: Nico. Última actualización: 02/10/2026.

## Dónde está cada cosa

| Qué | Dónde |
|---|---|
| App (producción) | https://pecuariabulltrade.github.io/hoteleria-haras/ |
| Código fuente publicado | Repo GitHub `pecuariabulltrade/hoteleria-haras` (GitHub Pages sirve `index.html`) |
| Proyecto completo en la PC de la oficina | `C:\Users\USER\Documents\GitHub\hoteleria-haras` (index.html, src/, tools/, sync/, data/, README.md, esta bitácora) |
| Base de datos | Supabase, proyecto de Caravanas Pecuaria (`xqcipsnyvnozkvehpzsk`), tablas con prefijo `hot_`. Mismos usuarios y contraseña que Caravanas |
| Servicio «Tomar información» | PC de la oficina, `sync\SERVICIO_HOTELERIA.bat` (puerto 8766). Lee la base Nutrir FL y la API de WinCampo. Credenciales en `sync\.env` |
| Respaldos automáticos | `Dropbox\Hoteleria El Haras\respaldos` (si no hay Dropbox: `hoteleria-haras\respaldos`), Excel informe + JSON por mes, al cerrar el mes o con «Respaldar en el servidor» |
| Histórico importado | `data\hist\<AAAA-MM>.json` (mayo 2025 a agosto 2026) generado por `tools\extraer_historico.py` desde los Excel mensuales |
| Documentación técnica | `README.md` del proyecto (reglas de cálculo, validación, puesta en marcha, servicio) |

## Cómo se publica un cambio

El código se edita en `src/` y se reensambla con `python tools\build.py`, que genera `index.html`. Para publicar, se sube `index.html` al repo arrastrándolo a "Upload files" en GitHub (web); GitHub Pages lo sirve en un minuto. Recargar la app con Ctrl+F5. Los datos no viven en GitHub sino en Supabase, así que subir una versión nueva no toca los datos.

## Reglas de negocio (resumen)

Cada día, los kilos tal cual alimentados (por corral e insumo, de Nutrir FL) se reparten entre los hoteleros según su tratamiento. **Cierto**: se le asignan los kilos de sus corrales, con un ajuste en ± kg/día (hoy solo la feria, corral FERIA). **Propio**: kg/cab base del día (total menos ciertos, dividido las cabezas no ciertas) × sus cabezas. **No propio ni cierto**: igual que propio con un % de ajuste único por hotelero. **Residual** (PEGSA): lo que queda, de modo que la suma de todos cierre contra el total alimentado del día (cierre diario = 0).

Las cabezas de cada hotelero salen del stock inicial del mes (lo fija Nico; el sistema sugiere el de WinCampo) más ingresos, menos egresos y mortandad, solo movimientos de El Haras (corrales 1 a 199 en WinCampo). El alimento se valoriza al precio diario de cada insumo con markup (15 %). Hotelería = cabezas·día × $/cab/día (precio general del mes, salvo FERIA que tiene precio propio). Sanidad de ingreso = cabezas ingresadas con sanidad × precio × (1 + markup). La sanidad individual (tratamientos) por ahora no se factura. IVA 21 %.

Precios: el maíz se importa del Excel de cotizaciones del Mercado de Cañuelas; al valor se le resta 63.180/63.181 $/tn y se le suma 26.573 $/tn; los días sin cotización toman la del día anterior. El silo se calcula por fórmula a partir del maíz. Gluten, núcleo y harina de germen son fijos mensuales con % de merma.

Para el dashboard, lo facturado se clasifica en **módulo ganadería** (Bulltrade, PEGSA, El Saguipe, Alonso Danae) o **terceros** (todos los demás). Se edita por hotelero en la pestaña Hoteleros → Módulo.

## Rutina mensual

1. «+ Mes» crea el período siguiente copiando hoteleros, parámetros y precios; el stock inicial propuesto es el stock final del mes anterior.
2. «⟳ Tomar información» (con el servicio corriendo en la PC de la oficina) trae alimentación, movimientos y stock sugerido. Revisar stocks iniciales en Hoteleros y los movimientos.
3. Parámetros y precios: importar el Excel de Cañuelas, revisar precios fijos y merma, hotelería y sanidad del mes.
4. Control del mes: el cierre diario tiene que dar 0 todos los días.
5. Liquidaciones → «Cerrar mes y guardar liquidaciones»: guarda una liquidación por hotelero (estado pendiente), marca el mes cerrado y dispara el respaldo Excel + JSON en la PC.
6. Facturación: a medida que se hacen las facturas, cargar número y fecha y «Marcar facturada». «Reabrir mes» descarta las liquidaciones del mes (no se puede si alguna ya está facturada).

La app autoguarda en la nube unos segundos después de cada cambio (el botón muestra «Guardado hh:mm»).

## Cronología

| Fecha | Qué pasó |
|---|---|
| 30/09/2026 | Arranque del proyecto. Nico describe los tratamientos (cierto / propio / no propio / residual), hotelería y sanidad, y entrega el Excel de agosto 2026 para validar. Decisiones: app web como el portal PEGSA, datos de Nutrir FL + WinCampo, % de ajuste único por hotelero, precios únicos de hotelería y sanidad. |
| 30/09/2026 | Motor de cálculo validado contra la planilla de agosto 2026: kilos, precios diarios, hotelería y sanidad idénticos (Bulltrade y La Tapera exactos; PEGSA con la diferencia de 15 cabezas de la planilla). Motor de referencia en Python (`tools\motor_ref.py`). |
| 01/10/2026 | Decisiones de operación: la toma de datos es un botón, no corre sola; el stock inicial lo fija Nico con el sugerido editable; solo movimientos de El Haras (corrales 1–199); sanidad individual no se factura; FERIA es el único cierto y tiene precio propio de hotelería; movimientos editables en el cuadro. Reglas de precios (Cañuelas, silo por fórmula, fijos con merma). |
| 01/10/2026 | Publicación: repo y GitHub Pages; base en el Supabase de Caravanas con prefijo `hot_` (la cuenta no tiene más proyectos gratis); servicio «Tomar información» en la PC de la oficina. Septiembre 2026 traído del sistema: 2.436.633 kg, 56 movimientos. |
| 01/10/2026 | Mejoras en Control del mes (% MS, kg MS, $/kg TC y MS, filas General). Cierre de mes con liquidaciones guardadas y pestaña Facturación. Respaldo Excel informe + JSON en el servidor al cerrar. |
| 01/10/2026 | Incidente: los datos cargados de septiembre se perdieron dos veces. Causa: la app solo subía a la nube al apretar Guardar/Cerrar, y una recarga desde la nube pisó la copia local. Solución: autoguardado automático; además, no operar la app desde el navegador de Nico mientras él trabaja (las verificaciones se hacen leyendo la nube desde otra pestaña). Septiembre se volvió a cargar. |
| 02/10/2026 | Histórico cargado: 15 planillas (mayo 2025 a julio 2026) más agosto 2026, con las liquidaciones tal cual salieron de cada planilla (no recalculadas), meses cerrados y marcados como facturados sin número de factura. Mayo 2025 difiere en kilos (la feria no estaba en la dieta); junio y septiembre 2025 con diferencias chicas; las liquidaciones reflejan las hojas. |
| 02/10/2026 | Al cargar el histórico se pisó el padrón global de hoteleros; se restauró y se cambió el diseño: cada mes guarda su propio padrón (`hoteleros_cfg`) y el padrón global solo lo escribe el mes más reciente. |
| 02/10/2026 | **Septiembre 2026 cerrado**: 6 liquidaciones pendientes de facturar, total $ 870.642.641 con IVA (PEGSA 619,0 M; Bulltrade 191,3 M; La Tapera 24,3 M; Feria 20,1 M; UGMA 9,4 M; Darwash 6,6 M). Verificado en la nube. |
| 02/10/2026 | Vista `hot_resumen_mensual` en Supabase para el **portal de costos** (`portal-costos-physis`): una fila por mes y hotelero con hotelería, alimentación, sanidad y neto sin IVA, `es_propio` = módulo ganadería. Permisos solo para usuarios autenticados y service_role (anon rechazado, verificado). SQL en `hot_resumen_mensual.sql` y nota en el README. Control: agosto 2026 PEGSA neto 568.489.406,08 (lo facturado desde la planilla; el recálculo de la app daría 565.486.132,30). |
| 02/10/2026 | Pestaña **Dashboard**: todos los meses resumidos, indicadores, gráficos (liquidado por mes apilado módulo ganadería vs. terceros, kg por mes, ranking por hotelero), tablas por mes y por hotelero, filtro por año y neto/con IVA. Columna Módulo en Hoteleros. Con el histórico: $ 14.060 M netos en 16 meses, 82,8 % módulo ganadería. |

## Estado al 02/10/2026

17 meses en la nube (mayo 2025 a septiembre 2026). Los 16 anteriores cerrados con liquidaciones importadas de las planillas; septiembre 2026 cerrado con sus 6 liquidaciones pendientes de facturar. La versión con Dashboard está en la PC de la oficina lista para subir a GitHub.

## Pendientes y cosas a tener en cuenta

- La vista `hot_resumen_mensual` la consume el portal de costos: no cambiarla sin avisar a ese proyecto.
- Facturar septiembre 2026 y marcar cada liquidación en Facturación.
- Números de factura de los meses históricos (quedaron como facturados sin número); se pueden cargar en Facturación si hace falta.
- Hotelero EL SAGUIPE: está en el padrón sin movimientos; activarlo o desactivarlo según corresponda. ALONSO DANAE todavía no existe como hotelero (al darlo de alta cae en módulo ganadería).
- El respaldo en Dropbox se genera solo si el servicio de la PC está corriendo al cerrar el mes; si no, «Exportar Excel» desde Liquidaciones y «Respaldar en el servidor» más tarde.
- La pestaña del SQL editor de Supabase que quedó abierta en Chrome se cierra sin guardar.
- Regla de trabajo: las verificaciones de datos se hacen leyendo la nube desde una pestaña aparte, nunca operando la app en el navegador de Nico mientras él carga datos.
