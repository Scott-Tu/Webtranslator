# 產生 WebTranslator.xcodeproj（project.pbxproj 與共用 scheme）。新增或刪除 .swift 檔後執行：python3 scripts/gen_xcodeproj.py
import itertools
c=itertools.count(1)
def nid(): return 'A1B2C3D4%016X' % next(c)
import glob, os, sys
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
swift=sorted(os.path.basename(p) for p in glob.glob(ROOT+'/WebTranslator/*.swift'))
fr={f:nid() for f in swift}; bf={f:nid() for f in swift}
assets_fr, assets_bf = nid(), nid()
info_fr=nid(); app_fr=nid()
main_grp, src_grp, prod_grp = nid(), nid(), nid()
target, project = nid(), nid()
src_phase, fw_phase, res_phase = nid(), nid(), nid()
proj_dbg, proj_rel, tgt_dbg, tgt_rel = nid(), nid(), nid(), nid()
proj_list, tgt_list = nid(), nid()
L=[]; a=L.append
a('// !$*UTF8*$!\n{\n\tarchiveVersion = 1;\n\tclasses = {\n\t};\n\tobjectVersion = 56;\n\tobjects = {\n')
a('\n/* Begin PBXBuildFile section */\n')
for f in swift: a(f'\t\t{bf[f]} /* {f} in Sources */ = {{isa = PBXBuildFile; fileRef = {fr[f]} /* {f} */; }};\n')
a(f'\t\t{assets_bf} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {assets_fr} /* Assets.xcassets */; }};\n')
a('/* End PBXBuildFile section */\n\n/* Begin PBXFileReference section */\n')
a(f'\t\t{app_fr} /* WebTranslator.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = WebTranslator.app; sourceTree = BUILT_PRODUCTS_DIR; }};\n')
for f in swift: a(f'\t\t{fr[f]} /* {f} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {f}; sourceTree = "<group>"; }};\n')
a(f'\t\t{assets_fr} /* Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>"; }};\n')
a(f'\t\t{info_fr} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>"; }};\n')
a('/* End PBXFileReference section */\n\n/* Begin PBXFrameworksBuildPhase section */\n')
a(f'\t\t{fw_phase} /* Frameworks */ = {{\n\t\t\tisa = PBXFrameworksBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (\n\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t}};\n')
a('/* End PBXFrameworksBuildPhase section */\n\n/* Begin PBXGroup section */\n')
a(f'\t\t{main_grp} = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n\t\t\t\t{src_grp} /* WebTranslator */,\n\t\t\t\t{prod_grp} /* Products */,\n\t\t\t);\n\t\t\tsourceTree = "<group>";\n\t\t}};\n')
a(f'\t\t{prod_grp} /* Products */ = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n\t\t\t\t{app_fr} /* WebTranslator.app */,\n\t\t\t);\n\t\t\tname = Products;\n\t\t\tsourceTree = "<group>";\n\t\t}};\n')
kids=''.join(f'\t\t\t\t{fr[f]} /* {f} */,\n' for f in swift)
a(f'\t\t{src_grp} /* WebTranslator */ = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n{kids}\t\t\t\t{assets_fr} /* Assets.xcassets */,\n\t\t\t\t{info_fr} /* Info.plist */,\n\t\t\t);\n\t\t\tpath = WebTranslator;\n\t\t\tsourceTree = "<group>";\n\t\t}};\n')
a('/* End PBXGroup section */\n\n/* Begin PBXNativeTarget section */\n')
a(f'''\t\t{target} /* WebTranslator */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {tgt_list} /* Build configuration list for PBXNativeTarget "WebTranslator" */;
\t\t\tbuildPhases = (
\t\t\t\t{src_phase} /* Sources */,
\t\t\t\t{fw_phase} /* Frameworks */,
\t\t\t\t{res_phase} /* Resources */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t);
\t\t\tname = WebTranslator;
\t\t\tproductName = WebTranslator;
\t\t\tproductReference = {app_fr} /* WebTranslator.app */;
\t\t\tproductType = "com.apple.product-type.application";
\t\t}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
\t\t{project} /* Project object */ = {{
\t\t\tisa = PBXProject;
\t\t\tattributes = {{
\t\t\t\tBuildIndependentTargetsInParallel = 1;
\t\t\t\tLastSwiftUpdateCheck = 1600;
\t\t\t\tLastUpgradeCheck = 1600;
\t\t\t\tTargetAttributes = {{
\t\t\t\t\t{target} = {{
\t\t\t\t\t\tCreatedOnToolsVersion = 16.0;
\t\t\t\t\t}};
\t\t\t\t}};
\t\t\t}};
\t\t\tbuildConfigurationList = {proj_list} /* Build configuration list for PBXProject "WebTranslator" */;
\t\t\tcompatibilityVersion = "Xcode 14.0";
\t\t\tdevelopmentRegion = "zh-Hant";
\t\t\thasScannedForEncodings = 0;
\t\t\tknownRegions = (
\t\t\t\ten,
\t\t\t\tBase,
\t\t\t\t"zh-Hant",
\t\t\t);
\t\t\tmainGroup = {main_grp};
\t\t\tproductRefGroup = {prod_grp} /* Products */;
\t\t\tprojectDirPath = "";
\t\t\tprojectRoot = "";
\t\t\ttargets = (
\t\t\t\t{target} /* WebTranslator */,
\t\t\t);
\t\t}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
\t\t{res_phase} /* Resources */ = {{
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t\t{assets_bf} /* Assets.xcassets in Resources */,
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
\t\t{src_phase} /* Sources */ = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
''')
for f in swift: a(f'\t\t\t\t{bf[f]} /* {f} in Sources */,\n')
a('\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t};\n/* End PBXSourcesBuildPhase section */\n\n/* Begin XCBuildConfiguration section */\n')
common='''ALWAYS_SEARCH_USER_PATHS = NO;
ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
CLANG_ANALYZER_NONNULL = YES;
CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
CLANG_ENABLE_MODULES = YES;
CLANG_ENABLE_OBJC_ARC = YES;
CLANG_ENABLE_OBJC_WEAK = YES;
CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
CLANG_WARN_BOOL_CONVERSION = YES;
CLANG_WARN_COMMA = YES;
CLANG_WARN_CONSTANT_CONVERSION = YES;
CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
CLANG_WARN_EMPTY_BODY = YES;
CLANG_WARN_ENUM_CONVERSION = YES;
CLANG_WARN_INFINITE_RECURSION = YES;
CLANG_WARN_INT_CONVERSION = YES;
CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
CLANG_WARN_STRICT_PROTOTYPES = YES;
CLANG_WARN_SUSPICIOUS_MOVE = YES;
CLANG_WARN_UNREACHABLE_CODE = YES;
CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
COPY_PHASE_STRIP = NO;
ENABLE_STRICT_OBJC_MSGSEND = YES;
ENABLE_USER_SCRIPT_SANDBOXING = YES;
GCC_C_LANGUAGE_STANDARD = gnu17;
GCC_NO_COMMON_BLOCKS = YES;
GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
GCC_WARN_UNDECLARED_SELECTOR = YES;
GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
GCC_WARN_UNUSED_FUNCTION = YES;
GCC_WARN_UNUSED_VARIABLE = YES;
IPHONEOS_DEPLOYMENT_TARGET = 18.0;
LOCALIZATION_PREFERS_STRING_CATALOGS = YES;
MTL_FAST_MATH = YES;
SDKROOT = iphoneos;
'''
dbg='''DEBUG_INFORMATION_FORMAT = dwarf;
ENABLE_TESTABILITY = YES;
GCC_DYNAMIC_NO_PIC = NO;
GCC_OPTIMIZATION_LEVEL = 0;
GCC_PREPROCESSOR_DEFINITIONS = (
\t"DEBUG=1",
\t"$(inherited)",
);
MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
ONLY_ACTIVE_ARCH = YES;
SWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";
SWIFT_OPTIMIZATION_LEVEL = "-Onone";
'''
rel='''DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
ENABLE_NS_ASSERTIONS = NO;
MTL_ENABLE_DEBUG_INFO = NO;
SWIFT_COMPILATION_MODE = wholemodule;
VALIDATE_PRODUCT = YES;
'''
tgt='''ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
CODE_SIGN_STYLE = Automatic;
CURRENT_PROJECT_VERSION = 1;
DEVELOPMENT_TEAM = "";
ENABLE_PREVIEWS = YES;
GENERATE_INFOPLIST_FILE = YES;
INFOPLIST_FILE = WebTranslator/Info.plist;
INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
INFOPLIST_KEY_UILaunchScreen_Generation = YES;
INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
LD_RUNPATH_SEARCH_PATHS = (
\t"$(inherited)",
\t"@executable_path/Frameworks",
);
MARKETING_VERSION = 1.0;
PRODUCT_BUNDLE_IDENTIFIER = com.scotttu.webtranslator;
PRODUCT_NAME = "$(TARGET_NAME)";
SWIFT_EMIT_LOC_STRINGS = YES;
SWIFT_VERSION = 5.0;
TARGETED_DEVICE_FAMILY = "1,2";
'''
def cfg(i,name,body):
    lines=''.join('\t\t\t\t'+l+'\n' for l in body.strip('\n').split('\n'))
    a(f'\t\t{i} /* {name} */ = {{\n\t\t\tisa = XCBuildConfiguration;\n\t\t\tbuildSettings = {{\n{lines}\t\t\t}};\n\t\t\tname = {name};\n\t\t}};\n')
def sort(body): return '\n'.join(body)  # unused
cfg(proj_dbg,'Debug',common+dbg); cfg(proj_rel,'Release',common+rel)
cfg(tgt_dbg,'Debug',tgt); cfg(tgt_rel,'Release',tgt)
a('/* End XCBuildConfiguration section */\n\n/* Begin XCConfigurationList section */\n')
for lid,label,d_,r_ in [(proj_list,'PBXProject "WebTranslator"',proj_dbg,proj_rel),(tgt_list,'PBXNativeTarget "WebTranslator"',tgt_dbg,tgt_rel)]:
    a(f'\t\t{lid} /* Build configuration list for {label} */ = {{\n\t\t\tisa = XCConfigurationList;\n\t\t\tbuildConfigurations = (\n\t\t\t\t{d_} /* Debug */,\n\t\t\t\t{r_} /* Release */,\n\t\t\t);\n\t\t\tdefaultConfigurationIsVisible = 0;\n\t\t\tdefaultConfigurationName = Release;\n\t\t}};\n')
a('/* End XCConfigurationList section */\n\t};\n\trootObject = '+project+' /* Project object */;\n}\n')
open(ROOT+'/WebTranslator.xcodeproj/project.pbxproj','w').write(''.join(L))

import os, sys
scheme_dir=ROOT+'/WebTranslator.xcodeproj/xcshareddata/xcschemes'
os.makedirs(scheme_dir, exist_ok=True)
ref=f'''<BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{target}"
               BuildableName = "WebTranslator.app"
               BlueprintName = "WebTranslator"
               ReferencedContainer = "container:WebTranslator.xcodeproj">
            </BuildableReference>'''
open(scheme_dir+'/WebTranslator.xcscheme','w').write(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1600"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            {ref}
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         {ref}
      </BuildableProductRunnable>
   </LaunchAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
''')
