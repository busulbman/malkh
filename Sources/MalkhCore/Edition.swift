import Foundation

/// Which edition this binary is. The Mac App Store edition is built with MALKH_APPSTORE=1
/// (Swift flag APPSTORE): tools ship inside the app, and features App Review does not allow
/// (downloaded executables, web media downloads, controlling other apps' windows,
/// a self-updater, LibreOffice) are left out.
public enum MalkhEdition {
    #if APPSTORE
    public static let appStore = true
    #else
    public static let appStore = false
    #endif

    /// Document conversions that run without LibreOffice; the only ones the App Store edition offers.
    static let nativeDocumentRoutes: [String: Set<String>] = ["pdf": ["png", "jpg", "txt", "md"], "html": ["pdf"], "docx": ["pages"]]
    static func allows(_ input: URL, to format: String) -> Bool {
        guard appStore else { return true }
        switch FileCategory.detect(input) {
        case .pdf, .document, .presentation, .spreadsheet, .ebook:
            return nativeDocumentRoutes[FeatureCatalog.normalizedExtension(input)]?.contains(format) ?? false
        default: return true
        }
    }
}
