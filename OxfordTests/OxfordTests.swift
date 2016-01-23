//
//  OxfordTests.swift
//  OxfordTests
//
//  Created by Sam Ritchie on 13/01/2016.
//  Copyright © 2016 codesplice pty ltd. All rights reserved.
//

import XCTest
import SwiftCheck
@testable import Oxford

struct CSVLine: Arbitrary {
    let values: [String]
    
    static var arbitrary: SwiftCheck.Gen<CSVLine> {
        return CSVLine.init <^> [String].arbitrary
    }
}

struct CSVFile: Arbitrary {
    let headers: [String]
    let data: [[String]]

    static func create(headers: [String]) ->  [[String]] -> CSVFile {
        return { data in CSVFile(headers: headers, data: data) }
    }
    
    static var arbitrary: SwiftCheck.Gen<CSVFile> {
        // TODO: field counts should match
        return Int.arbitrary.suchThat { $0 > 0 }.flatMap { fieldCount in
            return CSVFile.create <^> [String].arbitrary.resize(fieldCount) <*> sequence([[String].arbitrary.resize(fieldCount)])
        }
    }
    
    func csvData() -> NSData {
        let str = headers.joinWithSeparator(",") + "\r\n" + data.map { $0.joinWithSeparator(",") }.joinWithSeparator("\r\n")
        return (str as NSString).dataUsingEncoding(NSUTF8StringEncoding)!
    }
    
    func asDictionaries() -> [[String: String]] {
        return data.map { values in
            return zip(headers, values).reduce([:]) { (acc: [String: String], p: (String, String)) in
                var dict = acc
                dict[p.0] = p.1
                return dict
            }
        }
    }
}

class OxfordTests: XCTestCase {
    
    // TODO: Use Swiftcheck like a boss
    func testBasicParsing() {
        let csv = try! CSVSequence(path: NSBundle(forClass: OxfordTests.self).URLForResource("test", withExtension: "csv")!.path!)
        let expected = [
            ["One": "1", "Three": "3", "Two": "2"],
            ["One": "4", "Three": "6", "Two": "5"]
        ]
        XCTAssert(csv.elementsEqual(expected, isEquivalent: ==))
    }
    
    func testAll() {
        property("values match") <- forAll { (file: CSVFile) in
            return true
        }
    }
}
