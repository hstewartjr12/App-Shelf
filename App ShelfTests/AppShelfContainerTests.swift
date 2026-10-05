import Testing
import Foundation
@testable import App_Shelf

@Suite("AppShelfContainer")
struct AppShelfContainerTests {

    @Test("iOS prefers the app group store location when available")
    func iosUsesAppGroupWhenAvailable() {
        let groupURL = URL(fileURLWithPath: "/tmp/group")
        let appSupportURL = URL(fileURLWithPath: "/tmp/app-support")

        let url = AppShelfContainer.persistentStoreURL(
            appGroupURL: groupURL,
            applicationSupportURL: appSupportURL,
            platform: .iOS
        )

        #expect(url.path == "/tmp/group/AppShelf.store")
    }

    @Test("iOS falls back to application support without an app group")
    func iosFallsBackToApplicationSupport() {
        let appSupportURL = URL(fileURLWithPath: "/tmp/app-support")

        let url = AppShelfContainer.persistentStoreURL(
            appGroupURL: nil,
            applicationSupportURL: appSupportURL,
            platform: .iOS
        )

        #expect(url.path == "/tmp/app-support/AppShelf.store")
    }

    @Test("macOS uses an app-local application support subdirectory")
    func macOSUsesAppLocalDirectory() {
        let groupURL = URL(fileURLWithPath: "/tmp/group")
        let appSupportURL = URL(fileURLWithPath: "/tmp/app-support")

        let url = AppShelfContainer.persistentStoreURL(
            appGroupURL: groupURL,
            applicationSupportURL: appSupportURL,
            platform: .macOS
        )

        #expect(url.path == "/tmp/app-support/App Shelf/AppShelf.store")
    }

    @Test("CloudKit is disabled while XCTest is hosting the app")
    func cloudKitDisabledForTests() {
        #expect(
            AppShelfContainer.shouldUseCloudKit(
                environment: ["XCTestConfigurationFilePath": "/tmp/test.xctestconfiguration"]
            ) == false
        )
    }

    @Test("CloudKit can be explicitly disabled for local verification")
    func cloudKitDisabledByEnvironmentFlag() {
        #expect(
            AppShelfContainer.shouldUseCloudKit(
                environment: ["APPSHELF_DISABLE_CLOUDKIT": "1"]
            ) == false
        )
    }

    @Test("CloudKit remains enabled for normal app launches")
    func cloudKitEnabledNormally() {
        #expect(
            AppShelfContainer.shouldUseCloudKit(
                environment: ["SIMULATOR_DEVICE_NAME": "iPhone 17"],
                infoDictionary: [:]
            ) == true
        )
    }

    @Test("CloudKit is disabled inside app extensions")
    func cloudKitDisabledForExtensions() {
        #expect(
            AppShelfContainer.shouldUseCloudKit(
                environment: [:],
                infoDictionary: ["NSExtension": ["NSExtensionPointIdentifier": "com.apple.widgetkit-extension"]]
            ) == false
        )
    }
}
