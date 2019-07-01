//
//  DataProviderSQLite.swift
//  altcoin_simulator
//
//  Created by Timothy Prepscius on 6/24/19.
//

import Foundation
import SQLite


public class DataProviderDiskSQLite: DataCache
{
	let log = Log(clazz: DataProviderDiskSQLite.self)
	var db: Connection! = nil
	let lock = ReadWriteLock()
	
	class S_ {
		static let
			folderName = "\(S.documents)/sqlite",
			currenciesFileName = "currencies.sqlite3"
	}
	
	func tableExists (_ db: Connection, _ table: Table) -> Bool
	{
		do
		{
			_ = try db.scalar(table.exists)
			return true
		}
		catch
		{
			return false
		}
	}
	
	class Currencies_ {
		static let table = Table("currencies")
		static let id = Expression<String>("id")
		static let name = Expression<String>("name")
		static let rank = Expression<Int>("rank")
		static let tokens = Expression<String>("tokens")
		static let timeRangeL = Expression<Double>("timeRangeL")
		static let timeRangeU = Expression<Double>("timeRangeU")
	}

//	class CurrencyDatas_ {
//		static let table = Table("currencyDatas")
//		static let id = Expression<String>("_id")
//		static let key = Expression<String>("key")
//		static let cacheTime = Expression<Time>("cacheTime")
//	}

	class TimeRanges_ {
//		static let table = Table("timeRanges")
//		static let id = Expression<String>("_id")
//		static let key = Expression<String>("key")

		static func table(id: String, key: String) -> Table { return Table("\(id)_\(key)_timeRanges") }
		static let lowerBound = Expression<Time>("lowerBound")
		static let upperBound = Expression<Real>("upperBound")
	}

	class HistoricalValues_ {
//		static let table = Table("historicalValues")
//		static let id = Expression<String>("_id")
//		static let key = Expression<String>("key")

		static func table(id: String, key: String) -> Table { return Table("\(id)_\(key)_historicalValues") }
		static let time = Expression<Time>("time")
		static let value = Expression<Real>("value")
	}


	public init() throws
	{
		if let dataFolder = getDataFolderUrl()
		{
			try? FileManager.default.createDirectory(at: dataFolder, withIntermediateDirectories: true, attributes: nil)
			db = try Connection(dataFolder.appendingPathComponent(S_.currenciesFileName).relativePath)
			
			let _ = try? db.run(Currencies_.table.create { t in
				t.column(Currencies_.id, primaryKey: true)
				t.column(Currencies_.name)
				t.column(Currencies_.rank)
				t.column(Currencies_.tokens)
				t.column(Currencies_.timeRangeL)
				t.column(Currencies_.timeRangeU)
			})
			
//			let _ = try? db.run(CurrencyDatas_.table.create { t in
//				t.column(CurrencyDatas_.id, primaryKey: true)
//				t.column(CurrencyDatas_.key)
//				t.column(CurrencyDatas_.cacheTime)
//			})
			

		}
	}

	func getDataFolderUrl () -> URL?
	{
		if var documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
		{
			documentsURL.appendPathComponent(S_.folderName)
			return documentsURL
		}
		
		return nil
	}
	

	public func getCurrencies () throws -> CurrencySet?
	{
		return try lock.read {
			let result = try db.prepare(Currencies_.table).map {
				return Currency (
					id: $0[Currencies_.id],
					name: $0[Currencies_.name],
					rank: $0[Currencies_.rank],
					tokens: $0[Currencies_.tokens].split(separator: ",").map { return String($0) },
					timeRange: TimeRange(uncheckedBounds: ($0[Currencies_.timeRangeL],$0[Currencies_.timeRangeU]))
				)
			}
			
			return result.isEmpty ? nil : CurrencySet(currencies: result)
		}
	}

	public func putCurrencies (_ data: CurrencySet) throws
	{
		return try lock.write {
			// should be upsert, not delete & insert
			try db.run(
				Currencies_.table.delete()
			)
		
			try db.transaction {
				try data.currencies.forEach {
					try db.run(Currencies_.table.insert(
						Currencies_.id <- $0.id,
						Currencies_.name <- $0.name,
						Currencies_.rank <- $0.rank,
						Currencies_.tokens <- $0.tokens.joined(separator: ","),
						Currencies_.timeRangeL <- $0.timeRange.lowerBound,
						Currencies_.timeRangeU <- $0.timeRange.upperBound
					));
				}
			}
		}
	}

	public func getCurrencyData (for currency: Currency, key: DataKey, in range: TimeRange, with resolution: Resolution) throws -> CurrencyData?
	{
		return try lock.read {
			let historicalValuesTable = HistoricalValues_.table(id: currency.id, key: key)
			guard tableExists(db, historicalValuesTable) else { return nil }

			let timeRangesTable = TimeRanges_.table(id: currency.id, key: key)
			guard tableExists(db, timeRangesTable) else { return nil }

			let values = try db.prepare(
					historicalValuesTable
	//					.filter(HistoricalValues_.id == currency.id)
	//					.filter(HistoricalValues_.key == key)
					.filter(HistoricalValues_.time >= range.lowerBound)
					.filter(HistoricalValues_.time <= range.upperBound)
			).map {
				return HistoricalValue (time: $0[HistoricalValues_.time], value: $0[HistoricalValues_.value])
			}

			let ranges = try db.prepare (
				timeRangesTable
	//				.filter(TimeRanges_.id == currency.id)
	//				.filter(TimeRanges_.key == key)
				.filter(TimeRanges_.lowerBound <= range.upperBound)
				.filter(TimeRanges_.upperBound >= range.lowerBound)
			).map {
				return TimeRange (uncheckedBounds: ($0[TimeRanges_.lowerBound], $0[TimeRanges_.upperBound]))
			}

			let currencyData = CurrencyData(
				key: key,
				ranges: TimeRanges(ranges: ranges),
				values: HistoricalValues(samples: values),
				wasCached: true
			)
			
			return currencyData.subset(range)
		}
	}
	
	public func getCurrencyRanges(for currency: Currency, key: DataKey, in range: TimeRange) throws -> TimeRanges?
	{
		return try lock.read {
			let timeRangesTable = TimeRanges_.table(id: currency.id, key: key)
			guard tableExists(db, timeRangesTable) else { return nil }
		
			let ranges = try db.prepare (
				timeRangesTable
	//			.filter(TimeRanges_.id == currency.id)
	//			.filter(TimeRanges_.key == key)
				.filter(TimeRanges_.lowerBound <= range.upperBound)
				.filter(TimeRanges_.upperBound >= range.lowerBound)
			).map {
				return TimeRange (uncheckedBounds: ($0[TimeRanges_.lowerBound], $0[TimeRanges_.upperBound]))
			}
			
			return TimeRanges(ranges: ranges).intersection(range)
		}
	}
	
	public func getCurrencyDatas (for currency: Currency, key: DataKey, in range: TimeRange, with resolution: Resolution) throws -> [CurrencyData]?
	{
		return try lock.read {
			if var currencyData = try getCurrencyData(for: currency, key: key, in: range, with: resolution)
			{
				currencyData.wasCached = true
				if currencyData.ranges.contains(range)
				{
					return [currencyData]
				}
			}
			
			return nil
		}
	}
	
	
	
	public func putCurrencyDatas(_ datas: [CurrencyData], for currency: Currency, in range: TimeRange, with resolution: Resolution) throws
	{
		return try lock.write {

			for data in datas
			{
				log.print("putCurrencyDatas data \(data.key) timeRange \(TimeEvents.toString(range))")
				
				let currencyData = try getCurrencyData(for: currency, key: data.key, in: range, with: resolution)
				let merged = currencyData?.merge(data) ?? data
				let mergedSampleRange = merged.values.timeRange ?? TimeRange(uncheckedBounds: (0,0))
				log.print("range \(range) -> mergedSampleRange \(mergedSampleRange)")
				
				let historicalValuesTable = HistoricalValues_.table(id: currency.id, key: data.key)
				if !tableExists(db, historicalValuesTable) {
					_ = try db.run(
						historicalValuesTable
							.create { t in
	//							t.column(HistoricalValues_.id, primaryKey: true)
	//							t.column(HistoricalValues_.key)
								t.column(HistoricalValues_.time)
								t.column(HistoricalValues_.value)
							}
						)
				}

				let timeRangesTable = TimeRanges_.table(id: currency.id, key: data.key)
				if !tableExists(db, timeRangesTable) {
					_ = try db.run(
						timeRangesTable
							.create { t in
	//							t.column(TimeRanges_.id, primaryKey: true)
	//							t.column(TimeRanges_.key)
								t.column(TimeRanges_.lowerBound)
								t.column(TimeRanges_.upperBound)
							}
						)
				}

				try db.run(
					historicalValuesTable
	//					.filter(HistoricalValues_.id == currency.id)
	//					.filter(HistoricalValues_.key == data.key)
						.filter(HistoricalValues_.time >= mergedSampleRange.lowerBound)
						.filter(HistoricalValues_.time <= mergedSampleRange.upperBound)
						.delete()
					)
				
				try db.transaction {
					for value in data.values.samples
					{
						try db.run(historicalValuesTable.insert(
	//						HistoricalValues_.id <- currency.id,
	//						HistoricalValues_.key <- data.key,
							HistoricalValues_.time <- value.time,
							HistoricalValues_.value <- value.value
						))
					}
				}

				try db.run(
					timeRangesTable
	//					.filter(TimeRanges_.id == currency.id)
	//					.filter(TimeRanges_.key == data.key)
						.filter(TimeRanges_.lowerBound >= range.lowerBound)
						.filter(TimeRanges_.upperBound <= range.upperBound)
						.delete()
					)

				
				try db.transaction {
					for range in merged.ranges.ranges
					{
						try db.run(timeRangesTable.insert(
	//						TimeRanges_.id <- currency.id,
	//						TimeRanges_.key <- data.key,
							TimeRanges_.lowerBound <- range.lowerBound,
							TimeRanges_.upperBound <- range.upperBound
						))
					}
				}
			}
		}
	}
}
