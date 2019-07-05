//
//  DataProviderCurrencySet.swift
//  AltCoin
//
//  Created by Timothy Prepscius on 7/5/19.
//

import Foundation

public class DataProviderCurrencyFilter : DataProvider
{
	public typealias Filter = (_ c : Currency) -> Bool
	let filter : Filter
	let provider: DataProvider
	
	public init(provider: DataProvider, filter: @escaping Filter)
	{
		self.provider = provider
		self.filter = filter
	}

	public func getCurrencies() throws -> CurrencySet? {
		if let currencies = try provider.getCurrencies()?.currencies.filter { filter($0) }
		{
			return CurrencySet(currencies: currencies)
		}
		
		return nil
	}
	
	public func getCurrencyRanges(for currency: Currency, key: DataKey, in range: TimeRange) throws -> TimeRanges? {
		return try provider.getCurrencyRanges(for: currency, key: key, in: range)
	}

	public func getCurrencyDatas(for currency: Currency, key: DataKey, in range: TimeRange, with resolution: Resolution) throws -> [CurrencyData]? {
		return try provider.getCurrencyDatas(for: currency, key: key, in: range, with: resolution)
	}
	
	public func getCurrencyData(for currency: Currency, key: DataKey, in range: TimeRange, with resolution: Resolution) throws -> CurrencyData? {
		return try provider.getCurrencyData(for: currency, key: key, in: range, with: resolution)
	}
}
