import XCTest
import CoreGraphics
import PDFKit
@testable import MalkhCore

final class AppLocalizationTests:XCTestCase {
    func testEveryToolAndWindowPlacementHasTurkishCopy() {
        for source in Array(FeatureCatalog.toolNames.values)+ToolKind.allCases.map(\.title)+WindowPlacement.allCases.map(\.title) {
            XCTAssertNotEqual(AppLocalization.text(source,language:"tr"),source,source)
        }
        XCTAssertEqual(AppLocalization.text("Language",language:"tr"),"Dil")
        XCTAssertEqual(AppLocalization.text("Library",language:"tr"),"Kitaplık")
        XCTAssertEqual(AppLocalization.text("READ QR CODES",language:"tr"),"QR KODLARINI OKU")
        XCTAssertEqual(AppLocalization.text("Resize Image".uppercased(),language:"tr"),"GÖRSELİ BOYUTLANDIR")
    }
    func testWordBoundTemplatesDoNotSwallowProseOrTitles() {
        XCTAssertNotEqual(AppLocalization.text("Add or change files",language:"tr"),"Add or change dosya")
        XCTAssertEqual(AppLocalization.text("3 files",language:"tr"),"3 dosya")
        XCTAssertEqual(AppLocalization.text("Convert to JPG",language:"tr"),"JPG biçimine dönüştür")
        XCTAssertEqual(AppLocalization.text("Convert to JPG · Malkh",language:"tr"),"JPG biçimine dönüştür · Malkh")
    }
    func testTurkishUppercaseKeepsLatinProductAndKeyNames() {
        XCTAssertEqual(AppLocalization.text("SHOW MALKH IN FINDER",language:"tr"),"MALKH'Yİ FINDER'DA GÖSTER")
        XCTAssertEqual(AppLocalization.uppercased("Shift'e bas",language:"tr"),"SHIFT'E BAS")
        XCTAssertEqual(AppLocalization.uppercased("Görseli seç",language:"tr"),"GÖRSELİ SEÇ")
        XCTAssertEqual(AppLocalization.uppercased("Shift",language:"en"),"SHIFT")
    }
    func testCatalogPlaceholdersMatchWithoutChangingFormatsOrShortcuts() {
        let marker=try! NSRegularExpression(pattern:#"\{[0-9]\}"#)
        func tokens(_ value:String)->[String] { marker.matches(in:value,range:NSRange(value.startIndex...,in:value)).compactMap{Range($0.range,in:value).map{String(value[$0])}}.sorted() }
        for (source,translation) in AppLocalization.turkish {
            XCTAssertFalse(translation.isEmpty,source)
            XCTAssertEqual(tokens(source),tokens(translation),source)
        }
        for code in ["png","MP4","Ctrl+Shift","⌘S","00:01.250"] { XCTAssertEqual(AppLocalization.text(code,language:"tr"),code) }
    }
    func testTranslatedCatalogsOnlyUseTurkishSourceStrings() {
        let reference=Set(AppLocalization.turkish.keys)
        XCTAssertFalse(reference.isEmpty)
        for language in AppLocalization.supportedLanguages where language != "en" {
            let catalog=AppLocalization.catalog(for:language)
            XCTAssertTrue(Set(catalog.keys).isSubset(of:reference),"\(language) has keys that Turkish.json lacks")
            XCTAssertFalse(catalog.values.contains{$0.isEmpty},language)
        }
        XCTAssertTrue(AppLocalization.catalog(for:"en").isEmpty)
    }
}
