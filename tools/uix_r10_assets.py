"""Preserve ImageGen alpha; fit each full vignette into a runtime canvas."""
from pathlib import Path
from PIL import Image, ImageOps, ImageDraw
import json, shutil, hashlib
ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT/'docs/verification/artifacts/uix-r10'
DEST = ROOT/'assets/ui/fortune-painted'
GROUPS = {
 'ruins':['enc_ancient_cave','enc_buddha_bodhi_tablet'],
 'spring':['enc_celestial_dew','enc_primordial_fountain','enc_human_tea_spring','enc_spirit_tianqing_tide','enc_immortal_celestial_feast','enc_buddha_lotus_blessing'],
 'traveler':['enc_wandering_taoist','enc_human_mortal_fair','enc_spirit_herb_fairy','enc_nether_ferryman','enc_nether_judge_brush','enc_demon_celestial_maiden'],
 'beast':['enc_beast_relic','enc_beast_peng_nest','enc_beast_dragon_bone','enc_immortal_crane_messenger'],
 'omen':['enc_nether_whisper','enc_demon_heart_tribulation','enc_falling_star','enc_demon_blood_sea_tide','enc_chaos_primordial_rift','enc_chaos_reversal_matrix','enc_origin_stellar_loom','enc_origin_first_dawn'],
 'sensing':[]}
def main():
 records=json.loads((OUT/'generation-records.json').read_text(encoding='utf-8-sig'))
 (OUT/'originals').mkdir(exist_ok=True)
 manifest={'task':'UIX-R10-FORTUNE','date':'2026-10-17','generator':'built-in ImageGen','source':'Original AI-generated art; no external reference','license_status':'Generated for project; no third-party commercial license asserted','layers':'Single RGBA vignette; all text/actions/state remain Godot','assets':[]}
 sheet=Image.new('RGB',(1008,672),'#efe7d2'); draw=ImageDraw.Draw(sheet)
 for i,r in enumerate(records):
  ident=r['id']; original=OUT/'originals'/f'{ident}.png'; shutil.copy2(r['generated_path'],original)
  im=Image.open(original).convert('RGBA'); alpha=im.getchannel('A'); assert alpha.getextrema()[0]==0
  fit=ImageOps.contain(im.crop(alpha.getbbox()),(448,448),Image.Resampling.LANCZOS)
  runtime=Image.new('RGBA',(480,480)); runtime.alpha_composite(fit,((480-fit.width)//2,(480-fit.height)//2))
  target=DEST/f'{ident}.png'; runtime.save(target,optimize=True)
  (OUT/f'{ident}-prompt.txt').write_text(r['prompt']+'\n',encoding='utf-8')
  thumb=runtime.resize((280,280)); x=(i%3)*336+28; y=(i//3)*336
  sheet.paste(thumb,(x,y),thumb); draw.text((x,y+286),ident,fill='#343c3d')
  manifest['assets'].append({'id':ident,'encounter_ids':GROUPS[ident],'purpose':'Encounter theme only; does not promise outcome','source':original.relative_to(ROOT).as_posix(),'runtime':target.relative_to(ROOT).as_posix(),'source_size':list(im.size),'runtime_size':[480,480],'alpha':True,'processing':'Full alpha bounds fitted to448px,16px padding; original alpha retained','prompt':f'docs/verification/artifacts/uix-r10/{ident}-prompt.txt','sha256':hashlib.sha256(target.read_bytes()).hexdigest()})
 ids=[e['id'] for e in json.loads((ROOT/'content/encounters/encounters.json').read_text(encoding='utf-8-sig'))]
 mapping={e:group for group,es in GROUPS.items() for e in es}; assert sorted(ids)==sorted(mapping)
 manifest['encounter_mapping']=mapping
 (DEST/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
 sheet.save(OUT/'art-contact-sheet.jpg',quality=95)
 print('PASS6 transparent sources/prompts/runtime assets;26 unique encounter mappings')
if __name__=='__main__': main()
