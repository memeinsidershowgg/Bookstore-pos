# Bookstore POS (Supabase + Vercel)
A single till for a bookstore with an attached cafe. One cart can mix books and cafe items.
Full instructions: **SETUP-GUIDE.md**.
Quick path: run `supabase/schema.sql`, add the owner user, edit `config.js`, then `vercel --prod`.

## What it is
- Single `index.html`, vanilla JS, no build step, no framework.
- Offline-first: sales keep working with no internet (IndexedDB), then sync to Supabase.
- PWA: installable, works offline after first sign-in (`manifest.json` + `sw.js`).
- Barcode/ISBN scanner support at checkout (a scanner just types digits + Enter into a focused field).
- Book inventory: title, author, publisher, ISBN, genre, cost/sell price, stock, reorder threshold, low-stock report.
- Cafe inventory: name, category, price, optional stock tracking.
- Split payment (cash/UPI/card), held/parked sales, returns with stock restock, configurable tax %, daily reports split by department, expenses.

## Roles
- **Owner**: inventory (books + cafe items + categories), settings, staff roles, reports, voids.
- **Manager**: discounts, voids, returns/exchanges.
- **Cashier**: sell and hold sales only.

First person to sign up becomes owner (see schema trigger). See SETUP-GUIDE.md for the full role matrix and how to promote staff.
