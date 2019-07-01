//
//  MergeSubsetTests.swift
//  altcoin_simulatorTests
//
//  Created by Timothy Prepscius on 6/30/19.
//

import XCTest
@testable import AltCoin

final class SubsetTest: XCTestCase {
    func subset1() throws {
		
		let samples : [HistoricalValue] = (0..<100).map { return HistoricalValue(time: Double($0), value: Double($0)) }
    	let v = HistoricalValues(samples: samples)
		
		let sub = v.subRange(5.0 ... 10.0)
		print(sub)
		let subTimes = sub.samples.map { return $0.time }
		
        XCTAssertEqual(subTimes, [5.0, 6.0, 7.0, 8.0, 9.0, 10.0])

    }

    static var allTests = [
        ("subset1", subset1),
    ]
}
