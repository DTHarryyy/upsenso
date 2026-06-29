# UPSENSO — BIR Compliance & Invoice Specification

> Status: **proposed (critical, pre-commercial-launch milestone)** · Branch:
> `claude/platform-features-roadmap-7bqdgn`
> This is the build spec for making UPSENSO's sales document legally valid in the
> Philippines. The **invoice itself is the centerpiece** — exact fields,
> computations, numbering, and the functional system behaviours BIR requires.

> ⚠️ **Not legal advice.** BIR rules changed materially with the **EOPT Act
> (RA 11976)** via **RR 7-2024 / RR 11-2024 / RMC 77-2024** and **RMO 24-2023**
> (eAccReg). Confirm the final field list, fees, and process with a **PH tax
> consultant + your RDO** before filing. This doc is the engineering plan; the
> consultant validates it.

---

## 0. The single most important rule (EOPT change)

Since 2024 the **principal sales document is the "INVOICE," not the "Official
Receipt."** For both goods *and* services, the document that proves a sale and
substantiates VAT is the **Sales Invoice**. UPSENSO must title its document
**"INVOICE"** (or "SALES INVOICE"), not "OFFICIAL RECEIPT." This is a renaming
*and* a behavioural change throughout the app. ([Grant Thornton — RR 7-2024](https://www.grantthornton.com.ph/insights/articles-and-updates1/tax-notes/clarification-on-the-invoicing-requirements-per-rr-no-7-2024-as-amended-by-rr-no-11-2024/), [PwC — EoPT invoicing clarified](https://www.pwc.com/ph/en/tax/tax-publications/taxwise-or-otherwise/2024/eopt-invoicing-clarified.html))

---

## 1. Two accreditations (recap)

1. **Supplier/software accreditation** — *UPSENSO* enrolls in **eAccReg**, passes
   a **live system demo to a Technical Working Group (TWG)**, and gets a
   Certificate of Accreditation (free to apply; ~20 working days). Major code
   changes to the sales/invoice logic require **re-accreditation**.
2. **Permit to Use / Acknowledgement Certificate** — *each customer business*
   registers its use of UPSENSO at its own RDO; the resulting **PTU/AC number +
   date must print on every invoice**.

So the invoice must carry **both** UPSENSO's accreditation details **and** the
customer's PTU/AC details.

---

## 2. THE INVOICE SPEC — mandatory fields

Every field below must appear (where applicable). "Have" = already in the data
model; "Need" = must be added. Sources: RR 7-2024/RMC 77-2024 (content),
RR 11-2004 (machine/functional).

### 2.1 Seller / header block

| # | Field | Rule | Status |
|---|---|---|---|
| 1 | Title **"INVOICE"** / "SALES INVOICE" | Must be prominent | **Need** (currently generic receipt) |
| 2 | Seller registered name | Required | Have (`businessName`) |
| 3 | Seller business address (registered) | Required | Have (`address`) |
| 4 | Seller **TIN incl. branch code** (12 digits) | Required, formatted `XXX-XXX-XXX-XXXXX` | Have (`tinNumber`) — add format validation |
| 5 | **VAT registration status** ("VAT REG TIN" / "NON-VAT") | Required statement | **Need** (`vatRegistered` flag) |
| 6 | Business style | **Optional** since EOPT (branding only) | Have-ish (`storeName`) |
| 7 | **Machine Identification Number (MIN)** | Per registered device | **Need** |
| 8 | **Serial number** of the software/printer | Required | **Need** |
| 9 | **Software accreditation number** (UPSENSO) | From eAccReg | **Need** (app-level constant) |
| 10 | **PTU / AC number + date issued** (customer) | Must appear on invoice | **Need** (`ptuNumber`, `ptuDate`) |

### 2.2 Buyer block (conditional)

| # | Field | Rule | Status |
|---|---|---|---|
| 11 | Buyer name | **Required if** B2B sale ≥ ₱1,000 to a VAT-registered buyer; optional for B2C | Partial (`customerName`) |
| 12 | Buyer address | Same condition | **Need** |
| 13 | Buyer TIN | Same condition | **Need** |

### 2.3 Transaction body

| # | Field | Rule | Status |
|---|---|---|---|
| 14 | **Invoice serial number** (sequential, min 6 digits, gapless per series) | Required + prominent | Partial (`invoiceNumber` — see §4) |
| 15 | Date (and time) of transaction | Required | Have (`createdAt`) |
| 16 | Per-line: quantity, unit cost, description | Required | Have (`transaction_items`) |
| 17 | Per-line VAT marker (VATable / Exempt / Zero-rated) | Required for breakdown | **Need** |
| 18 | Total amount due | Required | Have (`totalAmount`) |

### 2.4 VAT breakdown block (required for VAT-registered sellers)

| # | Field | Rule | Status |
|---|---|---|---|
| 19 | **VATable Sales** | Required | **Need** |
| 20 | **VAT-Exempt Sales** | Required | **Need** |
| 21 | **Zero-Rated Sales** | Required | **Need** |
| 22 | **VAT Amount (12%)** | Required, shown separately | Partial (`taxAmount` exists but not categorised) |
| 23 | **VATable + VAT + Exempt + Zero = Total** reconciliation | Required | **Need** |

### 2.5 Discounts block (Senior Citizen / PWD — legally mandated)

Governed by **RA 9994 (Senior Citizens)** and **RA 10754 (PWD)**: 20% discount
**and** VAT exemption for qualified persons. The invoice must capture:

| # | Field | Status |
|---|---|---|
| 24 | SC/PWD **ID number** | **Need** |
| 25 | SC/PWD **cardholder name + signature line** | **Need** |
| 26 | Discount amount line + the **VAT-exemption** applied | **Need** |
| 27 | Ordinary discounts (separate from SC/PWD) | Partial (`discountAmount`) |

### 2.6 Footer / accreditation block

| # | Field | Rule | Status |
|---|---|---|---|
| 28 | **Software provider details** — UPSENSO name, TIN, accreditation no., date issued, **valid until** | Required | **Need** (app constant) |
| 29 | Validity statement (e.g. "Valid for five (5) years") | Required | **Need** |
| 30 | "THIS SERVES AS YOUR SALES INVOICE" | Required | **Need** |

---

## 3. Functional system requirements (RR 11-2004)

These are *behaviours*, demonstrated live to the TWG — not just print fields:

- [ ] **Accumulated Grand Total (AGT)** — non-resettable, ≥10 digits, lifetime
      running total of gross sales per machine/series. Never decreases, never
      resets.
- [ ] **Sequential invoice numbering** — gapless per series, never reused (§4).
- [ ] **Z-Reading** — end-of-day report: beginning & ending invoice no., gross/
      net sales, VAT breakdown, discounts, voids/returns, AGT, Z-counter,
      reset-counter.
- [ ] **X-Reading** — shift/interim read without closing the day.
- [ ] **Tamper-proof** — no "training mode," no "no-sale" mode; recorded sales
      cannot be edited or deleted (corrections via void/credit only).
- [ ] **Void / return handling** — recorded as their own entries, reflected in
      Z-reading, never by deleting the original.
- [ ] **VAT computation** — correct inclusive/exclusive math + categorisation.
- [ ] **Backup + BIR audit access** — for cloud, data stored/retrievable for BIR
      revenue officers (record retention typically 10 years).

**UPSENSO is already ahead on tamper-proofing:** the **M1 hash-chained
append-only audit log** directly satisfies the "no edit/delete + audit trail"
requirement. Lean on it during the TWG demo.

---

## 4. Offline-first sequential numbering (the hard architectural part)

BIR expects **gapless, sequential** invoice numbers. UPSENSO is **offline-first
and multi-device** — a single global gapless sequence is impossible without
write-time coordination (same class of problem as the subscription-limit
overshoot). The compliant solution BIR already accommodates:

- **One invoice series per registered device/terminal**, tied to that device's
  **MIN + serial + PTU**. e.g. `MIN0001-000123`, `MIN0002-000045`.
- Each device increments **its own** sequence locally and gaplessly — fully
  offline-safe, no cross-device coordination, no collisions on sync.
- The existing `invoice_sequences` table is the base; make the sequence
  **keyed per device** (not just per business/branch), and bind the series
  prefix to the device's accreditation identity.
- Voids consume a number (the number still exists, marked void) — never reuse.

This keeps UPSENSO both **offline-first** and **BIR-sequential**.

---

## 5. Schema gap analysis (concrete columns to add)

### `receipt_settings` (business/seller config) — add:
- `documentTitle` (default `'INVOICE'`)
- `vatRegistered` (bool)
- `ptuNumber`, `ptuDateIssued` (customer's Permit to Use / AC)
- `minNumber`, `serialNumber` (per-device — may move to a `pos_devices` table)
- `businessStyle` (optional)
- *(note: the Drift table already has `currencySymbol`, `taxPercentage`,
  `vatInclusive`, `serviceChargePercentage` — but the `ReceiptSettings` domain
  entity does NOT map them yet. Reconcile the entity ↔ table first.)*

### `transactions` — add the VAT/discount breakdown:
- `vatableSales`, `vatExemptSales`, `zeroRatedSales`, `vatAmount`
- `scPwdDiscount`, `scPwdIdNumber`, `scPwdName`
- `buyerTin`, `buyerAddress` (for B2B ≥ ₱1,000)
- `seriesPrefix` + per-device sequence binding (§4)
- `isVoided` / `voidedByTransactionId`

### New tables:
- `pos_devices` — `id`, `businessId`, `minNumber`, `serialNumber`, `ptuNumber`,
  `seriesPrefix`, `accreditedAt`, `lastSeq`. (Drives §4 numbering + device cap
  shared with the subscription design.)
- `register_readings` — X/Z reading snapshots (counters, AGT, breakdown totals).
- `business_grand_total` — the non-resettable AGT per device.

> All additive, both Drift (schemaVersion bump + onUpgrade) and Supabase
> (migration + rollback), per `CLAUDE.md` safety rules.

---

## 6. Sample compliant invoice (80mm, illustrative)

```
            [LOGO]
        JUAN'S STORE INC.
   123 Rizal St., Cebu City, PH
     VAT REG TIN: 123-456-789-00000
        Business Style: Juan's

   MIN: MIN0001   SN: UPS-CEBU-01
   PTU No: FP012025  Issued: 2025-01-10

============ INVOICE ============
   Invoice No: MIN0001-000123
   Date: 2026-06-29 14:32
   Cashier: Maria S.
---------------------------------
 2  Coffee 1kg     @120.00   240.00 V
 1  Mug            @ 80.00    80.00 V
---------------------------------
 VATable Sales            285.71
 VAT-Exempt Sales           0.00
 Zero-Rated Sales           0.00
 VAT (12%)                 34.29
---------------------------------
 TOTAL DUE                320.00
 Cash                     500.00
 Change                   180.00
---------------------------------
 SC/PWD ID: __________  Name: ______
 Signature: _______________________
=================================
 This serves as your SALES INVOICE.
 Valid for five (5) years.

 Software: UPSENSO by Ledgidy
 TIN: 000-000-000-00000
 Accred No: AC-XXXXXXXX
 Issued: 2025-01-01  Valid until: 2030-01-01
```

(Fields shown for a VAT-registered seller; a NON-VAT seller omits the VAT
breakdown and prints "NON-VAT REG TIN".)

---

## 7. Build checklist (added to the execution sequence)

Sequence within this milestone:
1. [ ] Reconcile `ReceiptSettings` entity ↔ Drift table (map currency/tax/VAT).
2. [ ] Add seller BIR fields to `receipt_settings` (§5) + settings UI.
3. [ ] `pos_devices` table + device registration (online-only) carrying MIN/SN/PTU/series.
4. [ ] Per-device sequential numbering in `invoice_number_service` (§4).
5. [ ] VAT categorisation on products/lines + breakdown computation into `transactions` (§2.4).
6. [ ] SC/PWD discount capture + VAT-exemption math + invoice fields (§2.5).
7. [ ] Rename document to **INVOICE** across UI/print + footer accreditation block.
8. [ ] Accumulated Grand Total (non-resettable) + `business_grand_total`.
9. [ ] X-Reading / Z-Reading reports + `register_readings`.
10. [ ] Void/return as entries (no delete) — reconcile with refunds + audit chain.
11. [ ] Cloud backup + BIR audit-access provision.
12. [ ] BIR-format invoice renderer (thermal + PDF) matching §6.
13. [ ] Tests: numbering gaplessness per device, VAT math, SC/PWD math, AGT
        monotonicity, Z-reading totals reconcile.
14. [ ] Engage tax consultant → eAccReg enrollment → TWG demo.

---

## 8. Where it slots in the roadmap

This is a **dedicated pre-commercial-launch milestone (call it M-BIR)**. It is
**not** required for the capstone/demo, but it **is** the gate before selling to
any formal, registered business that must issue valid invoices. Recommended
timing: **after** the AI/CRM differentiator milestones (M2/M5) prove the product
is worth selling, and **before** the subscription/billing milestone (M7) goes
live — because the device/PTU model here (`pos_devices`) overlaps the device-cap
work in `UPSENSO_SUBSCRIPTION_AND_LIMITS_DESIGN.md`. Build them together.

**Re-accreditation constraint:** once accredited, **major changes to invoice/
sales logic require re-filing**. So freeze the BIR-critical surface, version it
carefully, and batch changes — don't ship continuous tweaks to it.

**Sources:** RR 7-2024 / RR 11-2024 / RMC 77-2024 (invoice content & EOPT),
RR 11-2004 (machine/functional), RMO 24-2023 (eAccReg process), RA 9994 / RA
10754 (SC/PWD). Validate all with a PH tax consultant before filing.
```
