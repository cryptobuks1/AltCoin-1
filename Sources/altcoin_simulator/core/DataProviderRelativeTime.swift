//
//  RelativeDataProvider.swift
//  altcoin-simulator
//
//  Created by Timothy Prepscius on 6/16/19.
//

import Foundation

protocol RelativeDataProvider : TimeProvider
{
	func getCurrencies () -> [Currency]?
	func getCurrencyData (for currency: Currency, key: DataKey, in relativeRange: TimeRange, with resolution: Resolution) -> CurrencyData?
}

class RelativeDataProviderConcrete : RelativeDataProvider
{
	static let log = LogNull(clazz: RelativeDataProviderConcrete.self)
	
	let dataProvider : DataProvider
	let timeProvider : TimeProvider
	
	init (dataProvider : DataProvider, timeProvider: TimeProvider)
	{
		self.dataProvider = dataProvider
		self.timeProvider = timeProvider
	}

	var now : Time {
		return timeProvider.now
	}

	func getCurrencies () -> [Currency]?
	{
		return dataProvider.getCurrencies()
	}
	
	func getCurrencyData (for currency: Currency, key: DataKey, in relativeRange: TimeRange, with resolution: Resolution) -> CurrencyData?
	{
		let now = timeProvider.now
		
		let range = TimeRange(uncheckedBounds: (now + relativeRange.lowerBound, now + relativeRange.upperBound ))
		
		RelativeDataProviderConcrete.log.print("getCurrencyData using timeRange \(TimeEvents.toString(range))")

		return dataProvider.getCurrencyData(for: currency, key: key, in: range, with: resolution)
	}

}
