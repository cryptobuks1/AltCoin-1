//
//  DataProvider.swift
//  AltCoinSimulator
//
//  Created by Timothy Prepscius on 6/15/19.
//  Copyright © 2019 Timothy Prepscius. All rights reserved.
//

import Foundation

protocol DataProvider
{
	func getCurrencies () throws -> [Currency]?
	func getCurrencyData (for currency: Currency, key: DataKey, in range: TimeRange, with resolution: Resolution) throws -> CurrencyData?
	
	// when we request one key, we might get several, this enables caching all the extra data immediately
	func getCurrencyDatas (for currency: Currency, key: DataKey, in range: TimeRange, with resolution: Resolution) throws -> [CurrencyData]?
}

protocol DataSink
{
	func putCurrencies (_ currencies: [Currency]) throws
	func putCurrencyDatas (_ data: [CurrencyData], for currency: Currency, in range: TimeRange, with resolution: Resolution) throws
}

protocol DataCache : DataProvider, DataSink
{
	
}
