//
//  OxfordTests.swift
//  OxfordTests
//
//  Created by Sam Ritchie on 13/01/2016.
//  Copyright © 2016 codesplice pty ltd. All rights reserved.
//

import XCTest
@testable import Oxford

class OxfordTests: XCTestCase {
    
    // TODO: Use Swiftcheck like a boss
    func testBasicParsing() {
        let csv = try! CSV(path: NSBundle(forClass: OxfordTests.self).URLForResource("test", withExtension: "csv")!.path!)
        for line in csv.rows {
            print(line)
        }
    }
    
}
