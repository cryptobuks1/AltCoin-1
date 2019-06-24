//
//  DataProviderSQLite.swift
//  altcoin_simulator
//
//  Created by Timothy Prepscius on 6/24/19.
//

import Foundation
import SQLite


class DataProviderDiskSQLite: DataCache
{
	let log = Log(clazz: DataProviderDiskJSON.self)
	var db: Connection! = nil
	
	class S {
		static let
			folderName = "altcoin-simulator/sqlite",
			currenciesFileName = "currencies.sqlite3"
	}

	class Currencies_ {
		static let table = Table("currencies")
		static let id = Expression<String>("id")
		static let name = Expression<String>("name")
		static let rank = Expression<Int>("rank")
		static let tokens = Expression<String>("tokens")
	}
	
	class CurrencyDatas_ {
		static let table = Table("currencyDatas")
		static let id = Expression<String>("_id")
		static let key = Expression<String>("key")
		static let cacheTime = Expression<Time>("cacheTime")
	}

	class TimeRanges_ {
		static let table = Table("timeRanges")
		static let id = Expression<String>("_id")
		static let key = Expression<String>("key")
		static let lowerBound = Expression<Time>("lowerBound")
		static let upperBound = Expression<Real>("upperBound")
	}

	class HistoricalValues_ {
		static let table = Table("historicalValues")
		static let id = Expression<String>("_id")
		static let key = Expression<String>("key")
		static let time = Expression<Time>("time")
		static let value = Expression<Real>("value")
	}


	init() throws
	{
		if let dataFolder = getDataFolderUrl()
		{
			try? FileManager.default.createDirectory(at: dataFolder, withIntermediateDirectories: true, attributes: nil)
			db = try Connection(dataFolder.appendingPathComponent(S.currenciesFileName).relativePath)
			
			let _ = try? db.run(Currencies_.table.create { t in
				t.column(Currencies_.id, primaryKey: true)
				t.column(Currencies_.name)
				t.column(Currencies_.rank)
				t.column(Currencies_.tokens)
			})
			
			let _ = try? db.run(CurrencyDatas_.table.create { t in
				t.column(CurrencyDatas_.id, primaryKey: true)
				t.column(CurrencyDatas_.key)
				t.column(CurrencyDatas_.cacheTime)
			})
			
			let _ = try? db.run(TimeRanges_.table.create { t in
				t.column(TimeRanges_.id, primaryKey: true)
				t.column(TimeRanges_.key)
				t.column(TimeRanges_.lowerBound)
				t.column(TimeRanges_.upperBound)
			})

			let _ = try? db.run(HistoricalValues_.table.create { t in
				t.column(HistoricalValues_.id, primaryKey: true)
				t.column(HistoricalValues_.key)
				t.column(HistoricalValues_.time)
				t.column(HistoricalValues_.value)
			})
		}
	}

	func getDataFolderUrl () -> URL?
	{
		if var documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
		{
			documentsURL.appendPathComponent(S.folderName)
			return documentsURL
		}
		
		return nil
	}
	

	func getCurrencies () -> [Currency]?
	{
		let result = try? db.prepare(Currencies_.table).map {
			return Currency (id: $0[Currencies_.id], name: $0[Currencies_.name], rank: $0[Currencies_.rank], tokens: $0[Currencies_.tokens].split(separator: ",").map { return String($0) })
		}
		
		return result;
	}

	func putCurrencies (_ data: [Currency])
	{
		try? data.forEach {
			try db.run(Currencies_.table.insert(
				Currencies_.id <- $0.id,
				Currencies_.name <- $0.name,
				Currencies_.rank <- $0.rank,
				Currencies_.tokens <- $0.tokens.joined(separator: ",")
			));
		}
	}

	func getCurrencyData (for currency: Currency, key: DataKey, in range: TimeRange, with resolution: Resolution) -> CurrencyData?
	{
		if let data = try? db.prepare(CurrencyDatas_.table.filter(CurrencyDatas_.id == currency.id)).first(where: { (_) in return true })
		{
			let values = try? db.prepare(
				HistoricalValues_.table
					.filter(HistoricalValues_.id == currency.id)
					.filter(HistoricalValues_.key == key)
			).map {
				return HistoricalValue (time: $0[HistoricalValues_.time], value: $0[HistoricalValues_.value])
			}

			let ranges = try? db.prepare (
				TimeRanges_.table
				.filter(TimeRanges_.id == currency.id)
				.filter(TimeRanges_.key == key)
			).map {
				return TimeRange (uncheckedBounds: ($0[TimeRanges_.lowerBound], $0[TimeRanges_.upperBound]))
			}

			if let values = values, let ranges = ranges
			{
				let currencyData = CurrencyData(
					key: key,
					ranges: TimeRanges(ranges: ranges),
					values: HistoricalValues(samples: values),
					cacheTime: data[CurrencyDatas_.cacheTime],
					wasCached: true
				)
				
				return currencyData.subset(range)
			}
		}
		
		return nil
	}
	
	func getCurrencyDatas (for currency: Currency, key: DataKey, in range: TimeRange, with resolution: Resolution) -> [CurrencyData]?
	{
		if var currencyData = getCurrencyData(for: currency, key: key, in: range, with: resolution)
		{
			currencyData.wasCached = true
			if currencyData.ranges.contains(range)
			{
				return [currencyData]
			}
		}
		
		return nil
	}
	
	func putCurrencyDatas(_ datas: [CurrencyData], for currency: Currency, in range: TimeRange, with resolution: Resolution)
	{
		for data in datas
		{
			print("putCurrencyDatas data \(data.key) timeRange \(TimeEvents.toString(data.ranges.ranges.first!))")
			
			if let currencyData = getCurrencyData(for: currency, key: data.key, in: range, with: resolution)
			{
				let merged = currencyData.merge(data)
//				write(fileName: fileName, data: merged)
			}
			else
			{
//				write(fileName: fileName, data: data)
			}
		}
	}
}
