// swift-tools-version:5.7
//
//  Package.swift — VTMProductLib
//
//  Swift Package Manager manifest for Viatom's iOS BLE SDK.
//
//  This file belongs at the root of https://github.com/viatom-dev/VTProductLib,
//  next to VTMProductLib.podspec and VTMProductLib.xcframework. SPM and CocoaPods
//  serve the exact same committed binary from the same tag, so there is no separate
//  release artifact and no checksum to keep in sync.
//
//  Releasing is therefore just: update the xcframework, bump spec.version, tag.
//
//  Tags must be three-component semver, with no "v" prefix, to be visible to SPM.
//  The repository's old two-component tags (v1.4 … v1.9) have been removed; 1.5.7
//  is the first SPM-resolvable tag.
//
import PackageDescription

let package = Package(
    name: "VTMProductLib",
    // iOS: matches spec.ios.deployment_target = "11.0" in the podspec. The binary's
    // LC_VERSION_MIN_IPHONEOS is 11.0; Xcode 15+ raises its own floor to iOS 12.
    //
    // macCatalyst: the xcframework carries an ios-arm64_x86_64-maccatalyst slice
    // built with minos 14.0. There is no native macOS slice.
    platforms: [
        .iOS(.v11),
        .macCatalyst(.v14)
    ],
    products: [
        // Both targets ship together on purpose: the xcframework carries the code,
        // VTMProductLibLinker carries the libc++ link flag it needs. See below.
        .library(
            name: "VTMProductLib",
            targets: ["VTMProductLib", "VTMProductLibLinker"]
        )
    ],
    targets: [
        // The xcframework committed at the repository root. Three slices:
        //   ios-arm64                       device
        //   ios-arm64_x86_64-simulator      simulator (includes arm64 for Apple silicon)
        //   ios-arm64_x86_64-maccatalyst    Mac Catalyst
        .binaryTarget(
            name: "VTMProductLib",
            path: "VTMProductLib.xcframework"
        ),

        // VTMProductLib is a *static* framework and parts of it are Objective-C++
        // (signal filtering and waveform decompression). Static archives do not pull
        // in the C++ standard library, and clang emits no autolink hint for it, so an
        // Objective-C-only app fails to link with ~44 undefined std:: symbols.
        //
        // Swift apps happen to get libc++ transitively through the Swift runtime,
        // which is why this is easy to miss. This is the SPM equivalent of the
        // podspec's `spec.libraries = 'c++', 'stdc++'`.
        //
        // binaryTarget cannot carry linkerSettings, hence this otherwise empty
        // companion target. Consumers never import it.
        //
        // System frameworks (CoreBluetooth, Security, CFNetwork, CoreGraphics,
        // Foundation, CoreFoundation) are autolinked via LC_LINKER_OPTION inside the
        // archive and deliberately not repeated here.
        .target(
            name: "VTMProductLibLinker",
            path: "Sources/VTMProductLibLinker",
            linkerSettings: [
                .linkedLibrary("c++")
            ]
        )
    ]
)
