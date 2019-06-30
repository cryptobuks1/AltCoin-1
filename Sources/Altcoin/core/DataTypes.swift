//
//  DataTypes.swift
//  AltCoinSimulator
//
//  Created by Timothy Prepscius on 6/15/19.
//  Copyright © 2019 Timothy Prepscius. All rights reserved.
//

import Foundation

public enum Resolution {
	case minute
	case hour
	case day
}

public typealias Real = Double
public typealias Time = Double
public typealias CurrencyId = String

public struct Currency
{
	let id: CurrencyId
	let name: String
	let rank: Int
	let tokens : [String]
	let timeRange: TimeRange
}

public struct CurrencySet
{
	var currencies : [Currency]
	
	init (currencies: [Currency])
	{
		self.currencies = currencies
		assert(!currencies.hasDuplicates({ $0.id }))
	}
}

public struct HistoricalValue : Hashable
{
	public let time: Time
	public let value: Real
}

public struct HistoricalValues
{
	public var samples : [HistoricalValue]
	
	public init (samples: [HistoricalValue])
	{
		self.samples = samples
		assert(samples.isSorted({ $0.time < $1.time }))
	}
}

public typealias TimeRange = ClosedRange<Time>

public struct TimeRanges
{
	var ranges : [TimeRange]
	
	init (ranges: [TimeRange])
	{
		self.ranges = ranges
		assert(ranges.isSorted({ $0.lowerBound < $1.lowerBound }))
	}

}

public typealias DataKey = String

public struct CurrencyData
{
	let key: DataKey

	let ranges: TimeRanges
	let values: HistoricalValues
	
	var wasCached = false
}

public struct Trade
{
	let from, to: CurrencyId;
	let amount: Double
	let rate: Double
	let time: Time
}

public struct TradeBook
{
	var trades: [Trade]
}

// -------


extension Currency : Codable
{
    enum CodingKeys : String, CodingKey
    {
    	case id
    	case name
    	case rank
    	case tokens
    	case timeRange
    }
}

extension CurrencySet : Codable
{
    enum CodingKeys : String, CodingKey
    {
    	case currencies
    }
}

extension HistoricalValue : Codable
{
    enum CodingKeys : String, CodingKey
    {
    	case time
    	case value
    }
}

extension HistoricalValues : Codable
{
    enum CodingKeys : String, CodingKey
    {
    	case samples
    }
}

extension TimeRanges : Codable
{
    enum CodingKeys : String, CodingKey
    {
    	case ranges
	}
}

extension CurrencyData : Codable
{
    enum CodingKeys : String, CodingKey
    {
    	case key
    	case values
    	case ranges
    }
}

extension Trade : Codable
{
    enum CodingKeys : String, CodingKey
    {
    	case from
    	case to
    	case amount
    	case rate
    	case time
    }
}

extension TradeBook : Codable
{
    enum CodingKeys : String, CodingKey
    {
    	case trades
    }
}

