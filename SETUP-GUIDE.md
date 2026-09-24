# Bookstore POS: Setup Guide
Everything runs on **your own** accounts (Supabase for the database, Vercel for hosting). Nothing is tied to the developer or any third-party AI account. Allow about 30 minutes.

## What you need
- A Supabase account (supabase.com) and a Vercel account (vercel.com), both signed up with **your** email
- A computer with Node.js installed (only for deploying), plus Chrome on the till tablet or PC
- Optional: a USB/Bluetooth barcode scanner (works as a keyboard — types the ISBN then Enter), a thermal receipt printer (80mm) and your own domain

## 1. Create the database
1. Supabase: New project. Pick the region closest to you and save the database password.
2. Open **SQL Editor > New query**, paste all of `supabase/schema.sql`, click **Run**.

## 2. Create the owner login
1. **Authentication > Users > Add user > Create new user**. Enter your email and password and tick **Auto confirm user**. The first user created is the **owner**.
2. **Authentication > Sign In / Providers**: turn **OFF** "Allow new users to sign up". This stops strangers creating accounts.

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
1. Open the address in Chrome, sign in, then open **Settings**: business name, address, phone, tax ID (optional, e.g. GSTIN), tax %, invoice prefix, currency symbol.
2. Open **Inventory**:
   - Add book genres, then add books (title, author, publisher, ISBN/barcode, cost price, sell price, stock, reorder threshold).
   - Add cafe categories, then add cafe items (name, category, price). Tick "Track stock" only for items you want to count (e.g. bottled drinks), leave it off for things like brewed coffee.
3. Install the app: Chrome menu > **Install app** (phone: **Add to Home Screen**). **Sign in once while online**; after that it works offline.

## 6. Staff and roles
Add each staff member in Supabase (**Authentication > Users**). They start as **cashier**. To make someone a manager or owner, run in SQL Editor:
`update profiles set role='manager' where email='name@example.com';`

Role matrix:
| Action | Cashier | Manager | Owner |
|---|---|---|---|
| Sell, scan barcodes, hold/resume sales | ✔ | ✔ | ✔ |
| Print / WhatsApp a receipt | ✔ | ✔ | ✔ |
| Line/order discounts | | ✔ | ✔ |
| Void a paid bill | | ✔ | ✔ |
| Process a return / exchange | | ✔ | ✔ |
| Add expenses, view daily reports | ✔ | ✔ | ✔ |
| Add/edit/delete books, cafe items, categories | | | ✔ |
| Edit business settings (tax %, name, ...) | | | ✔ |
| Change staff roles | | | ✔ (via SQL Editor) |

Note: stock quantities on `book` and `cafeitem` records are writable by any signed-in staff member at the database level, because a sale (any role) and a return (manager+) both need to adjust stock. The app's own screens still restrict adding/editing/deleting catalog entries to the owner. See the comment in `supabase/schema.sql` if you want to lock this down further (e.g. with a security-definer RPC).

## 7. Daily use
- **Sell**: switch between **Books** and **Cafe** to browse that department's categories, or just search/scan — the cart is shared, so one sale can include a book and a coffee. Scan or type an ISBN into the barcode field and press Enter to add a book instantly. Tap **Hold** to park a sale while the customer keeps browsing, and resume it from **Orders**.
- **Pay**: enter an amount and tap Cash, UPI or Card. Repeat to split the bill. The change is shown. **Complete and print** finishes the sale and updates stock.
- **Orders**: resume a held sale, reprint or WhatsApp a bill, void a paid bill (manager+).
- **Returns**: manager+ only. Look up a bill by its invoice number, pick the item and quantity to return, choose the refund method — stock is put back automatically.
- **Reports**: pick a date to see bookstore vs cafe sales, tax, cash/UPI/card totals, expenses, cash expected in the drawer, items sold, and low-stock items.

## 7b. Receipt printer
Set the thermal printer as the default in the operating system, paper size 80mm, margins none. For one-tap printing without the dialog, start Chrome with the `--kiosk-printing` option.

## 8. Test before opening day
1. Turn Wi-Fi off, make a sale that mixes a book and a cafe item. The header shows "1 unsynced".
2. Turn Wi-Fi on. It returns to "synced" within a minute.
3. On a second device, sign in and check the sale appears in **Orders**, and stock decreased in **Inventory**.
4. Process a test return and confirm stock goes back up.

## 9. Backups and costs
- Take the Supabase **Pro** plan for a live shop: daily backups, and free projects pause after a week without use.
- Vercel's free Hobby plan is meant for non-commercial use; a business should use a paid plan (or another host such as Netlify or Cloudflare Pages). Check their current terms.
- Export data any time: **Table Editor > records > Export**.

## 10. Troubleshooting
- "Setup needed": `config.js` still has the placeholders.
- "N unsynced" never clears: you are signed out or offline. Sign out, sign in again, and check the keys in `config.js`.
- Old screen after an update: close and reopen the app, or clear the site data in Chrome.
- Sign-in fails: check the user exists and is confirmed in Supabase.
- Barcode scanner doesn't add anything: check it's configured to send an Enter/Return after each scan, and that the ISBN typed matches the ISBN saved on the book exactly.

## Known limits
Tills sync through the internet, so two devices cannot share sales during a full outage (each keeps working alone and syncs later). No external ISBN lookup API (add books manually — keeps the app free and offline-capable). No full kitchen-display workflow (not needed for a bookstore/cafe counter). Cashier limits are enforced in the app; the database only distinguishes owner-only writes from staff writes (see the note in section 6 about stock fields).
