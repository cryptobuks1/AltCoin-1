//
//  DataProvider.swift
//  AltCoinSimulator
//
//  Created by Timothy Prepscius on 6/15/19.
//  Copyright © 2019 Timothy Prepscius. All rights reserved.
//

import Foundation

class DataProviderWeb : DataProvider
{
	let log = Log(clazz: DataProviderWeb.self)

	class S_ {
		static let
			currenciesURLString = "https://s2.coinmarketcap.com/generated/search/quick_search.json",
			currencyDataURLStringTemplate = "https://graphs2.coinmarketcap.com/currencies/{id}/{startTime}/{endTime}/",
			templateId = "{id}",
			templateStartTime = "{startTime}",
			templateEndTime = "{endTime}",

			name = "name",
			slug = "slug",
			rank = "rank",
			tokens = "tokens",
			price_btc = "price_btc",
			price_usd = "price_usd",
			volume_usd = "volume_usd",
			market_cap_by_available_supply = "market_cap_by_available_supply"
	}

	func getCurrencies () -> [Currency]?
	{
		let currenciesURL = URL(string: S_.currenciesURLString)!
		let (json, error) = JSONURLTask.shared.dataTaskSync(with: currenciesURL)

		if let coins = json as? [Any]
		{
			var currencies = [Currency]()

			for coin in coins
			{
				if let coin = coin as? [String:Any]
				{
					if
						let slug = coin[S_.slug] as? String,
						let name = coin[S_.name] as? String,
						let rank = coin[S_.rank] as? Int,
						let tokens = coin[S_.tokens] as? [String]
					{
						currencies.append(Currency(id: slug, name: name, rank: rank, tokens: tokens))
					}
				}
			}
			
//			let selected = ["bitcoin", "litecoin", "chainlink"]
//			currencies = currencies.filter { return selected.contains($0.id) }
			currencies.sort { return $0.rank < $1.rank }
			currencies = currencies.filter { return $0.rank < 4 }
			
			log.print("read web for currencies")
			return currencies
		}
		
		return nil
	}

	func parseHistoricalValues(_ json: Any?, _ index: String) -> HistoricalValues?
	{
		if let object = json as? [String:Any], let data = object[index] as? [Any]
		{
			var historicalValues = [HistoricalValue]()
		
			for datum in data
			{
				if let datum = datum as? [Any]
				{
					if let v0 = datum[0] as? Double, let v1 = datum[1] as? Double
					{
						historicalValues.append(HistoricalValue(time: TimeEvents.toTimeInterval(v0), value: v1))
					}
				}
			}
			
			let values = HistoricalValues(samples: historicalValues)
			log.print("parsed historical values have median time span \(values.medianTimeBetweenSamples)")

			return values
		}
		
		return nil
	}

	func getCurrencyDatas_ (for currency: Currency, key: DataKey, in range: TimeRange, with resolution: Resolution) throws -> [CurrencyData]?
	{
		let roundedRange = range.round(1.0 * TimeQuantities.Week).clamped(to: 0 ... TimeEvents.safeNow )
		log.print("getCurrencyDatas_ range \(TimeEvents.toString(range)) -> roundedRange \(TimeEvents.toString(roundedRange))")
		
		let currencyDataURLString = S_.currencyDataURLStringTemplate
			.replacingOccurrences(of: S_.templateId, with: currency.id)
			.replacingOccurrences(of: S_.templateStartTime, with: "\(TimeEvents.toUnix(roundedRange.lowerBound))")
			.replacingOccurrences(of: S_.templateEndTime, with: "\(TimeEvents.toUnix(roundedRange.upperBound))")
		
		print(currencyDataURLString)
		
		let currencyDataURL = URL(string: currencyDataURLString)!
		let (json, error) = JSONURLTask.shared.dataTaskSync(with: currencyDataURL)
		guard error == nil else { throw error! }
		
		var datas = [CurrencyData]()
		let cacheTime = Date().timeIntervalSinceReferenceDate
		
		let parseTos = [
			(S.markeyCapByAvailableSupply, S_.market_cap_by_available_supply),
			(S.priceBTC, S_.price_btc),
			(S.priceUSD, S_.price_usd),
			(S.volumeUSD, S_.volume_usd)
		]
		
		if let json = json
		{
			for parseTo in parseTos
			{
				if let values = parseHistoricalValues(json, parseTo.1)
				{
					datas.append(
						CurrencyData(
							key: parseTo.0,
							ranges: TimeRanges(ranges:[roundedRange]),
							values: values,
							cacheTime: cacheTime,
							wasCached: false
						)
					)
				}
			}

			log.print("read web for \(currency.id)")
			return datas;
		}
		
		return nil
	}
	
	var sleepSeconds = 15.0
	var requestDelaySeconds = 0.5
	var lastRequestSecond : TimeInterval = 0
	
	func sleep(_ delay : Double)
	{
		let usecond : Double = 1000000
		usleep(UInt32(delay * usecond))
	}

	func getCurrencyDatas (for currency: Currency, key: DataKey, in range: TimeRange, with resolution: Resolution) -> [CurrencyData]?
	{
		var alreadySlept = false
		var data : [CurrencyData]! = nil
		
		repeat
		{
			do
			{
				let requestTimeSecond = Date().timeIntervalSinceReferenceDate
				let differenceSeconds = requestTimeSecond - lastRequestSecond
				let delay = requestDelaySeconds - differenceSeconds
				if delay > 0
				{
					sleep(delay)
				}
				
				lastRequestSecond = requestTimeSecond
				data = try getCurrencyDatas_(for: currency, key: key, in: range, with: resolution)
			}
			catch
			{
				print(error)
				print("sleeping for \(sleepSeconds)")
				sleep(sleepSeconds)

				if alreadySlept
				{
					sleepSeconds *= 1.1
				}
				
				if !alreadySlept
				{
					requestDelaySeconds *= 1.02
					print("increased sleepSeconds to \(sleepSeconds) requestDelaySeconds \(requestDelaySeconds)")
				}
				
				alreadySlept = true
			}
		} while data == nil
		
		return data
	}
	
	func getCurrencyData (for currency: Currency, key: DataKey, in range: TimeRange, with resolution: Resolution) -> CurrencyData?
	{
		let datas = getCurrencyDatas(for: currency, key: key, in: range, with: resolution)

		return datas?.filter { $0.key == key }.first
	}
}
