//
//  Time.swift
//  altcoin-simulator
//
//  Created by Timothy Prepscius on 6/16/19.
//

import Foundation

// this stuff needs to be changed to use an actual calendar object, but I'm lazy for now
public class TimeQuantities
{
	public static let Second = 1.0
	public static let Minute = 60.0 * Second
	public static let Hour = 60.0 * Minute
	public static let Day = 24 * Hour
	public static let Week = 6 * Day
}

// this stuff needs to be changed to use an actual calendar object, but I'm lazy for now
public class StandardTimeEquations
{
	public static let nextMinute : Equation_P1_R1 = { return $0 + TimeQuantities.Minute }
	public static let nextHour : Equation_P1_R1 = { return $0 + TimeQuantities.Hour }
	public static let nextDay : Equation_P1_R1 = { return $0 + TimeQuantities.Day }
}

// this stuff needs to be changed to use an actual calendar object, but I'm lazy for now
public class StandardTimeRanges
{
	public static let relativeNow : Time = 0
	public static let oneDay : TimeRange = -TimeQuantities.Day ... relativeNow
	public static let oneWeek : TimeRange = -TimeQuantities.Week ... relativeNow
	public static let fourWeeks : TimeRange = (4.0 * -TimeQuantities.Week) ... relativeNow
}

public class TimeEvents
{
	public static func roundDown (_ t: TimeInterval, range r: TimeInterval) -> TimeInterval
	{
		return floor(t/r) * r
	}
	
	public static func roundUp (_ t: TimeInterval, range r: TimeInterval) -> TimeInterval
	{
		return ceil(t/r) * r
	}

	public static func toUnix(_ t: TimeInterval) -> Int64
	{
		return Int64(Date(timeIntervalSinceReferenceDate: t).timeIntervalSince1970) * 1000
	}

	public static func toTimeInterval(_ t: Double) -> TimeInterval
	{
		return Date(timeIntervalSince1970: t/1000.0).timeIntervalSinceReferenceDate
	}

	public static func toDate(_ isoDate: String) -> Date
	{
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
		dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
		let date = dateFormatter.date(from:isoDate)!
		return date
	}
	
	public static func toString(_ time: TimeInterval) -> String
	{
		return Date(timeIntervalSinceReferenceDate: time).description
	}
	
	public static func toString(_ range: TimeRange) -> String
	{
		return "(\(TimeEvents.toString(range.lowerBound)) ... \(TimeEvents.toString(range.upperBound)))"
	}

	public static let firstBubbleStart = toDate("2017-03-01T00:00:00+0000").timeIntervalSinceReferenceDate
	public static let firstBubbleCrash = toDate("2017-12-16T00:00:00+0000").timeIntervalSinceReferenceDate
	public static let secondBubbleStart = toDate("2019-02-01T00:00:00+0000").timeIntervalSinceReferenceDate
	public static let year2019 = toDate("2019-01-01T00:00:00+0000").timeIntervalSinceReferenceDate
	public static let oneMonthAgo = Date().timeIntervalSinceReferenceDate - 4 * TimeQuantities.Week
	public static let july1st2019 = toDate("2019-07-01T00:00:00+0000").timeIntervalSinceReferenceDate
	
	public static let now = Date().timeIntervalSinceReferenceDate
	public static let safeNow = now - TimeQuantities.Hour
}
