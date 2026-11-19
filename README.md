# ITC Desk

**Version 1.0.0 · Last updated 19 November 2026**

An offline working tool for GST input tax credit reversal under **Rules 42, 43 and 37 of the CGST Rules, 2017**. It reads TallyPrime exports, or GSTR-2B from the GST portal for clients on other software, puts each purchase ledger in a Rule 42 bucket with a reason, and works out the reversal for GSTR-3B Table 4(B)(1).

It is one HTML file. Open it in Chrome or Edge: nothing to install, and no data leaves the computer.

## What it does

- **Imports TallyPrime exports** (Excel or ASCII): GSTR-3B in Nature View, the reverse-charge voucher register and the columnar purchase register. Client, GSTIN and month are read from the files; unrelated files are refused.
- **Not on Tally?** Drop GSTR-2B from the GST portal (Excel or JSON: B2B, credit and debit notes, ISD and imports; ITC marked not available is kept out) and type the GSTR-3B 3.1 sales. Each supplier is one line, and the bucket chosen is remembered for that client next month. Or fill the Excel template from any software's purchase register (Busy, Marg, Zoho Books, Excel).
- **Buckets every ledger** (T1, T2, T3, T4, C2, Tc) with a written reason. Doubtful ones are marked **Check**. Section 17(5) items are recognised clause by clause, and reverse-charge services by their nature.
- **Rule 42 and 43** for a single period and month by month for the year, including the second proviso to Rule 42(1)(i) (a month without sales uses the last month that had sales) and the Rule 42(2) annual true-up.
- **Rule 37**: bills unpaid after 180 days, from Tally's Overdue Payables or Outstandings > Payables (Excel or XML). That export has no GST, so ITC is never guessed: each bill's ITC is typed, set from one rate, or read from the purchase voucher in Auto mode.
- **Section 16(4) time limit**: bills older than the limit (30 November after their financial year) are kept out of T and shown in Table 4(D)(2); bills in their last month get a warning.
- **Whole year (for notices and the Rule 42(2) true-up)**: import a year's files and choose Full Year; the year's required reversal is set against what GSTR-3B reversed, with interest from 1 April after the year, and the reverse-charge credit that Rule 42 actually reverses.
- **Rule 43 catch-up**: for capital goods whose monthly Te was never reversed, the missed reversal for each earlier month of the 60, with interest from each due date.
- **Interest and penalty** estimates (sections 50, 73, 74 and 74A by financial year).
- **Checks**: GSTIN check digit, ITC against GSTR-3B Table 4(A), Nature View against Return View, sales that may be untaxed in 3.1(a).
- **GSTR-3B Table 4 as on the portal**: 4(A)(1) to (5), 4(B)(1) and (2), 4(C) and 4(D), by IGST, CGST, SGST and Cess, filled from the bills (reverse charge in 4(A)(3), imports in 4(A)(1), ISD in 4(A)(4)), with the GSTR-9 Table 7 split of the reversal.
- **Tally journals that land in 4(B)(1)**: the XML carries the Stat Adjustment (GST, Reversal of Input Tax Credit, with Rule 42(1)(m), Rule 43(1)(h) or Ineligible Credit), and the rate and taxable value of every tax line. CGST and SGST are always equal, with any paisa difference on an editable Round Off line, so Tally does not list the journal under Uncertain Transactions. Ledger names and the GST registration are editable to match your Tally, rate-wise or one per tax, and remembered for each client.
- **Output**: Excel working with live formulas (bills, ledgers, working, month-wise and true-up), a printable A4 working paper, the journal entries and Tally XML.
- **The rule in simple words**: beside each bucket's reason, a plain explanation for office staff (what the rule says, an example, and what ITC Desk does), with the ICAI study material or GST handbook named as the source.
- **RCM guide tab, with Guru**: type a bill in plain words ("rent paid to unregistered landlord for godown", "audit fees", "lorry freight with LR") and Guru, the built-in helper, picks the reverse charge case, asks only the questions that matter and answers in two steps: is GST payable at all, then who pays it, with what to mark in Tally and the notification. Guru works offline from the rules built into ITC Desk; when a bill is not covered, it says so instead of guessing. The full list of reverse charge cases (26, searchable) opens with one click.
- **Guru, on every tab (hidden until you call it)**: click **Ask Guru** at the top right, or press **Alt+G**. Guru keeps track of the month's working while hidden and, when opened, tells you the next step, explains the reversal figure line by line, lists the ledgers to check, suggests reasons for a difference from Tally (debit notes, other months, credit already reversed), and answers "is this bill reverse charge?". Every reverse charge answer shows how to enter it in TallyPrime and report it in GSTR-3B (forward charge: Table 4(A)(5); reverse charge: 3.1(d) paid in cash and 4(A)(3); exempt: Table 5). Text only. Guru answers from ITC Desk's own figures and built-in rules; if ITC assistant.bat is running, the small model on your PC can answer other questions too, marked as such. Nothing goes online.
- **Flags likely reverse charge mistakes**: a ledger such as "Accounting Charges RCM" marked reverse charge in Tally is shown with a Check note (accounting, audit and consultancy fees are forward charge; only an advocate's legal fees are reverse charge). The working itself is not changed.
- **Optional assistant**: a small AI model running on your own computer (llama.cpp with a Hugging Face model) can suggest buckets for ledgers marked Check. It only suggests; nothing changes until you accept. See `ITC assistant.bat`.

## How to use

A step bar at the top of every tab shows the month's path and what to do next: **Auto** (or **Import** for files) > **Review ledgers** > **Single period** > **Capital goods** > **Post in Tally**. Choose *TallyPrime (Auto)* or *Files (Manual)* in it; steps not needed this month are struck out with the reason.

1. Download `index.html` and open it in Chrome or Edge.
2. In TallyPrime, export for one month, as Excel:
   - **GSTR-3B, Nature View**: Gateway of Tally > Display More Reports > GST Reports > GSTR-3B, Alt+F2 for the month, switch to Nature View, Alt+E > Export.
   - **Reverse-charge voucher register**: in GSTR-3B (Return View), open 3.1(d) and export.
   - **Purchase register, columnar**: Display More Reports > Account Books > Purchase Register, columnar view, export.
3. Drop the three files on the Import tab. Read the notes, settle every ledger marked **Check**, and open **Single period** for the reversal.
   Not on Tally: drop GSTR-2B instead (gst.gov.in > Returns Dashboard > month > GSTR-2B > View > Download Excel) and type Table 3.1 of GSTR-3B in the turnover boxes, or use **Download template**.
4. On the **Vouchers** tab, type the ledger names and GST registration as in Tally, click **Download Tally XML**, and import it in Tally (Alt+O > Import > Transactions). Check GSTR-3B Table 4(B)(1) afterwards.
5. **Save backup** keeps a client's work as a file; the page itself starts empty every time it is opened.

## Auto mode (from TallyPrime, test version)

The **Auto** tab reads straight from TallyPrime and works out every loaded company in one batch, then stops for review. Nothing is posted to Tally.

1. In each TallyPrime window: F1 > Settings > Connectivity > Client/Server configuration: TallyPrime is acting as **Both**, Port **9000** (a second window 9001, and so on).
2. Load the companies (F3, Spacebar to select several). Only loaded companies can be read.
3. Open ITC Desk by double-clicking `ITC Desk.bat` (keep it in the same folder as the HTML file). It opens the page and starts the Tally link in the background, with no extra window. It uses Windows PowerShell, installs nothing, listens only on this computer, and refuses any request that would change Tally. The Auto tab shows which Tally windows and companies are connected, and a "Stop link" button switches the link off.
   The first time, it offers to start the link whenever Windows starts, so Auto mode always finds it.
4. ITC Desk opens on the Auto tab. Follow its numbered steps: 1 choose the month (asked every time, never assumed), 2 Find Tally, 3 tick the companies, 4 Work out selected, 5 Check with Tally's GSTR-3B before filing, 6 review each company. A progress bar shows each company and each step. Open each result to review it like a normal import.

What Auto does for each company, and how it checks itself:

- **Purchases and credit** from the vouchers; reverse charge credit worked out from each reverse-charge line at the rate Tally stores on it; round-off lines get no tax.
- **Turnover item by item**, from the taxability Tally stores on each stock item. Exempt items sold on invoices that also charge GST are counted as exempt, as Rule 42 requires; Tally's own GSTR-3B counts them in 3.1(a).
- **Section 17(3)** items (reverse charge, securities, land, duty credit scrips) are found from the ledgers and kept out of turnover as the law requires.
- **Capital goods (Rule 43)**: assets bought with credit in the last 60 months are found and added to the Capital goods register.
- **Rule 37**: bills of this month's suppliers unpaid after 180 days, with the ITC from each purchase voucher.
- **Ledger names read from Tally**: the journal uses your own GST, reversal and round-off ledgers, recognised even when named differently ("Input CGST", "CGST @2.5%", "ITC reversal", "Roundoff"). If the reversal ledger does not exist in Tally, you are told before posting.
- **Second opinion**: Tally's own ledger totals for the month (GST, sales, purchase and expense ledgers) must equal the vouchers read, to the paisa. Any difference is listed by ledger.
- **Purchase ledgers verified from stock items**: when every item bought with GST was sold only with GST that month, the T4 bucket is confirmed without asking.
- **Check with Tally's GSTR-3B**: choose one or many GSTR-3B Excel exports (detailed view, Alt+F5); each file finds its company by GSTIN. A file for another GSTIN, another Tally company or year, another month or part of a month, or any report other than GSTR-3B itself is refused with the reason, and nothing changes. Differences are shown and explained.
- The month is checked against the dates Tally holds for each company (books from, last entry), not its name, so a company named "2025-2026" that carries on into 2026-27 is read for the month you chose; Stop works at once, and vouchers are read a few days at a time so Tally stays responsive.

**Download diagnostic** saves every request made to Tally with its timing, to help fix a company that fails.

## Optional assistant (offline AI)

Double-click `ITC assistant.bat` on Windows. The first run installs llama.cpp through winget and downloads a model from Hugging Face; later runs work offline. Choose by your computer:

| Key | Model | Size | For |
|---|---|---|---|
| S | Qwen3 4B Instruct | 2.5 GB | Recent i5 or better |
| M | LFM2.5 1.2B Instruct | 0.7 GB | Any 8 GB PC |
| L | Qwen2.5 1.5B Instruct | 1 GB | Light |
| T | LFM2 350M | 0.2 GB | Old PCs; fastest, weakest |

Keep its window open, then open "Assistant on this computer" in ITC Desk and click Test.

## Limits

- Business type is inferred from the client's name and the ledgers; the **Check** marks show where a fact only the client can confirm decides the bucket.
- Not covered: quarterly (QRMP) filers, builders under Rule 42(3) to (6), several GSTINs in one export.
- Tested on TallyPrime exports and on GSTR-2B files built to the portal's published layout; Tally ERP 9 and other software's own exports are untested. GSTR-2B amendments (B2BA, CDNRA) are not read.

## Disclaimer

ITC Desk is a computation and working-paper aid, not a legal opinion or a statutory portal. Have a Chartered Accountant or GST professional verify the buckets and workings before filing GSTR-3B, GSTR-9 or DRC-03.

## Credits

Concept, GST logic and testing by Avinash G. Code written with Claude (Anthropic). Excel reading by SheetJS Community Edition and the styled Excel export by xlsx-js-style (both Apache License 2.0); see `THIRD_PARTY_NOTICES.md`. The RCM search box is adapted from a Uiverse.io design (MIT). Ideas, not code, came from Butler (CherrysButler), wallie-V2 (Alradyin) and personality (PigeonPosse); Tally steps follow TallyPrime Help.

## Manual

`ITC-Desk-Manual.pdf` is a two-page guide (also inside the app: Notes and checklist > How ITC Desk works > Print manual or save as PDF).
