-- =========================================================
-- DulceMoment · Esquema Supabase (PostgreSQL)
-- Ejecutar completo en: Supabase Dashboard > SQL Editor
-- =========================================================

-- ---------------------------------------------------------
-- 1. TABLAS
-- ---------------------------------------------------------

-- Perfil de usuario, 1:1 con auth.users (Supabase Auth maneja
-- email/password reales; aquí solo guardamos datos de dominio)
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  name text not null,
  email text not null unique,
  role text not null check (role in ('customer', 'store')),
  created_at timestamptz not null default now()
);

create table if not exists public.products (
  id bigint generated always as identity primary key,
  name text not null,
  description text not null,
  base_price numeric(10, 2) not null check (base_price > 0),
  stock integer not null default 0 check (stock >= 0),
  image_url text not null default '',
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.product_options (
  id bigint generated always as identity primary key,
  product_id bigint not null references public.products (id) on delete cascade,
  category text not null,
  value text not null,
  price_delta numeric(10, 2) not null default 0
);
create index if not exists idx_product_options_product on public.product_options (product_id);
create index if not exists idx_product_options_category on public.product_options (category);

create table if not exists public.orders (
  id bigint generated always as identity primary key,
  customer_id uuid not null references public.profiles (id) on delete cascade,
  status text not null default 'created'
    check (status in ('created', 'in_oven', 'decorating', 'on_the_way', 'delivered', 'cancelled')),
  total numeric(10, 2) not null default 0,
  delivery_address text not null,
  notes text not null default '',
  created_at timestamptz not null default now()
);
create index if not exists idx_orders_customer on public.orders (customer_id);

create table if not exists public.order_items (
  id bigint generated always as identity primary key,
  order_id bigint not null references public.orders (id) on delete cascade,
  product_id bigint not null references public.products (id),
  quantity integer not null check (quantity > 0),
  unit_price numeric(10, 2) not null,
  ingredients text not null default '',
  size text not null default '',
  shape text not null default '',
  flavor text not null default '',
  color text not null default ''
);
create index if not exists idx_order_items_order on public.order_items (order_id);
create index if not exists idx_order_items_product on public.order_items (product_id);

create table if not exists public.tracking_events (
  id bigint generated always as identity primary key,
  order_id bigint not null references public.orders (id) on delete cascade,
  status text not null,
  message text not null,
  eta_minutes integer not null default 0,
  created_at timestamptz not null default now()
);
create index if not exists idx_tracking_events_order on public.tracking_events (order_id);

create table if not exists public.payments (
  id bigint generated always as identity primary key,
  order_id bigint not null unique references public.orders (id) on delete cascade,
  amount numeric(10, 2) not null,
  status text not null,
  card_last4 text not null default '',
  created_at timestamptz not null default now()
);

create table if not exists public.push_alerts (
  id bigint generated always as identity primary key,
  user_id uuid not null references public.profiles (id) on delete cascade,
  order_id bigint references public.orders (id) on delete set null,
  title text not null,
  body text not null,
  created_at timestamptz not null default now()
);
create index if not exists idx_push_alerts_user on public.push_alerts (user_id);

-- ---------------------------------------------------------
-- 2. TRIGGER: crear profile automáticamente al registrarse
--    (usa raw_user_meta_data enviado desde signUp)
-- ---------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, name, email, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'name', ''),
    new.email,
    coalesce(new.raw_user_meta_data ->> 'role', 'customer')
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ---------------------------------------------------------
-- 3. ROW LEVEL SECURITY
-- ---------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.products enable row level security;
alter table public.product_options enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.tracking_events enable row level security;
alter table public.payments enable row level security;
alter table public.push_alerts enable row level security;

-- profiles: cada quien ve su propio perfil, y todos pueden ver
-- el perfil público de la tienda (para mostrar "vendido por")
create policy "profiles_select_own_or_store" on public.profiles
  for select using (auth.uid() = id or role = 'store');
create policy "profiles_update_own" on public.profiles
  for update using (auth.uid() = id);

-- products: catálogo activo visible a todos los autenticados,
-- la tienda ve también los inactivos y puede escribir
create policy "products_select" on public.products
  for select using (
    is_active = true
    or exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'store')
  );
create policy "products_insert_store" on public.products
  for insert with check (
    exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'store')
  );
create policy "products_update_store" on public.products
  for update using (
    exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'store')
  );

-- product_options: lectura libre, escritura solo tienda
create policy "product_options_select" on public.product_options
  for select using (true);
create policy "product_options_insert_store" on public.product_options
  for insert with check (
    exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'store')
  );
create policy "product_options_update_store" on public.product_options
  for update using (
    exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'store')
  );
create policy "product_options_delete_store" on public.product_options
  for delete using (
    exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'store')
  );

-- orders: el cliente ve/crea/edita los suyos, la tienda ve y edita todos
create policy "orders_select" on public.orders
  for select using (
    customer_id = auth.uid()
    or exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'store')
  );
create policy "orders_insert_customer" on public.orders
  for insert with check (customer_id = auth.uid());
create policy "orders_update" on public.orders
  for update using (
    customer_id = auth.uid()
    or exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'store')
  );

-- order_items: visibles/insertables si el pedido padre es accesible
create policy "order_items_select" on public.order_items
  for select using (
    exists (
      select 1 from public.orders o
      where o.id = order_items.order_id
        and (o.customer_id = auth.uid()
             or exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'store'))
    )
  );
create policy "order_items_insert" on public.order_items
  for insert with check (
    exists (select 1 from public.orders o where o.id = order_items.order_id and o.customer_id = auth.uid())
  );

-- tracking_events: select igual que orders; insert solo tienda
create policy "tracking_events_select" on public.tracking_events
  for select using (
    exists (
      select 1 from public.orders o
      where o.id = tracking_events.order_id
        and (o.customer_id = auth.uid()
             or exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'store'))
    )
  );
create policy "tracking_events_insert_store" on public.tracking_events
  for insert with check (
    exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'store')
  );

-- payments: el cliente inserta el pago de su propio pedido,
-- ambos pueden leer, la tienda puede actualizar el estado
create policy "payments_select" on public.payments
  for select using (
    exists (
      select 1 from public.orders o
      where o.id = payments.order_id
        and (o.customer_id = auth.uid()
             or exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'store'))
    )
  );
create policy "payments_insert_customer" on public.payments
  for insert with check (
    exists (select 1 from public.orders o where o.id = payments.order_id and o.customer_id = auth.uid())
  );
create policy "payments_update_store" on public.payments
  for update using (
    exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'store')
  );

-- push_alerts: cada quien lee las suyas; cualquier usuario autenticado
-- puede insertar (la app crea alertas para el otro extremo del pedido)
create policy "push_alerts_select_own" on public.push_alerts
  for select using (user_id = auth.uid());
create policy "push_alerts_insert_authenticated" on public.push_alerts
  for insert with check (auth.role() = 'authenticated');

-- ---------------------------------------------------------
-- 4. REALTIME (para streams de pedidos/alertas en vivo)
-- ---------------------------------------------------------
alter publication supabase_realtime add table public.orders;
alter publication supabase_realtime add table public.order_items;
alter publication supabase_realtime add table public.tracking_events;
alter publication supabase_realtime add table public.products;
alter publication supabase_realtime add table public.push_alerts;
