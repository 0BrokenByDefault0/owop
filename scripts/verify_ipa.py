import hashlib,pathlib,plistlib,subprocess,zipfile,json,os
root=pathlib.Path(__file__).resolve().parent.parent
app=root/'build/device/Build/Products/Release-iphoneos/POCKET.app'
info=plistlib.loads((app/'Info.plist').read_bytes())
exe=app/info['CFBundleExecutable']
kind=subprocess.check_output(['file',str(exe)],text=True).strip()
assert 'arm64' in kind and 'Mach-O' in kind,kind
assert info['CFBundleIdentifier']=='com.brokenbydefault.pocket'
assert not (app/'embedded.mobileprovision').exists()
assert not (app/'_CodeSignature').exists()
result=subprocess.run(['codesign','-dv',str(app)],capture_output=True,text=True)
assert 'not signed at all' in result.stderr,result.stderr
out=root/'build/artifacts';out.mkdir(parents=True,exist_ok=True)
ipa=out/'POCKET-1.0-unsigned.ipa'
with zipfile.ZipFile(ipa,'w',zipfile.ZIP_DEFLATED) as z:
 for p in sorted(app.rglob('*')):
  if p.is_file():z.write(p,'Payload/POCKET.app/'+str(p.relative_to(app)))
sha=hashlib.sha256(ipa.read_bytes()).hexdigest()
(out/'SHA256.txt').write_text(sha+'  '+ipa.name+'\n')
(out/'build-info.json').write_text(json.dumps({'commit':os.getenv('GITHUB_SHA','local'),'xcode':subprocess.check_output(['xcodebuild','-version'],text=True),'binary':kind,'bytes':ipa.stat().st_size,'sha256':sha,'signing':'unsigned','bundle_id':info['CFBundleIdentifier'],'minimum_os':info.get('MinimumOSVersion')},indent=2))
print((out/'build-info.json').read_text())
