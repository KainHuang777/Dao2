"""Preserve the exact starting workspace evidence for TALENT batch closure."""
from pathlib import Path
import hashlib, json, shutil, subprocess, sys, re
ROOT=Path(__file__).resolve().parents[1]
D=ROOT/'docs/verification/artifacts/content-p2-talents-closure'
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def save(name,data): (D/name).write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')
def backup():
    D.mkdir(parents=True,exist_ok=True)
    assert not (D/'before.json').exists(), 'Do not replace baseline'
    files=list((ROOT/'docs/verification/artifacts').rglob('*.json'))+list((ROOT/'src/verification').glob('*.json'))
    hashes={}
    for p in files:
        if D in p.parents: continue
        name=p.relative_to(ROOT).as_posix(); target=D/'before-flat'/(hashlib.sha256(name.encode()).hexdigest()+'.json')
        target.parent.mkdir(parents=True,exist_ok=True); shutil.copyfile(p,target); hashes[name]=sha(p)
    save('before.json',hashes)
    save('backup-integrity.json',{'count':len(hashes),'failures':[n for n,h in hashes.items() if sha(D/'before-flat'/(hashlib.sha256(n.encode()).hexdigest()+'.json'))!=h]})
    (D/'git-start.txt').write_bytes(subprocess.check_output(['git','status','--short'],cwd=ROOT))
    save('closure-decision.json',{'date':'2026-10-25','task':'CONTENT-P2-TALENT','user_quote':'接受三圖與目前節奏','art':'ACCEPTED','pacing':'ACCEPTED','batch':'IN_PROGRESS'})
    for name in ['assets/ui/reincarnation-painted/talent2-manifest.json','docs/verification/artifacts/content-p2-talents-ui/art-manifest.json']:
        p=ROOT/name; obj=json.loads(p.read_text(encoding='utf-8-sig')); obj['acceptance']='ACCEPTED'; obj['acceptance_date']='2026-10-25'; obj['user_quote']='接受三圖與目前節奏'; p.write_text(json.dumps(obj,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print('BACKUP',len(hashes))
def restore():
    hashes=json.loads((D/'before.json').read_text(encoding='utf-8')); changed=[]
    accepted='docs/verification/artifacts/content-p2-talents-ui/art-manifest.json'
    for name,h in hashes.items():
        if name==accepted: continue
        p=ROOT/name
        if not p.exists() or sha(p)!=h:
            if p.exists():
                target=D/'generated'/name; target.parent.mkdir(parents=True,exist_ok=True); shutil.copyfile(p,target)
            shutil.copyfile(D/'before-flat'/(hashlib.sha256(name.encode()).hexdigest()+'.json'),p); changed.append(name)
        assert sha(p)==h,name
    for p in D.glob('*command.log'):
        m=re.search(r'\[LOGS\] ([^\r\n]+)',p.read_text(encoding='utf-8-sig'))
        if m and Path(m[1].strip()).exists(): shutil.copytree(m[1].strip(),D/'logs'/Path(m[1].strip()).name,dirs_exist_ok=True)
    save('restored.json',{'checked':len(hashes)-1,'changed_archived_restored':changed,'intentional_acceptance_metadata':accepted})
    print('RESTORED',len(changed))
def sources():
    paths=[p for folder in ['src','content','assets','scenes'] for p in (ROOT/folder).rglob('*') if p.is_file() and 'src/verification/' not in p.relative_to(ROOT).as_posix()]
    save('candidate-source-hashes.json',{p.relative_to(ROOT).as_posix():sha(p) for p in paths})
    print('SOURCE HASHES',len(paths))
def reconcile():
    hashes=json.loads((D/'before.json').read_text(encoding='utf-8')); rows=[]
    for p in (D/'before').rglob('*.json'):
        name=p.relative_to(D/'before').as_posix()
        if name not in hashes: continue
        h=sha(p)
        if hashes[name]!=h:
            rows.append(name); shutil.copyfile(p,D/'before-flat'/(hashlib.sha256(name.encode()).hexdigest()+'.json')); hashes[name]=h
    save('before.json',hashes)
    save('baseline-reconciliation.json',{'earlier_partial_backup_used':rows,'reason':'First backup was interrupted by Windows path length after copying these files; earliest byte snapshots take precedence.'})
    save('backup-integrity.json',{'count':len(hashes),'failures':[n for n,h in hashes.items() if sha(D/'before-flat'/(hashlib.sha256(n.encode()).hexdigest()+'.json'))!=h]})
    print('EARLIEST BASELINE RECONCILED',len(rows))
def finalize():
    assert (D/'full-exit.txt').read_text().strip()=='0','L3 must finish successfully before DONE'
    assert json.loads((D/'browser-observations.json').read_text(encoding='utf-8'))['purchase_recovery_verified']
    log=(D/'full-command.log').read_text(encoding='utf-8-sig')
    initial=len(re.findall(r'\[PASS:initial\]',log)); retries=re.findall(r'\[PASS:serial-retry\] ([^ ]+)',log)
    assert initial+len(retries)==121
    summary=f'2026-10-25 **CONTENT-P2-TALENT DONE（三圖與目前節奏人工接受；L3／桌面Web有界）**：使用者回覆「接受三圖與目前節奏」。L3完整尺寸121／121唯一runner最終通過（{initial}初跑＋{len(retries)}串行重試）；原失敗與中斷紀錄保留。正常候選build/web-content-p2-talents、Brotli／四BGM及三橫式滑鼠、拓脈25→15拒寫／再重試／恢復／重載已驗。4173份JSON基準備份核對，變動先封存後逐字復原；三圖metadata明確接受。未改規則／PNG／玩家進度，未commit/push。見[整批驗收](LINK)。本階段停止；下一大型任務請New Chat指定，不自動開其他P2／P3。'
    for name in ['README.md','ROADMAP.md','docs/ai-handoff.md','docs/development-status.md','docs/25-system-content-expansion-plan.md','docs/36-content-p2-talent-design.md']:
        p=ROOT/name; link='docs/verification/content-p2-talents-closure.md' if '/' not in name else 'verification/content-p2-talents-closure.md'
        p.write_text(summary.replace('LINK',link)+'\n\n'+p.read_text(encoding='utf-8-sig'),encoding='utf-8')
    p=ROOT/'docs/design-data/content-p2-talents-proposal.json'; proposal=json.loads(p.read_text(encoding='utf-8-sig'))
    save('proposal-before-closure.json',proposal)
    proposal['implementation_status']='CONTENT-P2-TALENT DONE — L3 and bounded desktop Web closure'
    proposal['art_proposal']['status']='GENERATED_INTEGRATED_ACCEPTED'
    proposal['art_proposal']['acceptance']='ACCEPTED'
    proposal['art_acceptance']='ACCEPTED'; proposal['pacing_acceptance']='ACCEPTED'; proposal['acceptance_date']='2026-10-25'; proposal['acceptance_user_quote']='接受三圖與目前節奏'
    p.write_text(json.dumps(proposal,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    decision=json.loads((D/'closure-decision.json').read_text(encoding='utf-8')); decision['batch']='DONE'; save('closure-decision.json',decision)
    p=ROOT/'docs/verification/content-p2-talents-ui.md'
    p.write_text('2026-10-25 更新：三圖／卡片與目前節奏已由使用者明確接受，整批L3與桌面Web收尾完成，見[整批驗收](content-p2-talents-closure.md)。下方2026-10-24待接受文字保留為當時狀態。\n\n'+p.read_text(encoding='utf-8-sig'),encoding='utf-8')
    p=ROOT/'docs/verification/content-p2-talents-closure.md'; report=p.read_text(encoding='utf-8')
    report=report.replace('**整批驗收執行中，尚未標 DONE**','**CONTENT-P2-TALENT DONE（L3／桌面Web有界）**')
    report=report.replace('結果以最終日誌為準。',f'最終完整命令exit0，121／121唯一runner通過：{initial}初跑、{len(retries)}串行重試。不是初跑全綠；原失敗保留於日誌。')
    report+='\n最終串行重試通過：'+', '.join(retries)+'。測試服務已Ctrl+C停止（exit1為主動停止）、分頁關閉、viewport override重設；無殘留本輪服務。\n'
    p.write_text(report,encoding='utf-8')
    restored=json.loads((D/'restored.json').read_text(encoding='utf-8'))
    checkpoint=f'''2026-10-25 CONTENT-P2-TALENT DONE — HUMAN ART/PACING ACCEPTED; L3 AND BOUNDED DESKTOP WEB CLOSED. STOP / NEW CHAT.
Human explicitly replied "接受三圖與目前節奏". All three built-in ImageGen illustrations/cards and current integrated pacing are accepted; approved U prices/formulas unchanged. Normal-host Full/Parallel3/TimeoutSeconds1800 completed exit0, 121/121 unique runners with full viewport matrix ({initial} initial passes, {len(retries)} serial-retry passes). Preserve original fixture-write failure, backup path-length failure, interrupted sandbox attempt/export, expected corrupt-JSON errors and existing exit diagnostics. See docs/verification/content-p2-talents-closure.md and its raw logs/audit.
Normal Web candidate build/web-content-p2-talents exported/compressed exit0, Brotli roundtrip and four BGM companions verified. Isolated loopback origin48471, real mouse canvas sizes1280x720/844x390/800x360; three illustrations/current-next effects and inner scrolling reviewed. Frontier first purchase25->15 with refusal, denied retry, recovery saves the same result, reload keeps rank1/15hearts/version3; returned home. Current observed console errors/warnings empty, prior MutationObserver diagnostics remain historical. Earned rebirth fixture only UTC-resealed with state_equal=true. Existing legal snapshot-to-rebirth and synthetic1000-heart evidence boundaries remain.
4173 JSON backups verified; {len(restored['changed_archived_restored'])} regenerated files archived then restored byte-for-byte except intentional accepted art metadata. Initial partial backup supplied the earlier last-earned-level baseline; do not claim every backup preceded the interrupted first test. Existing independently running supply runner/services were not stopped; no ownership/root-cause claims. Runtime/assets hashes verified against candidate, no player progress/rules/PNG edits, no commit/push. New closure tools/report/evidence, accepted metadata and status documents only. Browser tab closed, viewport reset, local review server stopped.
STOP this completed stage. Next large task must be user-selected in a New Chat; do not automatically start other P2/P3, redo U acceptance, or repeat L3 for document metadata.

'''
    p=ROOT/'updata.txt'; p.write_text(checkpoint+p.read_text(encoding='utf-8-sig'),encoding='utf-8')
    print('FINALIZED 121/121',initial,'initial',len(retries),'retry')
def audit():
    checks=[]; failures=[]
    def check(ok,name):
        checks.append(name)
        if not ok: failures.append(name)
    def read(p):
        raw=p.read_bytes(); s=raw.decode('utf-16') if raw.startswith((b'\xff\xfe',b'\xfe\xff')) else raw.decode('utf-8-sig')
        return re.sub(r'\x1b\[[0-9;]*[A-Za-z]','',s)
    command=read(D/'full-command.log'); runners=[s.strip() for s in read(D/'full-list.log').splitlines() if s.strip().endswith('.gd')]
    check(len(runners)==len(set(runners))==121,'121 unique runners')
    check(read(D/'full-exit.txt').strip()=='0','L3 exit0')
    check('SELECTED 121 RUNNERS PASSED (matrix=full)' in command,'L3 complete full matrix')
    folder=D/'logs'/Path(re.search(r'\[LOGS\] ([^\r\n]+)',command)[1].strip()).name
    for runner in runners:
        attempt='serial-retry' if '[PASS:serial-retry] '+runner in command else 'initial'
        check('[PASS:'+attempt+'] '+runner in command,'PASS '+runner)
        p=folder/(runner.replace('/','_')+'.'+attempt+'.log'); err=Path(str(p)+'.err')
        check(p.exists() and err.exists(),'logs '+runner)
        if p.exists() and err.exists(): check('SCRIPT ERROR:' not in read(p)+read(err),'no SCRIPT ERROR '+runner)
    for kind in ['export','compression','rebase']: check(read(D/(kind+'-exit.txt')).strip()=='0',kind+' exit0')
    check('state_equal=true' in read(D/'rebase.log'),'earned state preserved')
    package=json.loads(read(ROOT/'build/web-content-p2-talents/compression.json'))
    for item in package['files']:
        check(sha(ROOT/'build/web-content-p2-talents'/item['file'])==item['sha256'],'package '+item['file'])
        check(sha(ROOT/'build/web-content-p2-talents'/(item['file']+'.br'))==item['br_sha256'],'Brotli '+item['file'])
    check(len(package['audioFiles'])==4,'four BGM')
    for item in package['audioFiles']: check(sha(ROOT/'build/web-content-p2-talents'/item['file'])==item['sha256'],'BGM '+item['file'])
    hashes=json.loads(read(D/'before.json'))
    check(all(sha(ROOT/n)==h for n,h in hashes.items() if n!='docs/verification/artifacts/content-p2-talents-ui/art-manifest.json'),'prior JSON evidence preserved')
    source=json.loads(read(D/'candidate-source-hashes.json'))
    check(all(sha(ROOT/n)==h for n,h in source.items()),'runtime content assets unchanged since export')
    check(json.loads(read(D/'backup-integrity.json'))['failures']==[],'backup integrity')
    web=json.loads(read(D/'browser-observations.json'))
    check(web['sizes']==[[1280,720],[844,390],[800,360]],'three browser sizes')
    check(web['purchase_recovery_verified'],'mouse refusal retry recovery reload')
    check(json.loads(read(ROOT/'assets/ui/reincarnation-painted/talent2-manifest.json'))['acceptance']=='ACCEPTED','art accepted')
    decision=json.loads(read(D/'closure-decision.json'))
    check(decision['user_quote']=='接受三圖與目前節奏','human decision preserved')
    proposal=json.loads(read(ROOT/'docs/design-data/content-p2-talents-proposal.json'))
    original_proposal=json.loads(read(D/'proposal-before-closure.json'))
    check(proposal['talents']==original_proposal['talents'] and proposal['save_proposal']==original_proposal['save_proposal'],'U formulas prices gates and save contract unchanged')
    check(proposal['art_proposal']['acceptance']=='ACCEPTED' and proposal['implementation_status'].startswith('CONTENT-P2-TALENT DONE'),'proposal metadata closed')
    for name in ['README.md','ROADMAP.md','docs/ai-handoff.md','docs/development-status.md','docs/25-system-content-expansion-plan.md','docs/36-content-p2-talent-design.md']:
        check('CONTENT-P2-TALENT DONE' in read(ROOT/name).splitlines()[0],'closure status '+name)
    result={'level':'L3','checks':len(checks),'failures':failures,'runners':len(runners),'initial_failures':re.findall(r'\[FAIL:initial\] ([^ ]+)',command),'package':package,'candidate':'build/web-content-p2-talents','previous_json_count':len(hashes),'source_files':len(source)}
    save('delivery-audit.json',result); print(json.dumps({k:result[k] for k in ['checks','failures','runners','initial_failures']})); return bool(failures)
if __name__=='__main__': sys.exit({'backup':backup,'restore':restore,'sources':sources,'audit':audit,'reconcile':reconcile,'finalize':finalize}[sys.argv[1]]())
