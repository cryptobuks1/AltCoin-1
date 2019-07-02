//
//  DataTypes+Log.swift
//  altcoin-simulator
//
//  Created by Timothy Prepscius on 6/20/19.
//

import Foundation

extension TimeRange
{
	public static let log = LogNull(clazz: TimeRange.self)
}

extension HistoricalValues
{
	public static let log = Log(clazz: HistoricalValues.self)
}

extension TimeRanges
{
	public static let log = LogNull(clazz: TimeRanges.self)
}
