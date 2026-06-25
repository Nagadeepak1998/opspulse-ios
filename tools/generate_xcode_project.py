#!/usr/bin/env python3
"""Generate the minimal Xcode project used by OpsPulse.

The repo keeps the generator in source control so project-file churn is
repeatable and reviewable. It intentionally has no third-party dependencies.
"""

from __future__ import annotations

import hashlib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PROJECT_DIR = ROOT / "OpsPulse.xcodeproj"
SCHEME_DIR = PROJECT_DIR / "xcshareddata" / "xcschemes"


def uid(label: str) -> str:
    return hashlib.md5(label.encode("utf-8")).hexdigest().upper()[:24]


def q(value: str) -> str:
    escaped = value.replace("\\", "\\\\").replace('"', '\\"')
    return f'"{escaped}"'


def build_settings(settings: dict[str, str | list[str]]) -> str:
    lines = ["\t\t\t\tbuildSettings = {"]
    for key, value in settings.items():
        if isinstance(value, list):
            rendered = "(" + ", ".join(value) + ")"
        else:
            rendered = value
        lines.append(f"\t\t\t\t\t{key} = {rendered};")
    lines.append("\t\t\t\t};")
    return "\n".join(lines)


def file_type(path: Path, product: bool = False) -> str:
    if product and path.suffix == ".app":
        return "wrapper.application"
    if product and path.suffix == ".appex":
        return "wrapper.app-extension"
    if path.suffix == ".swift":
        return "sourcecode.swift"
    if path.suffix == ".xcassets":
        return "folder.assetcatalog"
    if path.suffix == ".plist":
        return "text.plist.xml"
    if path.suffix == ".md":
        return "text"
    if path.suffix == ".sh":
        return "text.script.sh"
    return "text"


def add_file_ref(objects: list[str], label: str, path: Path, source_tree: str = "<group>", product: bool = False) -> str:
    file_id = uid(f"fileref:{label}:{path}")
    name = path.name
    source = file_type(path, product=product)
    explicit = "explicitFileType" if product else "lastKnownFileType"
    objects.append(
        f"\t\t{file_id} = {{isa = PBXFileReference; {explicit} = {source}; "
        f"includeInIndex = 0; name = {q(name)}; path = {q(str(path))}; sourceTree = {q(source_tree)}; }};"
    )
    return file_id


def add_build_file(objects: list[str], label: str, file_ref: str, embed: bool = False) -> str:
    build_id = uid(f"buildfile:{label}:{file_ref}")
    settings = " settings = {ATTRIBUTES = (RemoveHeadersOnCopy, );};" if embed else ""
    objects.append(f"\t\t{build_id} = {{isa = PBXBuildFile; fileRef = {file_ref};{settings} }};")
    return build_id


def group(objects: list[str], label: str, children: list[str], name: str | None = None, path: str | None = None) -> str:
    group_id = uid(f"group:{label}")
    attrs = [f"isa = PBXGroup; children = ({', '.join(children)});"]
    if name:
        attrs.append(f"name = {q(name)};")
    if path:
        attrs.append(f"path = {q(path)};")
    attrs.append("sourceTree = \"<group>\";")
    objects.append(f"\t\t{group_id} = {{{' '.join(attrs)} }};")
    return group_id


def config(objects: list[str], label: str, name: str, settings: dict[str, str | list[str]]) -> str:
    config_id = uid(f"config:{label}:{name}")
    objects.append(
        f"\t\t{config_id} = {{isa = XCBuildConfiguration; "
        f"name = {name};\n{build_settings(settings)}\n\t\t\t}};"
    )
    return config_id


def config_list(objects: list[str], label: str, debug: str, release: str) -> str:
    list_id = uid(f"configlist:{label}")
    objects.append(
        f"\t\t{list_id} = {{isa = XCConfigurationList; buildConfigurations = ({debug}, {release}); "
        "defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; };"
    )
    return list_id


def main() -> None:
    objects: list[str] = []
    app_swift = sorted([*ROOT.glob("OpsPulse/**/*.swift"), *ROOT.glob("Sources/OpsPulseCore/**/*.swift")])
    widget_swift = sorted(ROOT.glob("OpsPulseWidget/*.swift"))
    assets = ROOT / "OpsPulse" / "Assets.xcassets"

    products_group_id = uid("group:Products")
    app_product_ref = add_file_ref(objects, "OpsPulse.app", Path("OpsPulse.app"), "BUILT_PRODUCTS_DIR", product=True)
    widget_product_ref = add_file_ref(objects, "OpsPulseWidget.appex", Path("OpsPulseWidget.appex"), "BUILT_PRODUCTS_DIR", product=True)

    app_file_refs = [(path, add_file_ref(objects, f"app:{path}", path.relative_to(ROOT), "SOURCE_ROOT")) for path in app_swift]
    widget_file_refs = [(path, add_file_ref(objects, f"widget:{path}", path.relative_to(ROOT), "SOURCE_ROOT")) for path in widget_swift]
    assets_ref = add_file_ref(objects, "assets", assets.relative_to(ROOT), "SOURCE_ROOT")

    app_build_files = [add_build_file(objects, f"app:{path}", file_ref) for path, file_ref in app_file_refs]
    widget_build_files = [add_build_file(objects, f"widget:{path}", file_ref) for path, file_ref in widget_file_refs]
    assets_build = add_build_file(objects, "assets", assets_ref)
    embedded_widget_build = add_build_file(objects, "embed-widget", widget_product_ref, embed=True)

    app_sources_phase = uid("phase:app:sources")
    app_resources_phase = uid("phase:app:resources")
    app_frameworks_phase = uid("phase:app:frameworks")
    app_embed_phase = uid("phase:app:embed")
    widget_sources_phase = uid("phase:widget:sources")
    widget_resources_phase = uid("phase:widget:resources")
    widget_frameworks_phase = uid("phase:widget:frameworks")

    objects.append(f"\t\t{app_sources_phase} = {{isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ({', '.join(app_build_files)}); runOnlyForDeploymentPostprocessing = 0; }};")
    objects.append(f"\t\t{app_resources_phase} = {{isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = ({assets_build}); runOnlyForDeploymentPostprocessing = 0; }};")
    objects.append(f"\t\t{app_frameworks_phase} = {{isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; }};")
    objects.append(f"\t\t{app_embed_phase} = {{isa = PBXCopyFilesBuildPhase; buildActionMask = 2147483647; dstPath = \"\"; dstSubfolderSpec = 13; files = ({embedded_widget_build}); name = \"Embed App Extensions\"; runOnlyForDeploymentPostprocessing = 0; }};")
    objects.append(f"\t\t{widget_sources_phase} = {{isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ({', '.join(widget_build_files)}); runOnlyForDeploymentPostprocessing = 0; }};")
    objects.append(f"\t\t{widget_resources_phase} = {{isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; }};")
    objects.append(f"\t\t{widget_frameworks_phase} = {{isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; }};")

    project_debug = config(objects, "project", "Debug", {
        "ALWAYS_SEARCH_USER_PATHS": "NO",
        "CLANG_ANALYZER_NONNULL": "YES",
        "CLANG_ENABLE_MODULES": "YES",
        "CLANG_ENABLE_OBJC_ARC": "YES",
        "COPY_PHASE_STRIP": "NO",
        "DEBUG_INFORMATION_FORMAT": "dwarf",
        "ENABLE_STRICT_OBJC_MSGSEND": "YES",
        "GCC_C_LANGUAGE_STANDARD": "gnu17",
        "GCC_DYNAMIC_NO_PIC": "NO",
        "GCC_NO_COMMON_BLOCKS": "YES",
        "GCC_OPTIMIZATION_LEVEL": "0",
        "IPHONEOS_DEPLOYMENT_TARGET": "18.0",
        "SDKROOT": "iphoneos",
        "SWIFT_VERSION": "6.0",
    })
    project_release = config(objects, "project", "Release", {
        "ALWAYS_SEARCH_USER_PATHS": "NO",
        "CLANG_ANALYZER_NONNULL": "YES",
        "CLANG_ENABLE_MODULES": "YES",
        "CLANG_ENABLE_OBJC_ARC": "YES",
        "COPY_PHASE_STRIP": "NO",
        "DEBUG_INFORMATION_FORMAT": "dwarf-with-dsym",
        "ENABLE_NS_ASSERTIONS": "NO",
        "ENABLE_STRICT_OBJC_MSGSEND": "YES",
        "GCC_C_LANGUAGE_STANDARD": "gnu17",
        "GCC_NO_COMMON_BLOCKS": "YES",
        "IPHONEOS_DEPLOYMENT_TARGET": "18.0",
        "SDKROOT": "iphoneos",
        "SWIFT_COMPILATION_MODE": "wholemodule",
        "SWIFT_VERSION": "6.0",
    })
    project_config_list = config_list(objects, "project", project_debug, project_release)

    app_settings = {
        "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
        "CODE_SIGN_STYLE": "Automatic",
        "CURRENT_PROJECT_VERSION": "1",
        "DEVELOPMENT_TEAM": "\"\"",
        "ENABLE_PREVIEWS": "YES",
        "GENERATE_INFOPLIST_FILE": "YES",
        "INFOPLIST_KEY_CFBundleDisplayName": "OpsPulse",
        "INFOPLIST_KEY_LSApplicationCategoryType": "public.app-category.developer-tools",
        "INFOPLIST_KEY_UIApplicationSceneManifest_Generation": "YES",
        "INFOPLIST_KEY_UILaunchScreen_Generation": "YES",
        "IPHONEOS_DEPLOYMENT_TARGET": "18.0",
        "MARKETING_VERSION": "1.0",
        "PRODUCT_BUNDLE_IDENTIFIER": "com.naga.OpsPulse",
        "PRODUCT_NAME": "$(TARGET_NAME)",
        "SUPPORTED_PLATFORMS": "\"iphoneos iphonesimulator\"",
        "SWIFT_VERSION": "6.0",
        "TARGETED_DEVICE_FAMILY": "\"1,2\"",
    }
    app_debug = config(objects, "app", "Debug", app_settings | {"SWIFT_OPTIMIZATION_LEVEL": "\"-Onone\""})
    app_release = config(objects, "app", "Release", app_settings)
    app_config_list = config_list(objects, "app", app_debug, app_release)

    widget_settings = {
        "APPLICATION_EXTENSION_API_ONLY": "YES",
        "CODE_SIGN_STYLE": "Automatic",
        "CURRENT_PROJECT_VERSION": "1",
        "DEVELOPMENT_TEAM": "\"\"",
        "GENERATE_INFOPLIST_FILE": "NO",
        "INFOPLIST_FILE": "OpsPulseWidget/Info.plist",
        "IPHONEOS_DEPLOYMENT_TARGET": "18.0",
        "MARKETING_VERSION": "1.0",
        "PRODUCT_BUNDLE_IDENTIFIER": "com.naga.OpsPulse.widget",
        "PRODUCT_NAME": "$(TARGET_NAME)",
        "SKIP_INSTALL": "YES",
        "SUPPORTED_PLATFORMS": "\"iphoneos iphonesimulator\"",
        "SWIFT_VERSION": "6.0",
        "TARGETED_DEVICE_FAMILY": "\"1,2\"",
    }
    widget_debug = config(objects, "widget", "Debug", widget_settings | {"SWIFT_OPTIMIZATION_LEVEL": "\"-Onone\""})
    widget_release = config(objects, "widget", "Release", widget_settings)
    widget_config_list = config_list(objects, "widget", widget_debug, widget_release)

    app_target = uid("target:OpsPulse")
    widget_target = uid("target:OpsPulseWidget")
    dependency_proxy = uid("proxy:widget")
    dependency = uid("dependency:widget")
    project_id = uid("project:OpsPulse")
    main_group_id = uid("group:main")

    objects.append(
        f"\t\t{dependency_proxy} = {{isa = PBXContainerItemProxy; containerPortal = {project_id}; proxyType = 1; remoteGlobalIDString = {widget_target}; remoteInfo = OpsPulseWidget; }};"
    )
    objects.append(
        f"\t\t{dependency} = {{isa = PBXTargetDependency; target = {widget_target}; targetProxy = {dependency_proxy}; }};"
    )

    objects.append(
        f"\t\t{app_target} = {{isa = PBXNativeTarget; buildConfigurationList = {app_config_list}; "
        f"buildPhases = ({app_sources_phase}, {app_frameworks_phase}, {app_resources_phase}, {app_embed_phase}); "
        f"buildRules = (); dependencies = ({dependency}); name = OpsPulse; productName = OpsPulse; "
        f"productReference = {app_product_ref}; productType = \"com.apple.product-type.application\"; }};"
    )
    objects.append(
        f"\t\t{widget_target} = {{isa = PBXNativeTarget; buildConfigurationList = {widget_config_list}; "
        f"buildPhases = ({widget_sources_phase}, {widget_frameworks_phase}, {widget_resources_phase}); "
        f"buildRules = (); dependencies = (); name = OpsPulseWidget; productName = OpsPulseWidget; "
        f"productReference = {widget_product_ref}; productType = \"com.apple.product-type.app-extension\"; }};"
    )

    app_group = group(objects, "OpsPulse", [file_ref for _, file_ref in app_file_refs] + [assets_ref], path="OpsPulse")
    core_group = group(objects, "Sources", [file_ref for path, file_ref in app_file_refs if "Sources/OpsPulseCore" in str(path)], path="Sources")
    widget_group = group(objects, "OpsPulseWidget", [file_ref for _, file_ref in widget_file_refs], path="OpsPulseWidget")
    products_group = group(objects, "Products", [app_product_ref, widget_product_ref], name="Products")
    objects.append(f"\t\t{main_group_id} = {{isa = PBXGroup; children = ({app_group}, {core_group}, {widget_group}, {products_group}); sourceTree = \"<group>\"; }};")

    objects.append(
        f"\t\t{project_id} = {{isa = PBXProject; attributes = {{BuildIndependentTargetsInParallel = YES; "
        f"LastSwiftUpdateCheck = 1600; LastUpgradeCheck = 1600; TargetAttributes = {{{app_target} = {{CreatedOnToolsVersion = 16.0;}}; {widget_target} = {{CreatedOnToolsVersion = 16.0;}}; }}; }}; "
        f"buildConfigurationList = {project_config_list}; compatibilityVersion = \"Xcode 15.0\"; developmentRegion = en; hasScannedForEncodings = 0; "
        f"knownRegions = (en, Base); mainGroup = {main_group_id}; productRefGroup = {products_group_id}; projectDirPath = \"\"; projectRoot = \"\"; "
        f"targets = ({app_target}, {widget_target}); }};"
    )

    content = "\n".join([
        "// !$*UTF8*$!",
        "{",
        "\tarchiveVersion = 1;",
        "\tclasses = {};",
        "\tobjectVersion = 56;",
        "\tobjects = {",
        *objects,
        "\t};",
        f"\trootObject = {project_id};",
        "}",
    ])

    PROJECT_DIR.mkdir(exist_ok=True)
    (PROJECT_DIR / "project.pbxproj").write_text(content + "\n", encoding="utf-8")
    SCHEME_DIR.mkdir(parents=True, exist_ok=True)
    (SCHEME_DIR / "OpsPulse.xcscheme").write_text(scheme_xml(app_target), encoding="utf-8")
    print(f"Generated {PROJECT_DIR.relative_to(ROOT)} with {len(app_swift)} app Swift files and {len(widget_swift)} widget Swift files.")


def scheme_xml(app_target: str) -> str:
    return f'''<?xml version="1.0" encoding="UTF-8"?>
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
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{app_target}"
               BuildableName = "OpsPulse.app"
               BlueprintName = "OpsPulse"
               ReferencedContainer = "container:OpsPulse.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
      </Testables>
   </TestAction>
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
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{app_target}"
            BuildableName = "OpsPulse.app"
            BlueprintName = "OpsPulse"
            ReferencedContainer = "container:OpsPulse.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{app_target}"
            BuildableName = "OpsPulse.app"
            BlueprintName = "OpsPulse"
            ReferencedContainer = "container:OpsPulse.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
'''


if __name__ == "__main__":
    main()
