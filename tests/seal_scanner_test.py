import asyncio, json, sys
from playwright.async_api import async_playwright
PAGE = sys.argv[1] if len(sys.argv) > 1 else 'file://' + __import__('os').path.abspath(__import__('os').path.join(__import__('os').path.dirname(__file__), '..', 'index.html')) + ''
async def main():
    async with async_playwright() as p:
        b = await p.chromium.launch(); pg = await b.new_page()
        errs = []; pg.on('pageerror', lambda e: errs.append(str(e)))
        pg.on('dialog', lambda d: asyncio.ensure_future(d.accept()))
        await pg.goto(PAGE); await pg.wait_for_timeout(800)
        r = await pg.evaluate("ITCDeskTests.run()")
        print('TESTS', r)
        cases = await pg.evaluate("ITCDeskTests.cases.filter(c=>!c.pass)")
        for c in cases: print('  FAIL', c)
        # supplier scanner + bill search + trading inelig warning
        await pg.evaluate("""()=>{ flowSetMode && flowSetMode('manual'); showTab(0);
          importedRows=[
           {date:'2026-09-02',party:'Bharti Airtel Ltd',ledger:'Purchase 18%',taxable:1000,igst:180,cgst:0,sgst:0,in2B:true,bucket:'T4',how:'auto',inv:'AIR/551'},
           {date:'2026-09-03',party:'Sri Multiplast Packagers',ledger:'Purchase 18%',taxable:1000,igst:0,cgst:90,sgst:90,in2B:true,bucket:'T4',how:'auto',vno:'12'},
           {date:'2026-09-04',party:'Jiofi Traders',ledger:'Purchase 18%',taxable:1000,igst:0,cgst:90,sgst:90,in2B:true,bucket:'T4',how:'auto'},
           {date:'2026-09-05',party:'Ramesh Rice Mill',ledger:'Purchase 5%',taxable:10000,igst:0,cgst:250,sgst:250,in2B:true,bucket:'T3',inelig:true,how:'tally'},
           {date:'2026-09-06',party:'Kumar Stationers',ledger:'Office Expenses',taxable:500,igst:0,cgst:45,sgst:45,in2B:true,bucket:'T3',inelig:true,how:'tally'}];
          renderImporterTable(); pushImportToCalculator(false); }""")
        txt = await pg.inner_text('#impLedgerSummary')
        print('SCANNER', [l for l in txt.split('\n') if 'look' in l])
        print('SETUPWARN', txt.count('Tally setup warning'))
        await pg.fill('#billSearch','multiplst'); await pg.wait_for_timeout(100)
        print('SEARCH', await pg.evaluate("document.querySelectorAll('#impBody tr').length"), await pg.inner_text('#billSearchCount'))
        await pg.fill('#billSearch','AIR/551'); print('SEARCH2', await pg.evaluate("document.querySelectorAll('#impBody tr').length"))
        await pg.fill('#billSearch',''); 
        # seal
        await pg.evaluate("$('meta_name').value='Test Co';$('meta_gstin').value='29AAAAA0000A1Z5';calcAll()")
        await pg.wait_for_timeout(200)
        await pg.evaluate("sealFinalise()"); await pg.wait_for_timeout(400)
        print('SEALBAR', (await pg.inner_text('#sealBar'))[:90])
        print('LOCKED', await pg.evaluate("[$('T').disabled,$('meta_name').disabled,$('billSearch').disabled,$('sealBtn').disabled,$('t1').disabled]"))
        await pg.evaluate("clearAllSheets()"); print('CLEAR BLOCKED', await pg.evaluate("importedRows.length"))
        h = await pg.evaluate("SEAL.seal.hash"); print('HASHLEN', len(h))
        js = await pg.evaluate("sha256Js(new TextEncoder().encode(SEAL.seal.payload))"); print('JS==WEBCRYPTO', js == h, await pg.evaluate("sha256Js(new TextEncoder().encode('abc'))")=='ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad')
        # tamper via console then check mismatch
        await pg.evaluate("$('meta_name').value='Other';calc1()"); await pg.wait_for_timeout(300)
        print('MISMATCH', (await pg.inner_text('#sealBar'))[:60])
        await pg.evaluate("$('meta_name').value='Test Co';calc1()"); await pg.wait_for_timeout(300)
        print('MATCH AGAIN', (await pg.inner_text('#sealBar'))[:40])
        st = await pg.evaluate("JSON.stringify(collectState())")
        await pg.evaluate("sealReopen()"); await pg.wait_for_timeout(100)
        print('REOPEN', await pg.evaluate("[!!SEAL.seal, SEAL.history.length, $('T').disabled]"))
        await pg.evaluate("s=>applyState(JSON.parse(s))", st); await pg.wait_for_timeout(400)
        print('RESTORED SEAL', await pg.evaluate("[!!SEAL.seal, $('T').disabled]"), (await pg.inner_text('#sealBar'))[:40])
        await pg.evaluate("printReport=printReport; document.getElementById('printReport')"); 
        blk = await pg.evaluate("sealPrintBlock()"); print('PRINTBLOCK', 'Sealed' in blk)
        # bank Tsp UI
        await pg.evaluate("sealReopen()")
        await pg.evaluate("$('meta_cat').value='bank';calc1()")
        print('TSP VISIBLE', await pg.evaluate("!$('bankSpBox').classList.contains('hide')"))
        print('ARIA', await pg.evaluate("[document.querySelector('.tabs').getAttribute('role'), $('t1').getAttribute('aria-selected'), document.querySelectorAll('[role=tab]').length]"))
        await pg.evaluate("showTab(1)"); print('ARIA2', await pg.evaluate("$('t1').getAttribute('aria-selected')"))
        print('ERRORS', errs)
        await b.close()
asyncio.run(main())
