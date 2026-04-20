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
}
