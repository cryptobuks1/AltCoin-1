//
//  DataProvider.swift
//  AltCoinSimulator
//
//  Created by Timothy Prepscius on 6/15/19.
//  Copyright © 2019 Timothy Prepscius. All rights reserved.
//

import Foundation
import sajson_swift

class DataProviderWeb : DataProvider
{
	let log = Log(clazz: DataProviderWeb.self)
	let logDetail = LogNull(clazz: DataProviderWeb.self)

	class S_ {
		static let
			folderName = "\(S.documents)/http",

			currenciesURLString = "https://s2.coinmarketcap.com/generated/search/quick_search.json",
			currencyDataRangeURLStringTemplate = "https://graphs2.coinmarketcap.com/currencies/{id}/",
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

	init ()
	{
	}
	
	
	func getCurrencyDataRange(for id: String) throws -> TimeRange?
	{
		let currencyDataRangeURLString = S_.currencyDataRangeURLStringTemplate
			.replacingOccurrences(of: S_.templateId, with: id)
		
		let url = URL(string: currencyDataRangeURLString)!
		let (json, error, _) = JSONURLTask.shared.dataTaskSyncRateLimitRetry(with: url, useCache: true)
		guard error == nil else { throw error! }

		if let json = json
		{
			if let values = parseHistoricalValues(json, S_.price_btc),
				let lowerBound = values.timeRange?.lowerBound
			{
				return TimeRange(uncheckedBounds:
					(lowerBound - TimeQuantities.Week,
					Date.distantFuture.timeIntervalSinceReferenceDate)
				)
			}
		}
		
		return nil
	}
	
	func getCurrencies () throws -> [Currency]?
	{
		let currenciesURL = URL(string: S_.currenciesURLString)!
		let (json, _, _) = JSONURLTask.shared.dataTaskSyncRateLimitRetry(with: currenciesURL, useCache: false)

		return json?.doc.withRootValueReader { coins_ -> [Currency]? in
			guard case .array(let coins) = coins_ else { return nil }

			let currencies = coins.enumerated().map_parallel({ arg -> Currency? in
				let (i, coin_) = arg
				guard case .object(let coin) = coin_ else { return nil }
				
				if
					let slug = coin[S_.slug]?.valueAsAny as? String,
					let name = coin[S_.name]?.valueAsAny as? String,
					let rank = Int(any: coin[S_.rank]?.valueAsAny),
					let tokens = coin[S_.tokens]?.valueAsAny as? [String],
					let timeRange = try? getCurrencyDataRange(for: slug)
				{
					return Currency(id: slug, name: name, rank: Int(rank), tokens: tokens, timeRange: timeRange)
				}
				else
				{
					print("failed to deserialize coin \(coin)")
				}

				
				return nil;
			})
			
			log.print("read web for currencies")
			return currencies.compactMap({ return $0 })
		}
	}


	func parseHistoricalValues(_ json: JSON?, _ index: String) -> HistoricalValues?
	{
		return json?.doc.withRootValueReader { keys_ -> HistoricalValues? in
			guard case .object(let keys) = keys_ else { return nil }
			guard case .array(let data) = keys[index]! else { return nil }

			var historicalValues = [HistoricalValue]()
		
			for datum in data
			{
				guard case .array(let v) = datum else { return nil }

				// why NSNumber and not Double?  Causes a memory leak!  Swift bug apparently.
				if let v0 = Double(any: v[0].valueAsAny), let v1 = Double(any: v[1].valueAsAny)
				{
					historicalValues.append(HistoricalValue(time: TimeEvents.toTimeInterval(v0), value: v1))
				}
				else
				{
					print("failed to deserialize historical value \(v)")
				}
			}
			
			let values = HistoricalValues(samples: historicalValues)
			logDetail.print("parsed historical values have median time span \(values.medianTimeBetweenSamples)")
			
			return values
		}
	}


	func getCurrencyDatas (for currency: Currency, key: DataKey, in range: TimeRange, with resolution: Resolution) throws -> [CurrencyData]?
	{
		if !currency.timeRange.extends(range)
		{
			return []
		}
	
		let roundedRange = range.round(1.0 * TimeQuantities.Week).clamped(to: 0 ... TimeEvents.safeNow )
		log.print("getCurrencyDatas_ range \(TimeEvents.toString(range)) -> roundedRange \(TimeEvents.toString(roundedRange))")
		
		let currencyDataURLString = S_.currencyDataURLStringTemplate
			.replacingOccurrences(of: S_.templateId, with: currency.id)
			.replacingOccurrences(of: S_.templateStartTime, with: "\(TimeEvents.toUnix(roundedRange.lowerBound))")
			.replacingOccurrences(of: S_.templateEndTime, with: "\(TimeEvents.toUnix(roundedRange.upperBound))")

		let currencyDataURL = URL(string: currencyDataURLString)!
		let (json, error, wasCached) = JSONURLTask.shared.dataTaskSyncRateLimitRetry(with: currencyDataURL, useCache: true)
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
							wasCached: wasCached
						)
					)
				}
			}

			log.print("read web for \(currency.id)")
			return datas;
		}
		
		return nil
	}
	
	func getCurrencyData (for currency: Currency, key: DataKey, in range: TimeRange, with resolution: Resolution) throws -> CurrencyData?
	{
		let datas = try getCurrencyDatas(for: currency, key: key, in: range, with: resolution)
		return datas?.filter { $0.key == key }.first
	}
}
