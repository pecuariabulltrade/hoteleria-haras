-- Vista hot_resumen_mensual — Hotelería El Haras
-- Una fila por mes y hotelero con los importes de la liquidación guardada al cerrar el mes (todo sin IVA).
-- LA CONSUME EL PORTAL DE COSTOS (portal-costos-physis): no cambiar columnas ni semántica sin avisar a ese proyecto.
--
-- Reproduce el Dashboard de la app:
--   "facturado total por mes"  = sum(neto)  agrupando por mes
--   "facturación propia"       = sum(neto) where es_propio   (= módulo ganadería del Dashboard)
--   es_propio sale del campo «Módulo» del padrón del mes más reciente (hot_periodos.hoteleros_cfg[].grupo),
--   si falta, del grupo guardado en la liquidación, y si falta, de la lista por defecto:
--   BULLTRADE, PEGSA, EL SAGUIPE y ALONSO DANAE son módulo ganadería (es_propio = true); el resto, terceros.
-- Solo hay filas de meses cerrados (las liquidaciones se generan al cerrar el mes; reabrir el mes las borra).

create or replace view public.hot_resumen_mensual
with (security_invoker = true) as
with ultimo as (
  select hoteleros_cfg from public.hot_periodos order by mes desc limit 1
), grupos as (
  select h->>'id' as hotelero, h->>'grupo' as grupo, h->>'nombre' as nombre
  from ultimo, jsonb_array_elements(coalesce(ultimo.hoteleros_cfg, '[]'::jsonb)) h
)
select
  l.mes,
  l.hotelero,
  l.datos->'h'->>'tratamiento'                                   as tratamiento,
  coalesce(
    g.grupo,
    l.datos->'h'->>'grupo',
    case when upper(l.hotelero) in ('BULLTRADE','PEGSA','EL SAGUIPE','ALONSO DANAE')
           or upper(coalesce(l.datos->'h'->>'nombre','')) in ('BULLTRADE','PEGSA','EL SAGUIPE','ALONSO DANAE')
         then 'ganaderia' else 'tercero' end
  ) = 'ganaderia'                                                as es_propio,
  round((l.datos->'r'->>'hoteleria')::numeric, 2)                as hoteleria,
  round((l.datos->'r'->>'alimento')::numeric, 2)                 as alimentacion,
  round((l.datos->'r'->>'sanidad')::numeric, 2)                  as sanidad,
  round((l.datos->'r'->>'subtotal')::numeric, 2)                 as neto,
  coalesce(p.estado, 'cerrado')                                  as estado,
  l.cerrada_en                                                   as cerrado_el
from public.hot_liquidaciones l
left join public.hot_periodos p on p.mes = l.mes
left join grupos g on g.hotelero = l.hotelero;

comment on view public.hot_resumen_mensual is 'Resumen mensual de hotelería por hotelero (sin IVA). La consume el portal de costos (portal-costos-physis): no cambiar sin avisar.';

-- Acceso: la vista respeta RLS de las tablas (security_invoker). Solo usuarios autenticados y service_role; nunca anon.
revoke all on public.hot_resumen_mensual from anon;
grant select on public.hot_resumen_mensual to authenticated, service_role;
