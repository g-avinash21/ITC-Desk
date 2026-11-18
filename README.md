# ITC Desk

An offline working tool for GST input tax credit reversal under **Rules 42, 43 and 37 of the CGST Rules, 2017**. It reads TallyPrime exports, or GSTR-2B from the GST portal for clients on other software, puts each purchase ledger in a Rule 42 bucket with a reason, and works out the reversal for GSTR-3B Table 4(B)(1).

It is one HTML file. Open it in Chrome or Edge: nothing to install, and no data leaves the computer.

## What it does

- **Imports TallyPrime exports** (Excel or ASCII): GSTR-3B in Nature View, the reverse-charge voucher register and the columnar purchase register. Client, GSTIN and month are read from the files; unrelated files are refused.
- **Not on Tally?** Drop GSTR-2B from the GST portal (Excel or JSON: B2B, credit and debit notes, ISD and imports; ITC marked not available is kept out) and type the GSTR-3B 3.1 sales. Each supplier is one line, and the bucket chosen is remembered for that client next month. Or fill the Excel template from any software's purchase register (Busy, Marg, Zoho Books, Excel).
- **Buckets every ledger** (T1, T2, T3, T4, C2, Tc) with a written reason. Doubtful ones are marked **Check**. Section 17(5) items are recognised clause by clause, and reverse-charge services by their nature.
- **Rule 42 and 43** for a single period and month by month for the year, including the second proviso to Rule 42(1)(i) (a month without sales uses the last month that had sales) and the Rule 42(2) annual true-up.
- **Rule 37**: bills unpaid after 180 days.
- **Section 16(4) time limit**: bills older than the limit (30 November after their financial year) are kept out of T and shown in Table 4(D)(2); bills in their last month get a warning.
- **Whole year (for notices and the Rule 42(2) true-up)**: import a year's files and choose Full Year; the year's required reversal is set against what GSTR-3B reversed, with interest from 1 April after the year, and the reverse-charge credit that Rule 42 actually reverses.
- **Rule 43 catch-up**: for capital goods whose monthly Te was never reversed, the missed reversal for each earlier month of the 60, with interest from each due date.
- **Interest and penalty** estimates (sections 50, 73, 74 and 74A by financial year).
- **Checks**: GSTIN check digit, ITC against GSTR-3B Table 4(A), Nature View against Return View, sales that may be untaxed in 3.1(a).
- **GSTR-3B Table 4 as on the portal**: 4(A)(1) to (5), 4(B)(1) and (2), 4(C) and 4(D), by IGST, CGST, SGST and Cess, filled from the bills (reverse charge in 4(A)(3), imports in 4(A)(1), ISD in 4(A)(4)), with the GSTR-9 Table 7 split of the reversal.
- **Tally journals that land in 4(B)(1)**: the XML carries the Stat Adjustment (GST, Reversal of Input Tax Credit, with Rule 42(1)(m), Rule 43(1)(h) or Ineligible Credit), and the rate and taxable value of every tax line. Ledger names and the GST registration are editable to match your Tally, rate-wise or one per tax, and remembered for each client.
- **Output**: Excel working with live formulas (bills, ledgers, working, month-wise and true-up), a printable A4 working paper, the journal entries and Tally XML.
- **ICAI references**: beside each bucket's reason, the ICAI study material page or GST handbook page that supports it (for example *ICAI Blocked credit handbook p. 71* for cab hire). The link opens ICAI's website, where the publications are free to download.
- **Optional assistant**: a small AI model running on your own computer (llama.cpp with a Hugging Face model) can suggest buckets for ledgers marked Check. It only suggests; nothing changes until you accept. See `ITC assistant.bat`.

## How to use

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
3. Double-click `ITC Tally link.bat` and keep its window open. It uses Windows PowerShell, installs nothing, listens only on this computer, and refuses any request that would change Tally.
4. In ITC Desk: Auto > Find Tally > tick the companies > Work out selected. Open each result to review it like a normal import.

If Tally's GSTR-3B report cannot be read, the turnover is worked out from sales vouchers and marked for checking. **Download diagnostic** saves what Tally answered, to help fix a company that fails.

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

Concept, GST logic and testing by Avinash G. Code written with Claude (Anthropic). Excel reading by SheetJS Community Edition and the styled Excel export by xlsx-js-style (both Apache License 2.0); see `THIRD_PARTY_NOTICES.md`.

## Manual

`ITC-Desk-Manual.pdf` is a two-page guide (also inside the app: Notes and checklist > How ITC Desk works > Print manual or save as PDF).
