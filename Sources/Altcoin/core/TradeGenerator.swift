//
//  TradeGenerator.swift
//  altcoin-simulator
//
//  Created by Timothy Prepscius on 6/17/19.
//

import Foundation

public protocol TradeGenerator {
	func generateTrades () throws -> [Trade]?
}

public class TradeGeneratorWithDataProvider : TradeGenerator
{
	var relativeDataProvider : RelativeDataProvider
	
	public init (relativeDataProvider : RelativeDataProvider)
	{
		self.relativeDataProvider = relativeDataProvider
	}
	
	public func generateTrades () throws -> [Trade]?
	{
		return nil
	}
}

public class TradeGeneratorWithDataProviderAndTimeRange : TradeGeneratorWithDataProvider
{
	var timeRange: TimeRange
	var resolution: Resolution

	public init (relativeDataProvider : RelativeDataProvider, timeRange: TimeRange, resolution: Resolution)
	{
		self.timeRange = timeRange
		self.resolution = resolution

		super.init(relativeDataProvider: relativeDataProvider)
	}
}
