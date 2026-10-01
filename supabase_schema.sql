-- Hotelería El Haras — esquema Supabase (Postgres)
-- Vive en el proyecto de Caravanas Pecuaria (xqcipsnyvnozkvehpzsk) con prefijo hot_ para no mezclarse con sus tablas.
-- Ejecutar en el SQL Editor. Acceso: cualquier usuario autenticado lee y escribe (los mismos usuarios de Caravanas).

create table if not exists hot_hoteleros (
  id              text primary key,                 -- código corto, ej. PEGSA, BULLTRADE
  nombre          text not null,
  razon_social    text,
  cuit            text,
  tratamiento     text not null check (tratamiento in ('cierto','propio','no_propio','residual')),
  ajuste_pct      numeric default 0,                -- no_propio: 0.25 = +25 %
  ajuste_kg       numeric default 0,                -- cierto: ± kg por día
  corrales        text[] default '{}',              -- cierto: corrales asignados (nombres de Nutrir FL)
  precio_hoteleria numeric,                        -- $/cab/día propio del hotelero; null = precio general del período
  paga_hoteleria  boolean default true,
  paga_sanidad    boolean default true,
  activo          boolean default true,
  actualizado     timestamptz default now()
);

create table if not exists hot_periodos (
  mes              text primary key,                -- 'AAAA-MM'
  markup           numeric not null default 0.15,
  precio_hoteleria numeric not null default 0,      -- $/cab/día
  precio_sanidad   numeric not null default 0,      -- $/cab ingresada (costo, se le aplica markup)
  iva              numeric not null default 0.21,
  estado           text default 'abierto' check (estado in ('abierto','cerrado')),
  insumos          jsonb default '[]',              -- [{nombre, humedad, tipo, base, merma}]
  precios_config   jsonb default '{}',              -- {maiz:{flete_largo, flete_corto, piso, cotizaciones[]}, silo:{adicional, rendimiento, factor}}
  stock_inicial    jsonb default '{}',              -- {hotelero_id: cabezas al 1° del mes} (lo fija el usuario)
  stock_sugerido   jsonb default '{}',              -- {hotelero_id: cabezas al 1° del mes según WinCampo} (referencia)
  actualizado      timestamptz default now()
);

-- Kilos tal cual alimentados por día, corral e insumo (origen: base Nutrir FL, script etapa 2)
create table if not exists hot_alimentacion (
  id      bigserial primary key,
  mes     text not null references hot_periodos(mes) on delete cascade,
  fecha   date not null,
  corral  text not null,
  insumo  text not null,
  kg      numeric not null
);
create index if not exists hot_alimentacion_mes_idx on hot_alimentacion(mes, fecha);

-- Movimientos de cabezas por hotelero (origen: WinCampo, script etapa 2; editable en la app)
create table if not exists hot_movimientos (
  id       bigserial primary key,
  mes      text not null references hot_periodos(mes) on delete cascade,
  fecha    date not null,
  hotelero text not null references hot_hoteleros(id),
  tipo     text not null check (tipo in ('ingreso','egreso','mortandad')),
  cabezas  integer not null,
  tropa    text,
  sanidad  boolean default false,                    -- ingreso con sanidad de ingreso facturable
  origen   text default 'manual' check (origen in ('sistema','manual'))  -- 'sistema' = traído de WinCampo (se reemplaza al tomar información)
);
create index if not exists hot_movimientos_mes_idx on hot_movimientos(mes, fecha);

-- Precio diario de cada insumo ($/kg TC, costo)
create table if not exists hot_precios (
  id     bigserial primary key,
  mes    text not null references hot_periodos(mes) on delete cascade,
  fecha  date not null,
  insumo text not null,
  precio numeric not null,
  unique (mes, fecha, insumo)
);

-- RLS: usuarios autenticados, acceso completo
alter table hot_hoteleros    enable row level security;
alter table hot_periodos     enable row level security;
alter table hot_alimentacion enable row level security;
alter table hot_movimientos  enable row level security;
alter table hot_precios      enable row level security;
do $$ declare t text; begin
  foreach t in array array['hot_hoteleros','hot_periodos','hot_alimentacion','hot_movimientos','hot_precios'] loop
    execute format('drop policy if exists "hot_auth_all" on %I', t);
    execute format('create policy "hot_auth_all" on %I for all to authenticated using (true) with check (true)', t);
  end loop;
end $$;
