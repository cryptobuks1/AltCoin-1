import XCTest
@testable import AltCoin

final class AltCoinTests: XCTestCase {
	let log = Log(clazz: AltCoinTests.self)

//    func testExample() {
//        // This is an example of a functional test case.
//        // Use XCTAssert and related functions to verify your tests produce the correct
//        // results.
//        XCTAssertEqual(AltCoin().text, "Hello, World!")
//    }
	
    func subset1() throws {
		let samples : [HistoricalValue] = (1...100).map { return HistoricalValue(time: Double($0), value: Double($0)) }
    	let v = HistoricalValues(samples: samples)
		
		let sub1 = v.subRange(5.0 ... 10.0).samples.map { $0.time }
        XCTAssertEqual(sub1, [5.0, 6.0, 7.0, 8.0, 9.0, 10.0])
		log.print(sub1)
		
		let sub2 = v.subRange(5.5 ... 10.0).samples.map { $0.time }
        XCTAssertEqual(sub2, [6.0, 7.0, 8.0, 9.0, 10.0])
		log.print(sub2)

		let sub3 = v.subRange(5.5 ... 9.5).samples.map { $0.time }
        XCTAssertEqual(sub3, [6.0, 7.0, 8.0, 9.0])
		log.print(sub3)

		let sub4 = v.subRange(5.5 ... 5.6).samples.map { $0.time }
        XCTAssertEqual(sub4, [])
		log.print(sub4)

		let sub5 = v.subRange(5.5 ... 6.5).samples.map { $0.time }
        XCTAssertEqual(sub5, [6.0])
		log.print(sub5)

		let sub6 = v.subRange(5.0 ... 5.0).samples.map { $0.time }
        XCTAssertEqual(sub6, [5.0])
		log.print(sub6)

		let sub7 = v.subRange(0.0 ... 1.0).samples.map { $0.time }
        XCTAssertEqual(sub7, [1.0])
		log.print(sub7)

		let sub8 = v.subRange(0.0 ... 1.5).samples.map { $0.time }
        XCTAssertEqual(sub8, [1.0])
		log.print(sub8)

		let sub9 = v.subRange(0.0 ... 0.1).samples.map { $0.time }
        XCTAssertEqual(sub9, [])
		log.print(sub9)

		let sub10 = v.subRange(99.5 ... 100.5).samples.map { $0.time }
        XCTAssertEqual(sub10, [100.0])
		log.print(sub10)

		let sub11 = v.subRange(100.1 ... 100.5).samples.map { $0.time }
        XCTAssertEqual(sub11, [])
		log.print(sub11)

		let sub12 = v.subRange(100.0 ... 100.5).samples.map { $0.time }
        XCTAssertEqual(sub12, [100.0])
		log.print(sub12)
    }

    func notInRange1() throws {
		let samples : [HistoricalValue] = (1...8).map { return HistoricalValue(time: Double($0), value: Double($0)) }
    	let v = HistoricalValues(samples: samples)
		
		let nr1 = v.notRange(3.0 ... 6.0).samples.map { $0.time }
        XCTAssertEqual(nr1, [1.0, 2.0, 7.0, 8.0])
		log.print(nr1)
		
		let nr2 = v.notRange(2.5 ... 6.5).samples.map { $0.time }
        XCTAssertEqual(nr2, [1.0, 2.0, 7.0, 8.0])
		log.print(nr2)

		let nr3 = v.notRange(1.0 ... 8.0).samples.map { $0.time }
        XCTAssertEqual(nr3, [])
		log.print(nr3)

		let nr4 = v.notRange(0.5 ... 8.5).samples.map { $0.time }
        XCTAssertEqual(nr4, [])
		log.print(nr4)

		let nr5 = v.notRange(1.0 ... 7.0).samples.map { $0.time }
        XCTAssertEqual(nr5, [8.0])
		log.print(nr5)

		let nr6 = v.notRange(2.0 ... 8.0).samples.map { $0.time }
        XCTAssertEqual(nr6, [1.0])
		log.print(nr6)
    }

    func merging() throws {
		let samples1_4 : [HistoricalValue] = (1...4).map { return HistoricalValue(time: Double($0), value: Double($0)) }
		let samples3_4 : [HistoricalValue] = (3...4).map { return HistoricalValue(time: Double($0), value: Double($0)) }
		let samples3_6 : [HistoricalValue] = (3...6).map { return HistoricalValue(time: Double($0), value: Double($0)) }
		let samples5_6 : [HistoricalValue] = (5...6).map { return HistoricalValue(time: Double($0), value: Double($0)) }
		let samples6_6 : [HistoricalValue] = (6...6).map { return HistoricalValue(time: Double($0), value: Double($0)) }
		let samples1_6 : [HistoricalValue] = (1...6).map { return HistoricalValue(time: Double($0), value: Double($0)) }
		let d1_4 = samples1_4.map { $0.time }
		let d3_4 = samples3_4.map { $0.time }
		let d3_6 = samples3_6.map { $0.time }
		let d5_6 = samples5_6.map { $0.time }
		let d6_6 = samples6_6.map { $0.time }
		let d1_6 = samples1_6.map { $0.time }
		let d1_N5_6 = [1.0,2.0,3.0,4.0,6.0]

		let H = { (s: [HistoricalValue]) -> HistoricalValues in return HistoricalValues(samples: s) }

		let m1 = H(samples1_4).merge(H(samples3_4)).samples.map { $0.time }
        XCTAssertEqual(m1, d1_4)
		log.print(m1)

		let m2 = H(samples1_4).merge(H(samples1_4)).samples.map { $0.time }
        XCTAssertEqual(m2, d1_4)
		log.print(m2)

		let m3 = H(samples1_4).merge(H(samples3_6)).samples.map { $0.time }
        XCTAssertEqual(m3, d1_6)
		log.print(m3)

		let m4 = H(samples1_4).merge(H(samples5_6)).samples.map { $0.time }
        XCTAssertEqual(m4, d1_6)
		log.print(m4)

		let m5 = H(samples1_4).merge(H(samples5_6)).samples.map { $0.time }
        XCTAssertEqual(m5, d1_6)
		log.print(m5)

		let m6 = H(samples1_4).merge(H(samples6_6)).samples.map { $0.time }
        XCTAssertEqual(m6, d1_N5_6)
		log.print(m6)

    }

    func testExample() throws {
		try subset1()
		try notInRange1()
		try merging()
    }


    static var allTests = [
        ("testExample", testExample)
    ]
}
