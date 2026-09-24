# Bookstore POS (Supabase + Vercel)
A single till for a bookstore with an attached cafe and stationery counter. One cart can mix books, cafe items and stationery.
Full instructions: **SETUP-GUIDE.md**.
Quick path: run `supabase/schema.sql`, add the owner user, edit `config.js`, then `vercel --prod`.

## What it is
- Single `index.html`, vanilla JS, no build step, no framework.
- Offline-first: sales keep working with no internet (IndexedDB), then sync to Supabase.
- PWA: installable, works offline after first sign-in (`manifest.json` + `sw.js`).
- Fully responsive: usable one-handed on a phone (bottom nav, cart as a bottom sheet), on a tablet till (portrait or landscape), and on desktop.
- Barcode/ISBN scanner support at checkout (a scanner just types digits + Enter into a focused field). Owner can auto-generate a barcode/SKU for a book or stationery item that doesn't have one and print a sticker label.
- Three departments in one till: **Books** (title, author, publisher, ISBN, genre, cost/sell price, stock, reorder threshold, GST-exempt), **Cafe** (name, category, price, per-item GST%, optional stock tracking), **Stationery** (name, category, price, per-item GST%, stock-tracked like books).
- Per-item GST: each item carries its own tax rate (books 0%, cafe 5% default, stationery 18% default, both editable per item) — the cart, receipt and reports compute tax per line and show a GST breakdown.
- Split payment: cash (with a denomination counter for tendered notes/coins and for change given back), UPI, card, and store credit.
- Customer accounts (by phone): purchase history, loyalty points (configurable ₹ per point), and a store-credit balance usable at checkout.
- Held/parked sales, returns with stock restock, daily and date-range reports, expenses, low-stock alerts.
- Shift / drawer cash counting: open a shift with an opening float count, close it with a physical count, and see the over/short variance against the expected cash figure.
- QR table ordering for the cafe: print a QR code per table; customers scan it and order from a public menu with no login; staff confirm pending orders into a normal sale from a **Table Orders** queue.
- CSV import (owner) for Books/Cafe/Stationery inventory, and CSV export (Reports) of sales — one row per line item and one row per invoice — for reconciling in accounting software like Busy.
- Purchase orders and supplier records: create a PO against a supplier, receive it in full or in part (updates stock and cost price), track PO status.
- 80mm thermal receipt printing plus a formal A4 invoice view with an itemized GST breakdown.

## Roles
- **Owner**: inventory (books/cafe/stationery + categories + tables), settings, staff roles, suppliers/POs, reports, voids.
- **Manager**: discounts, voids, returns/exchanges, purchase orders.
- **Cashier**: sell, hold sales, shift/drawer counts, confirm table orders.

First person to sign up becomes owner (see schema trigger). See SETUP-GUIDE.md for the full role matrix, QR table setup, and how to promote staff (now done in-app on the Staff screen).
