//
//  OxfordTests.swift
//  OxfordTests
//
//  Created by Sam Ritchie on 13/01/2016.
//  Copyright © 2016 codesplice pty ltd. All rights reserved.
//

import XCTest
import Foundation
import SwiftCheck
@testable import Oxford

extension String {
    func quote() -> String {
        return "\"" + self.stringByReplacingOccurrencesOfString("\"", withString: "\"\"") + "\""
    }
}

extension Array {
    
    static func shrinkArrayOnly(array: [Element]) -> [[Element]] {
        guard array.count > 1 else { return [] }
        var comb = [[Element]]()
        for i in 0..<array.count {
            comb.append(array.exceptIndex(i))
        }
        return comb
    }
        
    private func exceptIndex(n: Int) -> [Element] {
        var ret = [Element]()
        for (i, e) in self.enumerate() {
            if i != n { ret.append(e) }
        }
        return ret
    }
}

struct CSVFile: Arbitrary, CustomDebugStringConvertible {
    let headers: [String]
    let data: [[String]]

    static func create(headers: [String]) ->  [[String]] -> CSVFile {
        return { data in CSVFile(headers: headers, data: data) }
    }
    
    static var arbitrary: SwiftCheck.Gen<CSVFile> {
        return Int.arbitrary.suchThat { $0 > 0 }.flatMap { fieldCount in
            return CSVFile.create <^> String.arbitrary.proliferateSized(fieldCount) <*> String.arbitrary.proliferateSized(fieldCount).proliferate
        }
    }
    
    static func shrink(file: CSVFile) -> [CSVFile] {
        print("shrinking...")
        return shrinkColumns(file) + shrinkRows(file)
    }
    
    static func shrinkRows(file: CSVFile) -> [CSVFile] {
        return [[String]].shrinkArrayOnly(file.data).map { d in CSVFile(headers: file.headers, data: d) }
    }
    
    static func shrinkColumns(file: CSVFile) -> [CSVFile] {
        let headersArrays =  [String].shrinkArrayOnly(file.headers)
        func rowsForHeaders(newHeaders: [String]) -> [[String]] {
            return file.data.map { line in
                return newHeaders.map { h in
                    return line[file.headers.indexOf(h)!]
                }
            }
        }
        return headersArrays.map { hs in CSVFile.create(hs)(rowsForHeaders(hs)) }
    }
    
    func asString() -> String {
        return headers.map { $0.quote() }.joinWithSeparator(",") + "\r\n" + data.map { l in l.map { $0.quote() }.joinWithSeparator(",") }.joinWithSeparator("\r\n")
    }

    func asData() -> NSData {
        return (self.asString() as NSString).dataUsingEncoding(NSUTF8StringEncoding)!
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
    
    var debugDescription: String {
        return self.asString()
    }
}

class OxfordTests: XCTestCase {
    
    func testBasicParsing() {
        let csv = try! CSV(path: NSBundle(forClass: OxfordTests.self).URLForResource("test", withExtension: "csv")!.path!)
        let expected = [
            ["One": "1", "Three": "3", "Two": "2"],
            ["One": "4", "Three": "6", "Two": "5"]
        ]
        XCTAssert(csv.elementsEqual(expected, isEquivalent: ==))
    }

    func testAll() {
        property("parsed rows equal source data") <- forAll { (file: CSVFile) in
            //print(file)
            let parsed = Array(CSV(data: file.asData()))
            return parsed == file.asDictionaries()
        }
    }
}
