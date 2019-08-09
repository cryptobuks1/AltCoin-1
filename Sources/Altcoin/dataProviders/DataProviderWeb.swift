//
//  DataProvider.swift
//  AltCoinSimulator
//
//  Created by Timothy Prepscius on 6/15/19.
//  Copyright © 2019 Timothy Prepscius. All rights reserved.
//

import Foundation
import sajson_swift

public class DataProviderWeb : DataProvider
{
	let log = LogNull(clazz: DataProviderWeb.self)
	let logDetail = LogNull(clazz: DataProviderWeb.self)

	public typealias SourceTimeGenerator = () -> TimeInterval
	let endSourceTime : SourceTimeGenerator
	let useCacheForCurrencies : Bool

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

	

	public init (useCacheForCurrencies: Bool = false, endSourceTime: @escaping SourceTimeGenerator = { TimeEvents.today12am } )
	{
		self.endSourceTime = endSourceTime
		self.useCacheForCurrencies = useCacheForCurrencies
	}
	
	
	public func getCurrencyDataRange(for id: String, useCache: Bool = true) throws -> TimeRange?
	{
		let currencyDataRangeURLString = S_.currencyDataRangeURLStringTemplate
			.replacingOccurrences(of: S_.templateId, with: id)
		
		let url = URL(string: currencyDataRangeURLString)!
		let (json, error, _) = JSONURLTask.shared.dataTaskSyncRateLimitRetry(with: url, useCache: useCache)
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
	
	public func getCurrencies () throws -> CurrencySet?
	{
		let currenciesURL = URL(string: S_.currenciesURLString)!
		let (json, _, _) = JSONURLTask.shared.dataTaskSyncRateLimitRetry(with: currenciesURL, useCache: useCacheForCurrencies)

		return json?.doc.withRootValueReader { coins_ -> CurrencySet? in
			guard case .array(let coins) = coins_ else { return nil }

			let currencies = coins.map_parallel({ coin_ -> Currency? in
				guard case .object(let coin) = coin_ else { return nil }
				
				if
					let slug = coin[S_.slug]?.valueAsAny as? String,
					let name = coin[S_.name]?.valueAsAny as? String,
					let rank = Int(any: coin[S_.rank]?.valueAsAny),
					let tokens = coin[S_.tokens]?.valueAsAny as? [String],
					let timeRange =
						try? getCurrencyDataRange(for: slug)
						// if the currency doesn't have any range, it may have been added but not populated, in this case
						// we try again
//							?? getCurrencyDataRange(for: slug, useCache: false)
				{
					return Currency(id: slug, name: name, rank: Int(rank), tokens: tokens, timeRange: timeRange)
				}
				else
				{
					log.error { "failed to deserialize coin \(coin.asDictionary())" }
				}

				
				return nil;
			})
			
			log.print { "read web for currencies" }
			
			return CurrencySet(currencies: currencies.compactMap({ $0 }))
		}
	}

	public func getCurrencyRanges(for currency: Currency, key: DataKey, in range: TimeRange) -> TimeRanges?
	{
		if let subrange = currency.timeRange.intersection(range)
		{
			return TimeRanges(ranges: [subrange])
		}
		
		return nil
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
					log.error { "failed to deserialize historical value \(v)" }
				}
			}
			
			let values = HistoricalValues(samples: historicalValues)
			logDetail.print { "parsed historical values have median time span \(values.medianTimeBetweenSamples)" }
			
			return values
		}
	}

	public func getCurrencyDatas (for currency: Currency, key: DataKey, in range: TimeRange, with resolution: Resolution) throws -> [CurrencyData]?
	{
		return try autoreleasepool {
			return try getCurrencyDatas_(for: currency, key: key, in: range, with: resolution)
		}
	}
	
	public func getCurrencyDatas_ (for currency: Currency, key: DataKey, in range: TimeRange, with resolution: Resolution) throws -> [CurrencyData]?
	{
		if !currency.timeRange.extends(range)
		{
			return []
		}
	
		let segmentLength = TimeQuantities.Week
		let rangeSegments = Int(floor(range.lowerBound / segmentLength)) ..< Int(ceil(range.upperBound / segmentLength))
		
		var datas = [DataKey:CurrencyData]()
		let lock = ReadWriteLock()

		rangeSegments.forEach_parallel {
			(rangeSegment) in
			let rangeSegmentTime = Double(rangeSegment) * segmentLength ... Double(rangeSegment + 1) * segmentLength
			let roundedRange = rangeSegmentTime.clamped(to: 0 ... endSourceTime() )
			log.print { "getCurrencyDatas_ \(currency.id) range \(TimeEvents.toString(rangeSegmentTime)) -> roundedRange \(TimeEvents.toString(roundedRange))" }
		
			let currencyDataURLString = S_.currencyDataURLStringTemplate
				.replacingOccurrences(of: S_.templateId, with: currency.id)
				.replacingOccurrences(of: S_.templateStartTime, with: "\(TimeEvents.toUnix(roundedRange.lowerBound))")
				.replacingOccurrences(of: S_.templateEndTime, with: "\(TimeEvents.toUnix(roundedRange.upperBound))")

			let currencyDataURL = URL(string: currencyDataURLString)!
			let (json, error, wasCached) = JSONURLTask.shared.dataTaskSyncRateLimitRetry(with: currencyDataURL, useCache: true)
			guard error == nil else { return }
		
			let parseTos = [
				(S.marketCapByAvailableSupply, S_.market_cap_by_available_supply),
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
						let existingData = lock.read {
							datas[parseTo.0] ??
								CurrencyData(
									key: parseTo.0,
									ranges: TimeRanges(ranges:[]),
									values: HistoricalValues(samples: []),
									wasCached: false
								)
						}
						
						let newData =
							CurrencyData(
								key: parseTo.0,
								ranges: TimeRanges(ranges:[roundedRange]),
								values: values,
								wasCached: wasCached
							)
						
						let mergedData = existingData.merge(newData)
						
						lock.write {
							datas[parseTo.0] = mergedData
						}
					}
				}
			}
		}
		
		log.print { "read web for \(currency.id)" }
		guard !datas.isEmpty else { return nil }
		return datas.map({ return $0.value })
		
	}
	
	public func getCurrencyData (for currency: Currency, key: DataKey, in range: TimeRange, with resolution: Resolution) throws -> CurrencyData?
	{
		let datas = try getCurrencyDatas(for: currency, key: key, in: range, with: resolution)
		return datas?.filter { $0.key == key }.first
	}
}
