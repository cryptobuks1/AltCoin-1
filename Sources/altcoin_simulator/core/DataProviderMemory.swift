//
//  MemoryDataProvider.swift
//  altcoin-simulator
//
//  Created by Timothy Prepscius on 6/16/19.
//

import Foundation

class DataProviderMemory : DataCache
{
	var currencies : [Currency]? = nil
	typealias KeyedCurrencyData = [DataKey:CurrencyData]
	var currencyDatas = [CurrencyId:KeyedCurrencyData]()

	init()
	{
	}

	func getCurrencies () -> [Currency]?
	{
		return currencies
	}
	
	func putCurrencies (_ data: [Currency])
	{
		currencies = data
	}

	func getCurrencyData (for currency: Currency, key: DataKey, in range: TimeRange, with resolution: Resolution) -> CurrencyData?
	{
		objc_sync_enter(self)
    	defer { objc_sync_exit(self) }

		return currencyDatas[currency.id]?[key]?.subset(range)
	}
	
	func getCurrencyDatas (for currency: Currency, key: DataKey, in range: TimeRange, with resolution: Resolution) -> [CurrencyData]?
	{
		if let data = getCurrencyData(for: currency, key: key, in: range, with: resolution)
		{
			if data.ranges.contains(range)
			{
				return [data]
			}
		}
		
		return nil
	}

	func putCurrencyDatas(_ datas: [CurrencyData], for currency: Currency, in range: TimeRange, with resolution: Resolution)
	{
		objc_sync_enter(self)
    	defer { objc_sync_exit(self) }

		var keyedCurrencyDatas = currencyDatas[currency.id] ?? [DataKey:CurrencyData]()
		
		for data in datas
		{
			if let kc = keyedCurrencyDatas[data.key]
			{
				keyedCurrencyDatas[data.key] = kc.merge(data)
			}
			else
			{
				keyedCurrencyDatas[data.key] = data
			}
		}
		
		currencyDatas[currency.id] = keyedCurrencyDatas
	}
}
