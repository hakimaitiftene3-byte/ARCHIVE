-- ============================================================
-- COMPLETE DATABASE SCHEMA — Run this ONE file in Supabase SQL Editor
-- ============================================================

-- ############################################################
-- FUNCTION: Auto-update updated_at
-- ############################################################
create or replace function update_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- ############################################################
-- TABLE 1: products
-- ############################################################
create table if not exists products (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  name_ar text,
  slug text unique not null,
  description text,
  description_ar text,
  category text,
  base_price integer not null,
  sale_price integer,
  is_active boolean default true,
  is_bestseller boolean default false,
  offer_enabled boolean default false,
  offer_percent integer default 0,
  sort_order integer default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ############################################################
-- EXTRA COLUMNS: products (size guide, offers, parent link)
-- ############################################################
alter table products add column if not exists size_guide_text text;
alter table products add column if not exists size_guide_images jsonb default '[]'::jsonb;
alter table products add column if not exists offer_text text;
alter table products add column if not exists offer_discount_type text default 'percent';
alter table products add column if not exists offer_discount_value integer default 0;
alter table products add column if not exists offer_min_qty integer default 1;
alter table products add column if not exists parent_product_id uuid references products(id) on delete set null;

-- ############################################################
-- TABLE 2: product_images
-- ############################################################
create table if not exists product_images (
  id uuid default gen_random_uuid() primary key,
  product_id uuid references products(id) on delete cascade,
  cloudinary_url text not null,
  cloudinary_public_id text not null,
  is_primary boolean default false,
  sort_order integer default 0,
  created_at timestamptz default now()
);

-- ############################################################
-- TABLE 3: product_variants
-- ############################################################
create table if not exists product_variants (
  id uuid default gen_random_uuid() primary key,
  product_id uuid references products(id) on delete cascade,
  size text not null,
  color text not null,
  color_hex text,
  price integer not null,
  stock integer not null default 0 check (stock >= 0),
  sku text unique,
  is_active boolean default true,
  sort_order integer default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(product_id, size, color)
);

-- ############################################################
-- TABLE 4: categories
-- ############################################################
create table if not exists categories (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  slug text unique not null,
  image_url text,
  is_active boolean default true,
  created_at timestamptz default now()
);

-- ############################################################
-- TABLE 5: wilaya_pricing
-- ############################################################
create table if not exists wilaya_pricing (
  id serial primary key,
  wilaya_code text not null unique,
  wilaya_name text not null,
  home_price integer not null,
  post_price integer not null,
  return_price integer default 0
);

-- ############################################################
-- TABLE 6: orders
-- ############################################################
create table if not exists orders (
  id uuid default gen_random_uuid() primary key,
  order_number bigint generated always as identity,
  first_name text not null,
  last_name text not null,
  phone text not null,
  phone2 text,
  wilaya_code text,
  wilaya_name text not null,
  commune text not null,
  delivery_type text not null check (delivery_type in ('home','post')),
  home_address text,
  notes text,
  shipping_cost integer not null,
  subtotal integer not null,
  total integer not null,
  status text not null default 'pending'
    check (status in ('pending','confirmed','processing','shipped','delivered','cancelled')),
  meta_event_id text,
  tracking_number text,
  promo_code text,
  promo_discount numeric default 0,
  notification_sent boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ############################################################
-- TABLE 7: order_items
-- ############################################################
create table if not exists order_items (
  id uuid default gen_random_uuid() primary key,
  order_id uuid references orders(id) on delete cascade,
  product_id uuid references products(id),
  variant_id uuid references product_variants(id),
  product_name text not null,
  product_image_url text,
  size text not null,
  color text not null,
  unit_price integer not null,
  quantity integer not null check (quantity > 0),
  line_total integer not null,
  created_at timestamptz default now()
);

-- ############################################################
-- TABLE 8: stock_movements
-- ############################################################
create table if not exists stock_movements (
  id uuid default gen_random_uuid() primary key,
  variant_id uuid references product_variants(id) on delete cascade,
  order_id uuid references orders(id),
  movement_type text not null check (movement_type in ('sale','restock','adjustment','cancelled')),
  quantity_change integer not null,
  stock_before integer not null,
  stock_after integer not null,
  note text,
  created_at timestamptz default now()
);

-- ############################################################
-- TABLE 9: site_settings
-- ############################################################
create table if not exists site_settings (
  key text primary key,
  value text,
  updated_at timestamptz default now()
);

-- ############################################################
-- TABLE 10: site_content (About page + multilingual)
-- ############################################################
create table if not exists site_content (
  id uuid default gen_random_uuid() primary key,
  section text not null,
  field text not null,
  lang text not null default 'en' check (lang in ('en','ar','fr')),
  value text,
  sort_order integer default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(section, field, lang)
);

-- ############################################################
-- TABLE 11: homepage_content
-- ############################################################
create table if not exists homepage_content (
  id serial primary key,
  field text not null,
  lang text not null default 'en' check (lang in ('en','ar','fr')),
  value text,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(field, lang)
);

-- ############################################################
-- TABLE 12: admin_users (Sub-Admins)
-- ############################################################
create table if not exists admin_users (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  access_code text unique not null,
  permissions text[] not null default '{}',
  is_active boolean default true,
  created_at timestamptz default now()
);

-- ############################################################
-- TABLE 13: outfits
-- ############################################################
create table if not exists outfits (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  name_ar text,
  slug text unique not null,
  description text,
  description_ar text,
  category text,
  base_price integer not null,
  sale_price integer,
  is_active boolean default true,
  is_bestseller boolean default false,
  offer_enabled boolean default false,
  offer_percent integer default 0,
  sort_order integer default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ############################################################
-- TABLE 14: outfit_images
-- ############################################################
create table if not exists outfit_images (
  id uuid default gen_random_uuid() primary key,
  outfit_id uuid references outfits(id) on delete cascade,
  cloudinary_url text not null,
  cloudinary_public_id text not null,
  is_primary boolean default false,
  sort_order integer default 0,
  created_at timestamptz default now()
);

-- ############################################################
-- TABLE 15: outfit_items
-- ############################################################
create table if not exists outfit_items (
  id uuid default gen_random_uuid() primary key,
  outfit_id uuid references outfits(id) on delete cascade,
  product_id uuid references products(id) on delete cascade,
  variant_id uuid references product_variants(id) on delete set null,
  quantity integer not null default 1 check (quantity > 0),
  created_at timestamptz default now(),
  unique(outfit_id, product_id, variant_id)
);

-- ############################################################
-- TABLE 16: outfit_products (child products in outfits)
-- ############################################################
create table if not exists outfit_products (
  id uuid default gen_random_uuid() primary key,
  outfit_id uuid references outfits(id) on delete cascade,
  name text not null default '',
  name_ar text default '',
  price integer default 0,
  category text default '',
  image_url text default '',
  sort_order integer default 0,
  created_at timestamptz default now()
);

-- ############################################################
-- TABLE 17: outfit_variants (color/size for outfit child products)
-- ############################################################
create table if not exists outfit_variants (
  id uuid default gen_random_uuid() primary key,
  outfit_product_id uuid references outfit_products(id) on delete cascade,
  color text default '',
  size text default '',
  price integer default 0,
  stock integer default 0,
  created_at timestamptz default now()
);

-- ############################################################
-- TABLE 18: promo_codes
-- ############################################################
create table if not exists promo_codes (
  id uuid default gen_random_uuid() primary key,
  code text not null unique,
  discount_type text not null default 'percent',
  discount_value numeric not null default 0,
  min_order numeric default 0,
  max_uses integer default 0,
  used_count integer default 0,
  expires_at timestamptz,
  is_active boolean default true,
  created_at timestamptz default now()
);

-- ############################################################
-- TABLE 19: page_views (analytics)
-- ############################################################
create table if not exists page_views (
  id uuid default gen_random_uuid() primary key,
  page text not null,
  path text,
  referrer text,
  user_agent text,
  screen_width integer,
  country text,
  created_at timestamptz default now()
);

-- ############################################################
-- TABLE 20: push_subscriptions
-- ############################################################
create table if not exists push_subscriptions (
  id uuid default gen_random_uuid() primary key,
  endpoint text not null unique,
  p256dh text not null,
  auth text not null,
  user_agent text,
  created_at timestamptz default now()
);

-- ############################################################
-- TRIGGERS
-- ############################################################
create trigger products_updated_at before update on products for each row execute function update_updated_at();
create trigger variants_updated_at before update on product_variants for each row execute function update_updated_at();
create trigger orders_updated_at before update on orders for each row execute function update_updated_at();
create trigger site_content_updated_at before update on site_content for each row execute function update_updated_at();
create trigger homepage_content_updated_at before update on homepage_content for each row execute function update_updated_at();
create trigger outfits_updated_at before update on outfits for each row execute function update_updated_at();

-- ############################################################
-- FUNCTIONS: Stock management
-- ############################################################
create or replace function decrease_stock_on_order(
  p_variant_id uuid,
  p_quantity integer,
  p_order_id uuid
) returns void as $$
declare
  current_stock integer;
begin
  select stock into current_stock from product_variants where id = p_variant_id for update;
  if current_stock < p_quantity then
    raise exception 'Insufficient stock for variant %', p_variant_id;
  end if;
  update product_variants set stock = stock - p_quantity where id = p_variant_id;
  insert into stock_movements (variant_id, order_id, movement_type, quantity_change, stock_before, stock_after)
  values (p_variant_id, p_order_id, 'sale', -p_quantity, current_stock, current_stock - p_quantity);
end;
$$ language plpgsql;

create or replace function restore_stock_on_cancel(p_order_id uuid) returns void as $$
declare
  item record;
  current_stock integer;
begin
  for item in select variant_id, quantity from order_items where order_id = p_order_id loop
    select stock into current_stock from product_variants where id = item.variant_id;
    update product_variants set stock = stock + item.quantity where id = item.variant_id;
    insert into stock_movements (variant_id, order_id, movement_type, quantity_change, stock_before, stock_after)
    values (item.variant_id, p_order_id, 'cancelled', item.quantity, current_stock, current_stock + item.quantity);
  end loop;
end;
$$ language plpgsql;

-- ############################################################
-- INDEXES
-- ############################################################
create index if not exists idx_products_category on products(category);
create index if not exists idx_products_slug on products(slug);
create index if not exists idx_products_active on products(is_active);
create index if not exists idx_products_sort on products(sort_order);
create index if not exists idx_products_bestseller on products(is_bestseller);
create index if not exists idx_variants_product on product_variants(product_id);
create index if not exists idx_variants_stock on product_variants(stock);
create index if not exists idx_images_product on product_images(product_id);
create index if not exists idx_orders_status on orders(status);
create index if not exists idx_orders_phone on orders(phone);
create index if not exists idx_orders_created on orders(created_at desc);
create index if not exists idx_order_items_order on order_items(order_id);
create index if not exists idx_stock_movements_variant on stock_movements(variant_id);
create index if not exists idx_admin_users_access_code on admin_users(access_code);
create index if not exists idx_admin_users_active on admin_users(is_active);
create index if not exists idx_outfits_slug on outfits(slug);
create index if not exists idx_outfits_active on outfits(is_active);
create index if not exists idx_outfit_images_outfit on outfit_images(outfit_id);
create index if not exists idx_outfit_items_outfit on outfit_items(outfit_id);
create index if not exists idx_outfit_items_product on outfit_items(product_id);
create index if not exists idx_page_views_created_at on page_views(created_at desc);
create index if not exists idx_page_views_page on page_views(page);
create index if not exists idx_page_views_path on page_views(path);

-- ############################################################
-- ROW LEVEL SECURITY
-- ############################################################
alter table products enable row level security;
alter table product_images enable row level security;
alter table product_variants enable row level security;
alter table categories enable row level security;
alter table wilaya_pricing enable row level security;
alter table orders enable row level security;
alter table order_items enable row level security;
alter table stock_movements enable row level security;
alter table site_settings enable row level security;
alter table site_content enable row level security;
alter table homepage_content enable row level security;
alter table admin_users enable row level security;
alter table outfits enable row level security;
alter table outfit_images enable row level security;
alter table outfit_items enable row level security;
alter table outfit_products enable row level security;
alter table outfit_variants enable row level security;
alter table promo_codes enable row level security;
alter table page_views enable row level security;
alter table push_subscriptions enable row level security;

-- Public read policies
create policy "Public read products" on products for select using (is_active = true);
create policy "Public read images" on product_images for select using (true);
create policy "Public read variants" on product_variants for select using (is_active = true);
create policy "Public read wilaya pricing" on wilaya_pricing for select using (true);
create policy "Public read categories" on categories for select using (true);
create policy "Public read site_content" on site_content for select using (true);
create policy "Public read homepage content" on homepage_content for select using (true);
create policy "Public read outfits" on outfits for select using (is_active = true);
create policy "Public read outfit_images" on outfit_images for select using (true);
create policy "Public read outfit_items" on outfit_items for select using (true);
create policy "Public read outfit_products" on outfit_products for select using (true);
create policy "Public read outfit_variants" on outfit_variants for select using (true);

-- Public insert (no login required)
create policy "Public insert orders" on orders for insert with check (true);
create policy "Public insert order_items" on order_items for insert with check (true);
create policy "Anyone can insert page views" on page_views for insert with check (true);
create policy "Anyone can insert push subs" on push_subscriptions for insert with check (true);

-- Admin full access (service key bypasses RLS anyway)
create policy "Admin manage products" on products for all using (true) with check (true);
create policy "Admin manage images" on product_images for all using (true) with check (true);
create policy "Admin manage variants" on product_variants for all using (true) with check (true);
create policy "Admin manage categories" on categories for all using (true) with check (true);
create policy "Admin manage orders" on orders for all using (true) with check (true);
create policy "Admin manage order_items" on order_items for all using (true) with check (true);
create policy "Admin manage stock_movements" on stock_movements for all using (true) with check (true);
create policy "Admin manage site_settings" on site_settings for all using (true) with check (true);
create policy "Admin manage site_content" on site_content for all using (true) with check (true);
create policy "Admin manage homepage content" on homepage_content for all using (true) with check (true);
create policy "Admin manage admin_users" on admin_users for all using (true) with check (true);
create policy "Admin manage outfits" on outfits for all using (true) with check (true);
create policy "Admin manage outfit_images" on outfit_images for all using (true) with check (true);
create policy "Admin manage outfit_items" on outfit_items for all using (true) with check (true);
create policy "Admin manage outfit_products" on outfit_products for all using (true) with check (true);
create policy "Admin manage outfit_variants" on outfit_variants for all using (true) with check (true);
create policy "Admin manage promo_codes" on promo_codes for all using (true) with check (true);
create policy "Admin manage push_subs" on push_subscriptions for all using (true) with check (true);

-- ############################################################
-- VIEWS
-- ############################################################
create or replace view orders_full as
select
  o.order_number,
  o.id,
  o.first_name || ' ' || o.last_name as customer_name,
  o.phone,
  o.wilaya_name,
  o.commune,
  o.delivery_type,
  o.home_address,
  o.shipping_cost,
  o.subtotal,
  o.total,
  o.status,
  o.notes,
  o.tracking_number,
  o.promo_code,
  o.promo_discount,
  o.created_at,
  json_agg(json_build_object(
    'product', oi.product_name,
    'image', oi.product_image_url,
    'size', oi.size,
    'color', oi.color,
    'qty', oi.quantity,
    'price', oi.unit_price,
    'total', oi.line_total
  )) as items
from orders o
left join order_items oi on oi.order_id = o.id
group by o.id
order by o.created_at desc;

drop view if exists products_with_stock;
create view products_with_stock as
select
  p.id,
  p.name,
  p.name_ar,
  p.category,
  p.base_price,
  p.sale_price,
  p.slug,
  p.is_active,
  p.is_bestseller,
  p.offer_enabled,
  p.sort_order,
  p.created_at,
  count(distinct pv.id) as variant_count,
  coalesce(sum(pv.stock), 0) as total_stock,
  (select cloudinary_url from product_images
   where product_id = p.id and is_primary = true limit 1) as primary_image
from products p
left join product_variants pv on pv.product_id = p.id
group by p.id
order by p.sort_order, p.name;

create or replace view outfits_with_items as
select
  o.id,
  o.name,
  o.name_ar,
  o.slug,
  o.description,
  o.description_ar,
  o.base_price,
  o.sale_price,
  o.is_active,
  o.is_bestseller,
  o.offer_enabled,
  o.sort_order,
  o.created_at,
  (select cloudinary_url from outfit_images
   where outfit_id = o.id and is_primary = true limit 1) as primary_image,
  json_agg(json_build_object(
    'product_id', oi.product_id,
    'variant_id', oi.variant_id,
    'quantity', oi.quantity,
    'product_name', p.name,
    'product_name_ar', p.name_ar,
    'product_price', p.base_price
  )) as items
from outfits o
left join outfit_items oi on oi.outfit_id = o.id
left join products p on p.id = oi.product_id
group by o.id
order by o.sort_order, o.name;

-- Analytics views
create or replace view daily_page_views as
select
  date(created_at) as date,
  page,
  count(*) as views,
  count(distinct path) as unique_paths
from page_views
group by date(created_at), page
order by date desc;

create or replace view total_page_stats as
select
  page,
  count(*) as total_views,
  min(created_at) as first_view,
  max(created_at) as last_view
from page_views
group by page
order by total_views desc;

-- ############################################################
-- DEFAULT DATA: Wilaya Pricing (58 wilayas)
-- ############################################################
insert into wilaya_pricing (wilaya_code, wilaya_name, home_price, post_price) values
('01','Adrar',1400,970),('02','Chlef',850,520),('03','Laghouat',950,620),
('04','Oum El Bouaghi',850,520),('05','Batna',900,520),('06','Bejaia',800,520),
('07','Biskra',950,620),('08','Bechar',1200,970),('09','Blida',600,470),
('10','Bouira',700,520),('11','Tamanrasset',1600,1120),('12','Tebessa',900,520),
('13','Tlemcen',900,570),('14','Tiaret',850,520),('15','Tizi Ouzou',750,520),
('16','Alger',500,370),('17','Djelfa',950,570),('18','Jijel',900,520),
('19','Setif',800,520),('20','Saida',900,570),('21','Skikda',900,520),
('22','Sidi Bel Abbes',900,520),('23','Annaba',850,520),('24','Guelma',900,520),
('25','Constantine',800,520),('26','Medea',800,520),('27','Mostaganem',900,520),
('28','Mila',850,570),('29','Mascara',900,520),('30','Ouargla',950,670),
('31','Oran',800,520),('32','El Bayadh',1100,670),
('34','Bordj Bou Arreridj',800,520),
('42','Tipaza',700,520),('43','Mila',900,520),('44','Ain Defla',900,520),
('45','Naama',1100,670),('46','Ain Temouchent',900,520),('47','Ghardaia',950,620),
('48','Relizane',900,520),('49','Timimoun',1400,970),
('51','Ouled Djellal',950,620),('52','Beni Abbes',1200,970),
('53','In Salah',1600,1120),('54','In Guezzam',1600,0),
('55','Touggourt',950,670),('57','El Meghaier',950,0),
('58','El Menia',1000,670)
on conflict (wilaya_code) do nothing;

-- ############################################################
-- DEFAULT DATA: Site Settings
-- ############################################################
insert into site_settings (key, value) values
('hero_video_url', ''),
('logo_url', ''),
('instagram_url', ''),
('whatsapp_phone', ''),
('email_address', ''),
('store_address', ''),
('working_hours', ''),
('zr_use_api_rates', 'false'),
('admin_username', '123456'),
('admin_password', '123456'),
('checkout_background', ''),
('products_page_eyebrow', ''),
('products_page_title', '')
on conflict (key) do nothing;

-- ============================================================
-- DONE! 20 tables created
-- ============================================================
