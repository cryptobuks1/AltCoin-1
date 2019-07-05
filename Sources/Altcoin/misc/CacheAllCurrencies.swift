//
//  CacheAllCurrencies.swift
//  altcoin-simulator
//
//  Created by Timothy Prepscius on 6/17/19.
//

import Foundation

func cacheAllCurrencies () throws
{
	let usecond : Double = 1000000
	let dataProvider = try DataProviderCaching (source: DataProviderWeb(), cache: DataProviderDiskJSON())

	if let currencies = try dataProvider.getCurrencies()
	{
//			let selected = ["bitcoin", "litecoin", "chainlink"]
//			currencies = currencies.filter { return selected.contains($0.id) }
		var currencies = currencies.currencies
		currencies.sort { return $0.rank < $1.rank }
		currencies = currencies.filter { return $0.rank < 4 }
	
		var sleepSeconds : Double = 15
		var requestSeconds = 0.5
		for currency in currencies
		{
			print("Currency[\(currency.id)]: \(currency.name)")
			let range : ClosedRange<Time> = 0 ... 5
			
			var currencyData : CurrencyData! = nil
			var requestFailedOnce = false
			
			repeat
			{
				currencyData = try dataProvider.getCurrencyData(for: currency, key: S.priceUSD, in: range, with: Resolution.hour)
				
				if currencyData == nil
				{
					if requestFailedOnce
					{
						print("currency data was nil, sleeping \(sleepSeconds) seconds")
						usleep(UInt32(sleepSeconds * usecond))
						sleepSeconds += 2
					}

					requestFailedOnce = true
				}
				
			} while currencyData == nil
			
			if requestFailedOnce
			{
				requestSeconds *= 1.1
				print("request, increased requestSeconds to \(requestSeconds)")
			}
			
			print(currencyData.values.averageTimeBetweenSamples)
			
			if currencyData.wasCached == false
			{
				usleep(UInt32(requestSeconds * usecond))
			}
		}
	}
}
