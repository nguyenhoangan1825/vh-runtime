"""Build repository launchers from the local source and an immutable source commit."""
from pathlib import Path
import argparse,hashlib,json,re,zlib
P=Path(__file__).resolve().parent

def lua_long(text):
    eq='===='
    while ']'+eq+']' in text:eq+='='
    return '['+eq+'['+text+']'+eq+']'

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source_commit',help='40-character commit SHA containing atlas/source.lua')
    parser.add_argument('--output',default=str(P.parent),help='Directory for atlas.lua and atlas-debug.lua')
    args=parser.parse_args()
    if not re.fullmatch('[0-9a-fA-F]{40}',args.source_commit):raise SystemExit('Expected a complete 40-character source commit SHA.')
    original=(P/'source.lua').read_bytes()
    source=original.decode('utf8')
    patches=json.loads((P/'diagnostic-patches.json').read_text())
    debug=source
    for old,new in patches:
        if debug.count(old)!=1:raise SystemExit('Diagnostic patch no longer matches your source: '+old[:70])
        debug=debug.replace(old,new,1)
    template=(P/'loader-template.lua').read_text()
    target=Path(args.output).resolve();target.mkdir(parents=True,exist_ok=True)
    url='https://raw.githubusercontent.com/nguyenhoangan1825/vh-runtime/'+args.source_commit+'/atlas/source.lua'
    for name,body,instructions in [('atlas.lua',source,''),('atlas-debug.lua',debug,'\n'.join(' source=replaceLiteral(source,'+lua_long(a)+','+lua_long(b)+',1)'for a,b in patches))]:
        text=template
        values={'@@SOURCE_URL@@':json.dumps(url),'@@SOURCE_BYTES@@':str(len(original)),'@@SOURCE_ADLER@@':str(zlib.adler32(original)),'@@PATCHED_ADLER@@':str(zlib.adler32(body.encode())),'@@PATCHES@@':instructions,'@@TAG@@':json.dumps('[Atlas VI2 D1] 'if name=='atlas-debug.lua'else '[Atlas VI2] ')}
        for key,value in values.items():text=text.replace(key,value)
        (target/name).write_text(text,encoding='utf8',newline='\n')
        print(name,'bytes',len(text.encode()),'source',args.source_commit)
    manifest={'source_commit':args.source_commit,'source_sha256':hashlib.sha256(original).hexdigest(),'source_bytes':len(original),'source_adler32':zlib.adler32(original),'debug_sha256':hashlib.sha256(debug.encode()).hexdigest(),'debug_adler32':zlib.adler32(debug.encode())}
    (target/'atlas-build.json').write_text(json.dumps(manifest,indent=2)+'\n')
if __name__=='__main__':main()
