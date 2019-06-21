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
	func getCurrencies () -> [Currency]?
	func getCurrencyData (for currency: Currency, key: DataKey, in range: TimeRange, with resolution: Resolution) -> CurrencyData?
	
	// when we request one key, we might get several, this enables caching all the extra data immediately
	func getCurrencyDatas (for currency: Currency, key: DataKey, in range: TimeRange, with resolution: Resolution) -> [CurrencyData]?
}

protocol DataSink
{
	func putCurrencies (_ currencies: [Currency])
	func putCurrencyDatas (_ data: [CurrencyData], for currency: Currency, in range: TimeRange, with resolution: Resolution)
}

protocol DataCache : DataProvider, DataSink
{
	
}
