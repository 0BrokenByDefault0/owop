#!/usr/bin/env python3
import hashlib,json,pathlib
root=pathlib.Path(__file__).resolve().parent.parent
obj={}
def uid(s):return hashlib.sha1(s.encode()).hexdigest()[:24].upper()
def add(name,body):obj[uid(name)]=body;return uid(name)
def q(s):return json.dumps(str(s))
sources=sorted(str(p.relative_to(root)) for p in (root/'POCKET').rglob('*') if p.suffix in ('.swift','.cpp'))
refs=[];build=[]
for p in sources+['POCKET/Assets.xcassets']:
    kind='sourcecode.swift' if p.endswith('.swift') else ('sourcecode.cpp.cpp' if p.endswith('.cpp') else 'folder.assetcatalog')
    ref=add('ref'+p,f'isa = PBXFileReference; lastKnownFileType = {kind}; path = {q(p)}; sourceTree = "<group>";')
    refs.append(ref);build.append(add('build'+p,f'isa = PBXBuildFile; fileRef = {ref};'))
product=add('product','isa = PBXFileReference; explicitFileType = wrapper.application; path = POCKET.app; sourceTree = BUILT_PRODUCTS_DIR;')
products=add('products',f'isa = PBXGroup; children = ({product},); name = Products; sourceTree = "<group>";')
group=add('group',f'isa = PBXGroup; children = ({",".join(refs+[products])},); sourceTree = "<group>";')
sourcephase=add('sources',f'isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ({",".join(build[:-1])},); runOnlyForDeploymentPostprocessing = 0;')
resources=add('resources',f'isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = ({build[-1]},); runOnlyForDeploymentPostprocessing = 0;')
frameworks=add('frameworks','isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0;')
projectsettings='CLANG_ENABLE_MODULES = YES; CLANG_CXX_LANGUAGE_STANDARD = "c++17"; CLANG_CXX_LIBRARY = "libc++"; IPHONEOS_DEPLOYMENT_TARGET = 17.0; SDKROOT = iphoneos; SWIFT_VERSION = 5.0;'
targetsettings='PRODUCT_NAME = POCKET; PRODUCT_BUNDLE_IDENTIFIER = com.brokenbydefault.pocket; INFOPLIST_FILE = POCKET/Info.plist; GENERATE_INFOPLIST_FILE = NO; SWIFT_OBJC_BRIDGING_HEADER = "POCKET/Pocket-Bridging-Header.h"; TARGETED_DEVICE_FAMILY = 1; SUPPORTED_PLATFORMS = "iphoneos iphonesimulator"; ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon; CODE_SIGNING_ALLOWED = NO; CODE_SIGNING_REQUIRED = NO; MARKETING_VERSION = 1.0; CURRENT_PROJECT_VERSION = 1; SWIFT_STRICT_CONCURRENCY = minimal; ENABLE_USER_SCRIPT_SANDBOXING = YES;'
def configs(name,settings):
    ids=[]
    for config in ['Debug','Release']:
        optimize='SWIFT_OPTIMIZATION_LEVEL = "-Onone"; GCC_OPTIMIZATION_LEVEL = 0;' if config=='Debug' else 'SWIFT_OPTIMIZATION_LEVEL = "-O"; GCC_OPTIMIZATION_LEVEL = s;'
        ids.append(add(name+config,f'isa = XCBuildConfiguration; buildSettings = {{{settings} {optimize}}}; name = {config};'))
    return add(name+'configs',f'isa = XCConfigurationList; buildConfigurations = ({",".join(ids)},); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')
pc=configs('project',projectsettings);tc=configs('target',targetsettings)
target=add('target',f'isa = PBXNativeTarget; buildConfigurationList = {tc}; buildPhases = ({sourcephase},{frameworks},{resources},); buildRules = (); dependencies = (); name = POCKET; productName = POCKET; productReference = {product}; productType = "com.apple.product-type.application";')
testref=add('testref','isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = Tests/UITests.swift; sourceTree = "<group>";')
testbuild=add('testbuild',f'isa = PBXBuildFile; fileRef = {testref};')
testproduct=add('testproduct','isa = PBXFileReference; explicitFileType = wrapper.cfbundle; path = POCKETUITests.xctest; sourceTree = BUILT_PRODUCTS_DIR;')
add('group',f'isa = PBXGroup; children = ({",".join(refs+[testref,products])},); sourceTree = "<group>";')
add('products',f'isa = PBXGroup; children = ({product},{testproduct},); name = Products; sourceTree = "<group>";')
testphase=add('testphase',f'isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ({testbuild},); runOnlyForDeploymentPostprocessing = 0;')
testframeworks=add('testframeworks','isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0;')
proxy=add('proxy',f'isa = PBXContainerItemProxy; containerPortal = {uid("project")}; proxyType = 1; remoteGlobalIDString = {target}; remoteInfo = POCKET;')
dependency=add('dependency',f'isa = PBXTargetDependency; target = {target}; targetProxy = {proxy};')
testsettings='PRODUCT_NAME = POCKETUITests; PRODUCT_BUNDLE_IDENTIFIER = com.brokenbydefault.pocket.uitests; GENERATE_INFOPLIST_FILE = YES; TEST_TARGET_NAME = POCKET; TARGETED_DEVICE_FAMILY = 1; CODE_SIGNING_ALLOWED = NO; SWIFT_STRICT_CONCURRENCY = minimal;'
testconfig=configs('test',testsettings)
testtarget=add('testtarget',f'isa = PBXNativeTarget; buildConfigurationList = {testconfig}; buildPhases = ({testphase},{testframeworks},); buildRules = (); dependencies = ({dependency},); name = POCKETUITests; productName = POCKETUITests; productReference = {testproduct}; productType = "com.apple.product-type.bundle.ui-testing";')
project=add('project',f'isa = PBXProject; attributes = {{LastUpgradeCheck = 1600;}}; buildConfigurationList = {pc}; compatibilityVersion = "Xcode 14.0"; developmentRegion = en; hasScannedForEncodings = 0; knownRegions = (en,Base,); mainGroup = {group}; productRefGroup = {products}; projectDirPath = ""; projectRoot = ""; targets = ({target},{testtarget},);')
folder=root/'POCKET.xcodeproj';folder.mkdir(exist_ok=True)
(folder/'project.pbxproj').write_text('// !$*UTF8*$!\n{archiveVersion = 1; classes = {}; objectVersion = 56; objects = {\n'+''.join(k+' = { '+v+' };\n' for k,v in obj.items())+'}; rootObject = '+project+'; }\n')
scheme=folder/'xcshareddata/xcschemes';scheme.mkdir(parents=True,exist_ok=True)
(scheme/'POCKET.xcscheme').write_text(f'''<?xml version="1.0" encoding="UTF-8"?><Scheme LastUpgradeVersion="1600" version="1.3"><BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{target}" BuildableName="POCKET.app" BlueprintName="POCKET" ReferencedContainer="container:POCKET.xcodeproj"/></BuildActionEntry></BuildActionEntries></BuildAction><LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{target}" BuildableName="POCKET.app" BlueprintName="POCKET" ReferencedContainer="container:POCKET.xcodeproj"/></BuildableProductRunnable></LaunchAction></Scheme>''')
print(f'Generated POCKET.xcodeproj: {len(sources)} source files')

path=scheme/'POCKET.xcscheme'
xml=path.read_text()
xml=xml.replace('</BuildActionEntries>',f'<BuildActionEntry buildForTesting="YES" buildForRunning="NO" buildForProfiling="NO" buildForArchiving="NO" buildForAnalyzing="NO"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{testtarget}" BuildableName="POCKETUITests.xctest" BlueprintName="POCKETUITests" ReferencedContainer="container:POCKET.xcodeproj"/></BuildActionEntry></BuildActionEntries>')
xml=xml.replace('<LaunchAction',f'<TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables><TestableReference skipped="NO"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{testtarget}" BuildableName="POCKETUITests.xctest" BlueprintName="POCKETUITests" ReferencedContainer="container:POCKET.xcodeproj"/></TestableReference></Testables></TestAction><LaunchAction',1)
path.write_text(xml)
