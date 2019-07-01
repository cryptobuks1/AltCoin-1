//
//  CachingDataProvider.swift
//  AltCoinSimulator
//
//  Created by Timothy Prepscius on 6/15/19.
//  Copyright © 2019 Timothy Prepscius. All rights reserved.
//

import Foundation

public class DataProviderCaching : DataProvider
{
	let log = LogNull(clazz: DataProviderCaching.self)
	
	var source: DataProvider
	var cache: DataCache
	
	public init (source: DataProvider, cache: DataCache)
	{
		self.source = source
		self.cache = cache
	}
	
	public func getCurrencies () throws -> CurrencySet?
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
	
	public func getCurrencyData (for currency: Currency, key: DataKey, in range: TimeRange, with resolution: Resolution) throws -> CurrencyData?
	{
		if let data = try cache.getCurrencyData(for: currency, key: key, in: range, with: resolution)
		{
			return data
		}
		
		let cachedTimeRanges = try cache.getCurrencyRanges(for: currency, key: key, in: range) ?? TimeRanges(ranges: [])
		let requiredRanges = range.excluding(cachedTimeRanges)
		log.print("range \(range) && cachedTimeRanges \(cachedTimeRanges) -> required ranges \(requiredRanges)")

		for requiredRange in requiredRanges.ranges
		{
			if let datas = try source.getCurrencyDatas(for: currency, key: key, in: requiredRange, with: resolution)
			{
				try cache.putCurrencyDatas(datas, for: currency, in: requiredRange, with: resolution)
			}
		}

		return try cache.getCurrencyData(for: currency, key: key, in: range, with: resolution)
	}
	
	public func getCurrencyRanges(for currency: Currency, key: DataKey, in range: TimeRange) throws -> TimeRanges?
	{
		return try source.getCurrencyRanges(for: currency, key: key, in: range)
	}
	
	public func getCurrencyDatas (for currency: Currency, key: DataKey, in range: TimeRange, with resolution: Resolution) throws -> [CurrencyData]?
	{
		if let datas = try cache.getCurrencyDatas(for: currency, key: key, in: range, with: resolution)
		{
			return datas
		}
		
		let cachedTimeRanges = try cache.getCurrencyRanges(for: currency, key: key, in: range) ?? TimeRanges(ranges: [])
		let requiredRanges = range.excluding(cachedTimeRanges)
		log.print("range \(range) && cachedTimeRanges \(cachedTimeRanges) -> required ranges \(requiredRanges)")

		for requiredRange in requiredRanges.ranges
		{
			if let datas = try source.getCurrencyDatas(for: currency, key: key, in: requiredRange, with: resolution)
			{
				try cache.putCurrencyDatas(datas, for: currency, in: requiredRange, with: resolution)
				return datas
			}
		}
		return nil
	}
}
