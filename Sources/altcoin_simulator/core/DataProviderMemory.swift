//
//  MemoryDataProvider.swift
//  altcoin-simulator
//
//  Created by Timothy Prepscius on 6/16/19.
//

import Foundation

class DataProviderMemory : DataCache
{
	let lock = ReadWriteLock()
	
	var currencies : [Currency]? = nil
	typealias KeyedCurrencyData = [DataKey:CurrencyData]
	var currencyDatas = [CurrencyId:KeyedCurrencyData]()

	init()
	{
	}

	func getCurrencies () -> [Currency]?
	{
		return lock.read {
			return currencies
		}
	}
	
	func putCurrencies (_ data: [Currency])
	{
		return lock.write {
			currencies = data
		}
	}

	func getCurrencyData (for currency: Currency, key: DataKey, in range: TimeRange, with resolution: Resolution) -> CurrencyData?
	{
		return lock.read {
			return currencyDatas[currency.id]?[key]?.subset(range)
		}
	}
	
	func getCurrencyDatas (for currency: Currency, key: DataKey, in range: TimeRange, with resolution: Resolution) -> [CurrencyData]?
	{
		return lock.read {
			if let data = getCurrencyData(for: currency, key: key, in: range, with: resolution)
			{
				if data.ranges.contains(range)
				{
					return [data]
				}
			}
			
			return nil
		}
	}

	func getCurrencyRanges(for currency: Currency, key: DataKey, in range: TimeRange) -> TimeRanges?
	{
		return lock.read {
			return currencyDatas[currency.id]?[key]?.ranges.intersection(range)
		}
	}

	func putCurrencyDatas(_ datas: [CurrencyData], for currency: Currency, in range: TimeRange, with resolution: Resolution)
	{
		return lock.write {
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
}
