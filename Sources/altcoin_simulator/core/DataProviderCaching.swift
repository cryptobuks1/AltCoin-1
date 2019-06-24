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
	
	func getCurrencies () throws -> [Currency]?
	{
		if let data = try cache.getCurrencies()
		{
			return data
		}
		
		if let data = try source.getCurrencies()
		{
			try cache.putCurrencies(data)
			return data
		}
		
		return nil
	}

	func getCurrencyData (for currency: Currency, key: DataKey, in range: TimeRange, with resolution: Resolution) throws -> CurrencyData?
	{
		if let data = try cache.getCurrencyData(for: currency, key: key, in: range, with: resolution)
		{
			return data
		}
		
		if let datas = try source.getCurrencyDatas(for: currency, key: key, in: range, with: resolution)
		{
			try cache.putCurrencyDatas(datas, for: currency, in: range, with: resolution)
			return try cache.getCurrencyData(for: currency, key: key, in: range, with: resolution)
		}
		
		return nil
	}
	
	func getCurrencyDatas (for currency: Currency, key: DataKey, in range: TimeRange, with resolution: Resolution) throws -> [CurrencyData]?
	{
		if let datas = try cache.getCurrencyDatas(for: currency, key: key, in: range, with: resolution)
		{
			return datas
		}
		
		if let datas = try source.getCurrencyDatas(for: currency, key: key, in: range, with: resolution)
		{
			try cache.putCurrencyDatas(datas, for: currency, in: range, with: resolution)
			return datas
		}
		
		return nil
	}
}
