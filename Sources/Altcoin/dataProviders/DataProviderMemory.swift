//
//  MemoryDataProvider.swift
//  altcoin-simulator
//
//  Created by Timothy Prepscius on 6/16/19.
//

import Foundation

public class DataProviderMemory : DataCache
{
	let log = Log(clazz: DataProviderMemory.self)
	let logLock = LogNull(clazz: DataProviderMemory.self)
	let lock = ReadWriteLock()
	
	var currencies : CurrencySet? = nil
	typealias KeyedCurrencyData = [DataKey:CurrencyData]
	var currencyDatas = [CurrencyId:KeyedCurrencyData]()
	
	var locks = [CurrencyId:ReadWriteLock]()

	public init()
	{
	}

	public func lockFor(_ currency: Currency) -> ReadWriteLock
	{
		if let l = lock.read({ return locks[currency.id] })
		{
			logLock.print { "using lock for \(currency.id)" }
			return l
		}
		
		return lock.write {
			if let l = locks[currency.id]
			{
				return l
			}
			
			let lock = ReadWriteLock()
			locks[currency.id] = lock
			logLock.print { "creating lock for \(currency.id)" }
			return lock
		}
	}

	public func getCurrencies () -> CurrencySet?
	{
		return lock.read {
			return currencies
		}
	}
	
	public func putCurrencies (_ data: CurrencySet)
	{
		return lock.write {
			currencies = data
		}
	}

	public func getCurrencyData (for currency: Currency, key: DataKey, in range: TimeRange, with resolution: Resolution) -> CurrencyData?
	{
		return lockFor(currency).read {
			return lock.read { currencyDatas[currency.id]?[key]?.subset(range) }
		}
	}
	
	public func getCurrencyDatas (for currency: Currency, key: DataKey, in range: TimeRange, with resolution: Resolution) -> [CurrencyData]?
	{
		return lockFor(currency).read {
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

	public func getCurrencyRanges(for currency: Currency, key: DataKey, in range: TimeRange) -> TimeRanges?
	{
		return lockFor(currency).read {
			return lock.read { currencyDatas[currency.id]?[key]?.ranges.intersection(range) }
		}
	}

	public func putCurrencyDatas(_ datas: [CurrencyData], for currency: Currency, in range: TimeRange, with resolution: Resolution)
	{
		return lockFor(currency).write {
			var keyedCurrencyDatas = lock.read { self.currencyDatas[currency.id] ?? [DataKey:CurrencyData]() }
			
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
			
			lock.write {
				currencyDatas[currency.id] = keyedCurrencyDatas
			}
		}
	}
	
	public func writeTo(_ sink: DataSink) throws
	{
		return try lock.read {
			if let currencies = currencies
			{
				try sink.putCurrencies(currencies)
				log.print { "wrote currencies" }
				
				for currency in currencies.currencies
				{
					if let datas = currencyDatas[currency.id]
					{
						for (_, data) in datas
						{
							try sink.putCurrencyDatas([data], for: currency, in: data.enclosingTimeRange ?? TimeRange.Zero, with: .minute)
							log.print { "wrote \(currency.id) \(data.key)" }
						}
					}
				}
			}
		}
	}
}
