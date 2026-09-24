# Full accounting engine — deferred for later

This is the list of "Busy/Tally-style" double-entry accounting features that were compared
against this POS earlier and deliberately **not built**, per the owner's own instruction:
"build only necessary thing for a bookstore for now." Nothing here is started. Revisit this
file when ready to scope that work as its own project.

## Out of scope (not built)

- General Ledger (chart of accounts, account-wise transaction history)
- Day Book / Cash Book / Bank Book
- Trial Balance
- Profit & Loss statement
- Balance Sheet
- Journal / Contra vouchers (manual double-entry postings)
- Bank reconciliation
- Fixed Assets register + depreciation
- Payroll
- GSTR-format return filing (GSTR-1/3B export)
- e-Invoice / e-Way Bill generation
- Multi-branch / multi-counter consolidation

## What this POS already does instead (the practical subset)

- Per-sale GST breakdown (CGST/SGST/IGST), GST-inclusive pricing
- B2B party accounts with GSTIN validation + CA-format tax invoices
- Supplier-level running balance + payments (cash/UPI/cheque/bank, with references)
- Day report, range report, expense tracking, stock valuation, dead stock, HSN-wise GST summary
- Shift/drawer cash counting with live till (denomination-level) and variance
- CSV exports: line items, invoice summary, and a Busy-compatible sales register

When the full double-entry engine is wanted, the natural next step is a proper `ledger` kind
(one row per debit/credit posting, account-tagged) that the existing `order`/`exp`/`suppayment`
records post into automatically — that's the right foundation for Trial Balance/P&L/Balance
Sheet, rather than trying to derive them from the current ad-hoc reports.
