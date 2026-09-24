# Bookstore POS: Setup Guide
Everything runs on **your own** accounts (Supabase for the database, Vercel for hosting). Nothing is tied to the developer or any third-party AI account. Allow about 30 minutes.

## What you need
- A Supabase account (supabase.com) and a Vercel account (vercel.com), both signed up with **your** email
- A computer with Node.js installed (only for deploying), plus Chrome on the till tablet or PC
- Optional: a USB/Bluetooth barcode scanner (works as a keyboard — types the ISBN/barcode then Enter), a thermal receipt printer (80mm), an A4/laser printer for formal invoices, and your own domain

## 1. Create the database
1. Supabase: New project. Pick the region closest to you and save the database password.
2. Open **SQL Editor > New query**, paste all of `supabase/schema.sql`, click **Run**. (If you are upgrading an existing project, running the whole file again is safe — the new `create policy`/`grant` statements are additive; only re-run the parts you haven't applied yet if you get "already exists" errors on the original statements.)

## 2. Create the owner login
1. **Authentication > Users > Add user > Create new user**. Enter your email and password and tick **Auto confirm user**. The first user created is the **owner**.
2. **Authentication > Sign In / Providers**: turn **OFF** "Allow new users to sign up". This stops strangers creating staff accounts. (Anonymous customers ordering from a table QR code do **not** sign up — they never get an account; see section 9.)

## 3. Connect the app to your database
1. **Project Settings > API**. Copy the Project URL and the anon / publishable key.
2. Open `config.js` in a text editor and replace the two placeholder values. Save.

## 4. Put it online
In a terminal, inside this folder:
```
npm i -g vercel
vercel login
vercel --prod
```
Answer the questions: no framework ("Other"), no build command, keep the default output. Vercel prints your live address. To use your own domain, add it under the project's **Settings > Domains**.

## 5. First-time setup in the app
1. Open the address in Chrome, sign in, then open **Settings**: business name, address, phone, tax ID (GSTIN, optional), default GST suggestion, loyalty points rate, invoice prefix, currency symbol.
2. Open **Inventory**:
   - Add book genres, then add books (title, author, publisher, ISBN/barcode, cost price, sell price, stock, reorder threshold). Books are always GST-exempt (0%).
   - Add cafe categories, then add cafe items (name, category, price, GST% — 5% by default, optional cost price for margin reports). Tick "Track stock" only for items you want to count (e.g. bottled drinks), leave it off for things like brewed coffee.
   - Add stationery categories, then add stationery items (name, category, price, GST% — 18% by default). Stationery is always stock-tracked, like books.
   - If a book or stationery item has no ISBN/barcode, use **Generate barcode** in its edit form, then **Print barcode** to print a small sticker label (works with any printer set as default; a dedicated label printer gives the best size).
   - Add cafe **tables** and print a QR code for each one (see section 8).
3. Install the app: Chrome menu > **Install app** (phone: **Add to Home Screen**). **Sign in once while online**; after that it works offline.

## 6. Staff and roles
Add each staff member's login in Supabase (**Authentication > Users**) — the app cannot create a new auth user itself (that needs a service-role key, which never belongs in client code). New staff start as **cashier**. To change someone's role, open the **Staff** screen in the app (owner only) and pick their role from the dropdown — no SQL needed. (The old SQL method still works if you prefer it: `update profiles set role='manager' where email='name@example.com';`)

Role matrix:
| Action | Cashier | Manager | Owner |
|---|---|---|---|
| Sell, scan barcodes, hold/resume sales | ✔ | ✔ | ✔ |
| Print / WhatsApp a receipt or A4 invoice | ✔ | ✔ | ✔ |
| Confirm/reject table (QR) orders | ✔ | ✔ | ✔ |
| Open/close shift, count the drawer | ✔ | ✔ | ✔ |
| Line/order discounts | | ✔ | ✔ |
| Void a paid bill | | ✔ | ✔ |
| Process a return / exchange | | ✔ | ✔ |
| Add store credit to a customer | | ✔ | ✔ |
| Create/receive purchase orders, manage suppliers | | ✔ | ✔ |
| Add expenses, view reports, export CSV | ✔ | ✔ | ✔ |
| Add/edit/delete books, cafe & stationery items, categories, tables | | | ✔ |
| Import inventory CSV | | | ✔ |
| Edit business settings | | | ✔ |
| Change staff roles (Staff screen) | | | ✔ |

Note: several `kind`s (order, exp, book, cafeitem, stationery, supplier, po, shift, torder, customer) are writable by any signed-in staff member at the database level, because everyday actions (a sale, a return, a shift count, confirming a table order, loyalty points at checkout) need to touch them from any role. The app's own screens still restrict the sensitive actions (catalog edits, CSV import, discounts, voids, credit, POs, staff roles) as in the table above. See the comments in `supabase/schema.sql` if you want to lock this down further with security-definer RPCs.

## 7. Daily use
- **Sell**: switch between **Books**, **Cafe** and **Stationery** to browse that department, or just search/scan — the cart is shared, so one sale can mix all three. Scan or type a barcode/ISBN into the field and press Enter to add an item instantly. Tap **Hold** to park a sale while the customer keeps browsing, and resume it from **Orders**. On a phone, the cart lives in a bottom sheet — tap the "Cart" bar to open or close it; on tablet/desktop it's a fixed side panel.
- **Pay**: enter an amount (or tick "count by denomination" for cash to enter how many ₹500s, ₹200s, etc. the customer handed over) and tap Cash, UPI, Card or Store credit. Repeat to split the bill. If change is due, a second denomination grid records exactly what was handed back. **Complete and print** finishes the sale, updates stock, earns/redeems loyalty points, and prints the receipt.
- **Orders**: resume a held sale, reprint or WhatsApp a receipt, print a formal A4 invoice, void a paid bill (manager+).
- **Table Orders**: pending orders customers placed by scanning a table's QR code, grouped by table — load one into the cart to bill it, or reject it.
- **Returns**: manager+ only. Look up a bill by its invoice number, pick the item and quantity to return, choose the refund method — stock is put back automatically.
- **Shift**: open a shift with an opening float count (by denomination), and at the end of the day/shift use **Count drawer / Close shift** to enter the physical count — the app shows expected cash (opening float + cash sales − cash change − till expenses) vs counted, and the variance.
- **Reports**: a single day's figures (sales by department, GST breakdown, payment split, cash expected in drawer, items sold, low stock), plus a date-range section with a sales trend, best sellers, estimated profit margin, and two CSV export buttons (line items, and one row per invoice) for reconciling in accounting software.
- **Purchase orders**: (manager+) add/edit suppliers, create a PO against a supplier with line items and quantities, and receive it in full or in part — receiving updates stock and the item's cost price.

## 8. QR table ordering (cafe)
1. In **Inventory**, add a table (e.g. "T1") and click **Print QR**. Print one QR label per table and stick it on the table.
2. A customer scans it with their phone camera, which opens the shop's live menu (cafe items only) with no login required — they add items and tap **Send order to counter**.
3. Staff see it appear in the **Table Orders** tab, grouped by table. Tap **Load into cart** to bring the order into a normal sale and take payment as usual, or **Reject** it.
4. If the customer sends a second order from the same table (e.g. they want dessert after their coffee), it shows up as a second pending order for that table in the same group — nothing is overwritten.
5. This uses two narrowly-scoped anonymous (no-login) database policies — see the comment above them in `supabase/schema.sql` for exactly what an anonymous visitor can and cannot do (menu browsing + creating a pending order only; they can never read anyone else's data or mark an order paid).

## 9. CSV import / export
- **Import** (Inventory, owner only): pick a department and upload a `.csv` file. Books use columns `title,author,publisher,isbn,category,cost_price,sell_price,stock,reorder_level`; Cafe/Stationery use `name,category,price,cost_price,gst_percent,track_stock,stock,reorder_level` (header names are case-insensitive; `cost_price` and `reorder_level` may be left blank). Books match existing rows by ISBN; Cafe/Stationery match by name + category. New categories are created automatically. You get a preview (rows to add/update, any parse errors) before committing, and a final count afterwards. If your accounting software (e.g. Busy) exports a different column layout, just re-save/re-header the CSV to match these column names before importing — a from-scratch template mapping screen can be added later once you share a sample export.
- **Export** (Reports): pick a date range and download either a line-item CSV (one row per item sold — invoice no, date, department, item, category, qty, unit price, discount %, tax %, tax amount, line total, payment methods, customer, staff) or an invoice-summary CSV (one row per bill).

## 9b. Receipt printer
Set the thermal printer as the default in the operating system, paper size 80mm, margins none. For one-tap printing without the dialog, start Chrome with the `--kiosk-printing` option. Formal A4 invoices (Orders > Invoice) print to any regular A4/letter printer.

## 10. Test before opening day
1. Turn Wi-Fi off, make a sale that mixes a book, a cafe item and a stationery item. The header shows "1 unsynced".
2. Turn Wi-Fi on. It returns to "synced" within a minute.
3. On a second device, sign in and check the sale appears in **Orders**, and stock decreased in **Inventory**.
4. Process a test return and confirm stock goes back up.
5. Print a table QR code, open it in an incognito/private browser tab (to simulate a customer with no login), place a test order, and confirm it appears in **Table Orders**.
6. Open a shift, make a cash sale, close the shift and confirm the expected-vs-counted variance is ₹0 when you count exactly what should be there.

## 11. Backups and costs
- Take the Supabase **Pro** plan for a live shop: daily backups, and free projects pause after a week without use.
- Vercel's free Hobby plan is meant for non-commercial use; a business should use a paid plan (or another host such as Netlify or Cloudflare Pages). Check their current terms.
- Export data any time: **Table Editor > records > Export**, or use the in-app CSV export under Reports.

## 12. Troubleshooting
- "Setup needed": `config.js` still has the placeholders.
- "N unsynced" never clears: you are signed out or offline. Sign out, sign in again, and check the keys in `config.js`.
- Old screen after an update: close and reopen the app, or clear the site data in Chrome.
- Sign-in fails: check the user exists and is confirmed in Supabase.
- Barcode scanner doesn't add anything: check it's configured to send an Enter/Return after each scan, and that the barcode typed matches the ISBN/SKU saved on the item exactly.
- Table QR opens a blank/loading menu: check the shop is online and has at least one cafe category + item, and that `anon_read_menu`/`anon_ins_torder` policies from `supabase/schema.sql` were applied.
- Staff screen is empty or role changes don't save: only the owner can read/update `profiles`; confirm you're signed in as the owner account.

## Known limits
Tills sync through the internet, so two devices cannot share sales during a full outage (each keeps working alone and syncs later). No external ISBN lookup API (add books manually, or via CSV import — keeps the app free and offline-capable). No full kitchen-display workflow. Loyalty points/store credit and shift expected-cash figures assume a single shared till (not per-cashier drawers). Cashier limits are enforced in the app; the database only distinguishes owner-only writes from staff writes (see the note in section 6).
