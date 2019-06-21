//
//  CachingDataProvider.swift
//  AltCoinSimulator
//
//  Created by Timothy Prepscius on 6/15/19.
//  Copyright © 2019 Timothy Prepscius. All rights reserved.
//

import Foundation

class DataProviderCaching : DataProvider
{
	var source: DataProvider
	var cache: DataCache
	
	init (source: DataProvider, cache: DataCache)
	{
		self.source = source
		self.cache = cache
	}
	
	func getCurrencies () -> [Currency]?
	{
		if let data = cache.getCurrencies()
		{
			return data
		}
		
		if let data = source.getCurrencies()
		{
			cache.putCurrencies(data)
			return data
		}
		
		return nil
	}

	func getCurrencyData (for currency: Currency, key: DataKey, in range: TimeRange, with resolution: Resolution) -> CurrencyData?
	{
		if let data = cache.getCurrencyData(for: currency, key: key, in: range, with: resolution)
		{
			return data
		}
		
		if let datas = source.getCurrencyDatas(for: currency, key: key, in: range, with: resolution)
		{
			cache.putCurrencyDatas(datas, for: currency, in: range, with: resolution)
			return cache.getCurrencyData(for: currency, key: key, in: range, with: resolution)
		}
		
		return nil
	}
	
	func getCurrencyDatas (for currency: Currency, key: DataKey, in range: TimeRange, with resolution: Resolution) -> [CurrencyData]?
	{
		if let datas = cache.getCurrencyDatas(for: currency, key: key, in: range, with: resolution)
		{
			return datas
		}
		
		if let datas = source.getCurrencyDatas(for: currency, key: key, in: range, with: resolution)
		{
			cache.putCurrencyDatas(datas, for: currency, in: range, with: resolution)
			return datas
		}
		
		return nil
	}
}
