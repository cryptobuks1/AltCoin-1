//
//  DataProvider.swift
//  AltCoinSimulator
//
//  Created by Timothy Prepscius on 6/15/19.
//  Copyright © 2019 Timothy Prepscius. All rights reserved.
//

import Foundation

public protocol DataProvider
{
	func getCurrencies () throws -> CurrencySet?
	func getCurrencyData (for currency: Currency, key: DataKey, in range: TimeRange, with resolution: Resolution) throws -> CurrencyData?
	func getCurrencyRanges (for currency: Currency, key: DataKey, in range: TimeRange) throws -> TimeRanges?
	
	// when we request one key, we might get several, or a different time range, this enables caching all the extra data immediately
	func getCurrencyDatas (for currency: Currency, key: DataKey, in range: TimeRange, with resolution: Resolution) throws -> [CurrencyData]?
}

public protocol DataSink
{
	func putCurrencies (_ currencies: CurrencySet) throws
	func putCurrencyDatas (_ data: [CurrencyData], for currency: Currency, in range: TimeRange, with resolution: Resolution) throws
}

public protocol DataCache : DataProvider, DataSink
{
	
}
