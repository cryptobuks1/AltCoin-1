//
//  RelativeDataProvider.swift
//  altcoin-simulator
//
//  Created by Timothy Prepscius on 6/16/19.
//

import Foundation

public protocol RelativeDataProvider : TimeProvider
{
	func getCurrencies () throws -> CurrencySet?
	func getCurrencyData (for currency: Currency, key: DataKey, in relativeRange: TimeRange, with resolution: Resolution) throws -> CurrencyData? 
}

public class RelativeDataProviderConcrete : RelativeDataProvider
{
	static let log = LogNull(clazz: RelativeDataProviderConcrete.self)
	
	let dataProvider : DataProvider
	let timeProvider : TimeProvider
	
	public init (dataProvider : DataProvider, timeProvider: TimeProvider)
	{
		self.dataProvider = dataProvider
		self.timeProvider = timeProvider
	}

	public var now : Time {
		return timeProvider.now
	}

	public func getCurrencies () throws -> CurrencySet?
	{
		return try dataProvider.getCurrencies()
	}
	
	public func getCurrencyData (for currency: Currency, key: DataKey, in relativeRange: TimeRange, with resolution: Resolution) throws -> CurrencyData?
	{
		let now = timeProvider.now
		
		let range = TimeRange(uncheckedBounds: (now + relativeRange.lowerBound, now + relativeRange.upperBound ))
		
		RelativeDataProviderConcrete.log.print("getCurrencyData using timeRange \(TimeEvents.toString(range))")

		return try dataProvider.getCurrencyData(for: currency, key: key, in: range, with: resolution)
	}

}
