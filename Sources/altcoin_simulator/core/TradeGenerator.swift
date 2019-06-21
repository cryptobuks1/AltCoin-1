//
//  TradeGenerator.swift
//  altcoin-simulator
//
//  Created by Timothy Prepscius on 6/17/19.
//

import Foundation

protocol TradeGenerator {
	func generateTrades () -> [Trade]?
}

class TradeGeneratorWithDataProvider : TradeGenerator
{
	var relativeDataProvider : RelativeDataProvider
	
	init (relativeDataProvider : RelativeDataProvider)
	{
		self.relativeDataProvider = relativeDataProvider
	}
	
	func generateTrades () -> [Trade]?
	{
		return nil
	}
}

class TradeGeneratorWithDataProviderAndTimeRange : TradeGeneratorWithDataProvider
{
	var timeRange: TimeRange
	var resolution: Resolution

	init (relativeDataProvider : RelativeDataProvider, timeRange: TimeRange, resolution: Resolution)
	{
		self.timeRange = timeRange
		self.resolution = resolution

		super.init(relativeDataProvider: relativeDataProvider)
	}
}
