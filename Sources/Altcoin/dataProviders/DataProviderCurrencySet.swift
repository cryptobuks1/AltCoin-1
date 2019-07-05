//
//  DataProviderCurrencySet.swift
//  AltCoin
//
//  Created by Timothy Prepscius on 7/5/19.
//

import Foundation

public class DataProviderCurrencySet : DataProvider
{
	let currencyIds : Set<String>
	let provider: DataProvider
	
	public init(provider: DataProvider, currencyIds: [String])
	{
		self.provider = provider
		self.currencyIds = Set<String>(currencyIds)
	}

	public func getCurrencies() throws -> CurrencySet? {
		if let currencies = try provider.getCurrencies()?.currencies.filter { currencyIds.contains($0.id) }
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
