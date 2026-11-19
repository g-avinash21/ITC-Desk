# ITC Desk: property tests. Random months, rules that must always hold. Run: python3 fuzz_invariants.py [page]
import asyncio, json, sys
from playwright.async_api import async_playwright
PAGE = sys.argv[1] if len(sys.argv) > 1 else 'file:///home/claude/fix/itc_reversal_workbench.html'
JS = r"""(seed)=>{
  let x = seed; const rnd = () => { x = (x * 1103515245 + 12345) % 2147483648; return x / 2147483648; };
  const out = [];
  for (let n = 0; n < 300; n++) {
    const B = ['T1','T2','T3','T4','C2'], rows = [];
    const k = 1 + Math.floor(rnd() * 12);
    for (let j = 0; j < k; j++) {
      const tax = Math.round(rnd() * 200000) / 100, inter = rnd() < 0.3;
      const half = Math.round(tax * 50) / 100;
      rows.push({ date: '2026-09-' + String(1 + j % 28).padStart(2, '0'), party: 'P' + j, ledger: 'L' + (j % 5), taxable: tax * 10,
        igst: inter ? tax : 0, cgst: inter ? 0 : half, sgst: inter ? 0 : half, in2B: rnd() > 0.1, bucket: B[Math.floor(rnd() * 5)], how: 'user' });
    }
    importedRows = rows;
    const a = Math.round(rnd() * 5e6), c = rnd() < 0.2 ? 0 : Math.round(rnd() * 5e6);
    $('imp_31a').value = a; $('imp_31c').value = c; if ($('imp_31b')) $('imp_31b').value = 0; if ($('imp_31e')) $('imp_31e').value = 0;
    try { pushImportToCalculator(false); calcAll(); } catch (e) { out.push({ n, err: String(e) }); continue; }
    const d = window._calc1 || {};
    const sumIn = rows.filter(r => r.in2B !== false).reduce((s, r) => s + r.igst + r.cgst + r.sgst, 0);
    const bad = [];
    const near = (p, q, tol) => Math.abs(p - q) <= (tol || 0.05);
    if (!(d.rev4B1 >= -0.005)) bad.push('reversal negative');
    if (!near(d.T, sumIn, 0.1)) bad.push(`T ${d.T} != tax in rows ${sumIn}`);
    if (d.C2 < -0.01) bad.push('C2 negative');
    if (!near(d.C2, d.T - d.T1 - d.T2 - d.T3 - d.T4, 0.1)) bad.push('C2 != T - T1..T4');
    if (d.F > 0 && !near(d.D1, d.C2 * d.E / d.F, 0.1)) bad.push(`D1 ${d.D1} != C2*E/F ${d.C2 * d.E / d.F}`);
    if (!(d.E > 0) && d.D1 > 0.005) bad.push('D1 with no exempt turnover');
    if (d.rev4B1 > d.T + (d.Te || 0) + 0.1) bad.push('reversal above total credit');
    if (d.ratio != null && (d.ratio < -1e-9 || d.ratio > 1 + 1e-9)) bad.push('ratio outside 0-1');
    if (bad.length) out.push({ n, bad, d: { T: d.T, T1: d.T1, T2: d.T2, T3: d.T3, T4: d.T4, C2: d.C2, E: d.E, F: d.F, D1: d.D1, D2: d.D2, rev: d.rev4B1 } });
  }
  return out;
}"""
async def main():
    async with async_playwright() as p:
        b = await p.chromium.launch(executable_path='/usr/bin/google-chrome', args=['--no-sandbox'])
        pg = await b.new_page(); errs = []; pg.on('pageerror', lambda e: errs.append(str(e)))
        pg.on('dialog', lambda d: asyncio.ensure_future(d.accept()))
        await pg.goto(PAGE); await pg.wait_for_timeout(600)
        fails = []
        for seed in (1, 7, 42):
            fails += await pg.evaluate(JS, seed)
        print('cases: 900, failures:', len(fails))
        for f in fails[:8]: print(json.dumps(f))
        print('page errors:', errs[:3])
        await b.close()
asyncio.run(main())
