//
//  DataTypes.swift
//  AltCoinSimulator
//
//  Created by Timothy Prepscius on 6/15/19.
//  Copyright © 2019 Timothy Prepscius. All rights reserved.
//

import Foundation

enum Resolution {
	case minute
	case hour
	case day
}

typealias Real = Double
typealias Time = Double
typealias CurrencyId = String

struct Currency
{
	let id: CurrencyId
	let name: String
	let rank: Int
	let tokens : [String]
}

struct HistoricalValue : Hashable
{
	let time: Time
	let value: Real
}

struct HistoricalValues
{
	var samples : [HistoricalValue]
}

typealias TimeRange = ClosedRange<Time>

struct TimeRanges
{
	var ranges : [TimeRange]
}

typealias DataKey = String

struct CurrencyData
{
	let key: DataKey

	let ranges: TimeRanges
	let values: HistoricalValues
	
	let cacheTime: Time
	var wasCached = false
}

struct Trade
{
	let from, to: CurrencyId;
	let amount: Double
	let rate: Double
	let time: Time
}

struct TradeBook
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
    	case cacheTime
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

