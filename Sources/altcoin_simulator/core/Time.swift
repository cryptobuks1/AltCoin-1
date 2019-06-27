//
//  Time.swift
//  altcoin-simulator
//
//  Created by Timothy Prepscius on 6/16/19.
//

import Foundation

// this stuff needs to be changed to use an actual calendar object, but I'm lazy for now
class TimeQuantities
{
	static let Second = 1.0
	static let Minute = 60.0 * Second
	static let Hour = 60.0 * Minute
	static let Day = 24 * Hour
	static let Week = 6 * Day
}

// this stuff needs to be changed to use an actual calendar object, but I'm lazy for now
class StandardTimeEquations
{
	static let nextMinute : Equation_P1_R1 = { return $0 + TimeQuantities.Minute }
	static let nextHour : Equation_P1_R1 = { return $0 + TimeQuantities.Hour }
	static let nextDay : Equation_P1_R1 = { return $0 + TimeQuantities.Day }
}

// this stuff needs to be changed to use an actual calendar object, but I'm lazy for now
class StandardTimeRanges
{
	static let relativeNow : Time = 0
	static let oneDay : TimeRange = -TimeQuantities.Day ... relativeNow
	static let oneWeek : TimeRange = -TimeQuantities.Week ... relativeNow
	static let fourWeeks : TimeRange = (4.0 * -TimeQuantities.Week) ... relativeNow
}

class TimeEvents
{
	static func toUnix(_ t: TimeInterval) -> Int64
	{
		return Int64(Date(timeIntervalSinceReferenceDate: t).timeIntervalSince1970) * 1000
	}

	static func toTimeInterval(_ t: Double) -> TimeInterval
	{
		return Date(timeIntervalSince1970: t/1000.0).timeIntervalSinceReferenceDate
	}

	static func toDate(_ isoDate: String) -> Date
	{
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
		dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
		let date = dateFormatter.date(from:isoDate)!
		return date
	}
	
	static func toString(_ time: TimeInterval) -> String
	{
		return Date(timeIntervalSinceReferenceDate: time).description
	}
	
	static func toString(_ range: TimeRange) -> String
	{
		return "(\(TimeEvents.toString(range.lowerBound)) ... \(TimeEvents.toString(range.upperBound)))"
	}

	static let firstBubbleStart = toDate("2017-03-01T00:00:00+0000").timeIntervalSinceReferenceDate
	static let firstBubbleCrash = toDate("2017-12-16T00:00:00+0000").timeIntervalSinceReferenceDate
	static let secondBubbleStart = toDate("2019-02-01T00:00:00+0000").timeIntervalSinceReferenceDate
	static let year2019 = toDate("2019-01-01T00:00:00+0000").timeIntervalSinceReferenceDate

	static let now = Date().timeIntervalSinceReferenceDate
	static let safeNow = now - TimeQuantities.Hour
}
