-- Run once in Supabase > SQL Editor
create table profiles(id uuid primary key references auth.users on delete cascade,email text,role text not null default 'cashier' check(role in('owner','manager','cashier')));
create table records(id text primary key,kind text not null,data jsonb not null,deleted boolean not null default false,author uuid default auth.uid(),updated_at timestamptz not null default now());
create index on records(updated_at);
create index on records(kind);
alter table profiles enable row level security; alter table records enable row level security;
create function me() returns text language sql security definer stable set search_path=public as $$select role from profiles where id=auth.uid()$$;
create function on_signup() returns trigger language plpgsql security definer set search_path=public as $$begin insert into profiles(id,email,role) values(new.id,new.email,case when exists(select 1 from profiles) then 'cashier' else 'owner' end);return new;end$$;
create trigger t_signup after insert on auth.users for each row execute function on_signup();
create function touch() returns trigger language plpgsql as $$begin new.updated_at=now();return new;end$$;
create trigger t_touch before insert or update on records for each row execute function touch();
create policy p_read on profiles for select using(id=auth.uid() or me()='owner');
create policy p_set on profiles for update using(me()='owner');
create policy r_read on records for select using(me() is not null);
-- order/exp: any signed-in staff (selling & logging expenses is a cashier job).
-- book/cafeitem/stationery: any signed-in staff too -- a sale must be able to decrement stock on
-- checkout, and a return must be able to put it back. The app UI still restricts add/edit/delete of
-- the catalog itself (title, price, ...) to owner (stock-adjust screens allow manager). This is a
-- deliberate simplification matching the reference design's "kind in (...)" pattern; a stricter
-- deployment could replace this with a security-definer RPC that only touches the stock field.
-- supplier/po/suppayment: any signed-in staff at the DB level too, for the same simplification reason
-- -- the app UI restricts the Purchase (bills) screen to manager/owner. suppayment is a supplier-level
-- payment record (Busy Accounting-style restructuring): payments are tracked against the supplier's
-- running balance rather than one specific bill, since that matches how a shop actually pays down
-- credit with a supplier -- see recordSupplierPayment/supplierOutstanding in index.html.
-- shift: any signed-in staff -- cashiers and managers both open/close the drawer and log counts.
-- torder: any signed-in staff -- the Table Orders queue is confirmed/rejected by cashier+.
-- customer: any signed-in staff -- loyalty points/credit must update at checkout time for any
-- cashier; the app UI restricts manually adding store credit to manager/owner.
-- cat/settings/table: owner only (catalog structure and QR table setup are owner-managed).
-- rental/membership/checkin: any signed-in staff -- renting a book, selling/renewing a membership
-- and checking a member in/out are all front-desk (cashier) jobs, same tier as 'order'.
-- stockmove/audit: any signed-in staff may INSERT (the app writes these as an automatic side effect
-- of a sale, return, receive, or an owner/manager-only adjustment screen -- the UI, not the DB, is
-- what gates who can trigger an adjustment). Nothing about these two kinds is ever user-editable
-- after the fact in the app UI, so allowing UPDATE at the DB level costs nothing in practice, but we
-- still include them for symmetry with the existing "kind in (...)" pattern rather than inventing a
-- separate append-only policy shape.
create policy r_ins on records for insert with check(me() is not null and (kind in('order','exp','book','cafeitem','stationery','supplier','po','suppayment','shift','torder','customer','rental','membership','checkin','stockmove','audit') or me()='owner'));
create policy r_upd on records for update using(me() is not null and (kind in('order','exp','book','cafeitem','stationery','supplier','po','suppayment','shift','torder','customer','rental','membership','checkin','stockmove','audit') or me()='owner')) with check(me() is not null and (kind in('order','exp','book','cafeitem','stationery','supplier','po','suppayment','shift','torder','customer','rental','membership','checkin','stockmove','audit') or me()='owner'));
alter publication supabase_realtime add table records;
-- Promote a user:  update profiles set role='manager' where email='someone@example.com';

-- Anonymous customer table self-ordering (QR at each cafe table): a customer who scans a table's QR
-- code gets index.html?order=1&t=<tableId>, a public read-only menu view with NO login. They may
-- only ever: (a) browse the live cafe menu and business name (kind cafeitem/cat/settings), and
-- (b) create a brand-new, always-pending 'torder' row recording what they want to order. They can
-- never read any other record -- not other customers' orders, not sales totals, not staff data, not
-- books -- because the anonymous SELECT policy is scoped to exactly those three menu-only kinds, and
-- nothing else grants anon any SELECT at all. They can never mark an order paid/merged/deleted or
-- claim any other kind, because the INSERT policy's WITH CHECK pins kind='torder', deleted=false and
-- status='pending'; a confirmed sale only ever happens after a signed-in staff member reviews the
-- pending order in the Table Orders queue and loads it into a normal cart. A second scan/order from
-- the same table simply lands as another pending 'torder' row -- the staff queue groups pending
-- orders by table, so no anonymous UPDATE is needed or granted (anon gets INSERT + SELECT only).
grant select, insert on records to anon;
create policy anon_read_menu on records for select to anon using(kind in ('cafeitem','cat','settings') and deleted=false);
create policy anon_ins_torder on records for insert to anon with check(kind='torder' and deleted=false and coalesce(data->>'status','pending')='pending');

-- Anonymous printable-invoice bill sharing: the WhatsApp "Share bill" button now also sends a link
-- of the form index.html?inv=<orderId>, a public no-login page that fetches exactly that one order
-- and renders it with the same inv()/prnA4() the authenticated app uses, so a customer can reopen,
-- save or print their own bill later without needing an account. This is safe under the same trust
-- model as any "anyone with the link" share: order ids are random UUIDs (not sequential, not
-- guessable), so granting anon SELECT on kind='order' only ever exposes a bill to someone who was
-- already given its specific link -- it does not let anon list, enumerate or browse orders (no
-- anon SELECT without an id is possible; there is no anon index/listing endpoint), and it does not
-- expose any other kind (stock, staff, other customers, etc). Deliberately scoped narrower than the
-- table-ordering menu grant above: only 'order' is added here, nothing else.
create policy anon_read_order on records for select to anon using(kind='order' and deleted=false);
