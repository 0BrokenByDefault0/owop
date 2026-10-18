import json,pathlib,subprocess,time
out=pathlib.Path('build/screens');out.mkdir(parents=True,exist_ok=True)
def run(*args,check=True):return subprocess.run(args,check=check,capture_output=True,text=True).stdout
available=json.loads(run('xcrun','simctl','list','devices','available','-j'))['devices']
phones=[d for devices in available.values() for d in devices if 'iPhone' in d['name']]
assert phones,'No iPhone simulators installed'
choices=[phones[0]]
large=next((d for d in phones if 'Max' in d['name'] or 'Plus' in d['name']),None)
if large and large['udid']!=phones[0]['udid']:choices.append(large)
for device in choices:
 uid=device['udid'];run('xcrun','simctl','boot',uid,check=False);run('xcrun','simctl','bootstatus',uid,'-b')
 run('xcrun','simctl','status_bar',uid,'override','--time','9:41','--dataNetwork','wifi','--wifiMode','active','--wifiBars','3','--batteryState','charged','--batteryLevel','100')
 run('xcrun','simctl','install',uid,'build/simulator/Build/Products/Debug-iphonesimulator/POCKET.app')
 for page in ['learn','practice','play','lesson']:
  run('xcrun','simctl','terminate',uid,'com.brokenbydefault.pocket',check=False)
  run('xcrun','simctl','launch',uid,'com.brokenbydefault.pocket','-preview',page)
  time.sleep(3)
  run('xcrun','simctl','io',uid,'screenshot',str(out/(device['name'].replace(' ','-')+'-'+page+'.png')))
 run('xcrun','simctl','shutdown',uid)
print('Native screens captured for '+', '.join(d['name'] for d in choices))
