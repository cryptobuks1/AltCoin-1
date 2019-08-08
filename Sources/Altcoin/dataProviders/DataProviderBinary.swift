//
//  DataProviderSQLite.swift
//  altcoin_simulator
//
//  Created by Timothy Prepscius on 6/24/19.
//

import Foundation
import SQLite
import NIO

typealias FileContents = ByteBuffer

// https://stackoverflow.com/questions/38023838/round-trip-swift-number-types-to-from-data
protocol DataConvertible {
    init?(data: Data)
    var data: Data { get }
}

extension DataConvertible where Self: ExpressibleByIntegerLiteral{

    init?(data: Data) {
        var value: Self = 0
        guard data.count == MemoryLayout.size(ofValue: value) else { return nil }
        _ = withUnsafeMutableBytes(of: &value, { data.copyBytes(to: $0)} )
        self = value
    }

    var data: Data {
        return withUnsafeBytes(of: self) { Data($0) }
    }
}

extension Int : DataConvertible { }
extension Float : DataConvertible { }
extension Double : DataConvertible { }

extension FileContents
{
	mutating func writeReal(_ v: Real)
	{
		_ = withUnsafeBytes(of: v) { writeBytes($0) }
	}
	
	mutating func writeTime(_ v: Time)
	{
		_ = withUnsafeBytes(of: v) { writeBytes($0) }
	}

	mutating func writeCount (_ v : Int)
	{
		writeInt(v)
	}
	
	mutating func writeInt (_ v: Int)
	{
		_ = withUnsafeBytes(of: v) { writeBytes($0) }
	}
	
	mutating func writeCountedString(_ v: String)
	{
		let c = v.lengthOfBytes(using: .utf8)
		writeCount(c)
		writeString(v)
	}

	mutating func writeCurrency (_ v: Currency)
	{
		writeCountedString(v.id)
		writeCountedString(v.name)
		writeInt(v.rank)
		writeCount(v.tokens.count)
		v.tokens.forEach { writeCountedString($0) }
		
		writeTimeRange(v.timeRange)
	}
	
	mutating func writeTimeRange(_ v: TimeRange)
	{
		writeTime(v.lowerBound)
		writeTime(v.upperBound)
	}
	
	mutating func writeCurrencySet (_ v: CurrencySet)
	{
		writeCount(v.currencies.count)
		for i in v.currencies
		{
			writeCurrency(i)
		}
	}
	
	mutating func writeHistoricalValue (_ v: HistoricalValue)
	{
		writeTime(v.time)
		writeReal(v.value)
	}
	
	mutating func writeHistoricalValues (_ v: HistoricalValues)
	{
		writeCount(v.samples.count)
		for i in v.samples
		{
			writeHistoricalValue(i)
		}
	}

	mutating func writeTimeRanges (_ v : TimeRanges)
	{
		writeCount(v.ranges.count)
		for i in v.ranges {
			writeTimeRange(i)
		}
	}
	
	mutating func writeDataKey(_ v : DataKey)
	{
		writeCountedString(v)
	}
	
	mutating func writeCurrencyData (_ v: CurrencyData)
	{
		writeDataKey(v.key)
		writeTimeRanges(v.ranges)
		writeHistoricalValues(v.values)
	}
}

extension FileContents
{
	mutating func readReal() -> Real?
	{
		let t = Real()
		return readBytes(length: MemoryLayout.size(ofValue: t))?.withUnsafeBytes {
			let data = Data($0)
			return Real(data: data)
		}
	}
	
	mutating func readTime() -> Time?
	{
		let t = Time()
		return readBytes(length: MemoryLayout.size(ofValue: t))?.withUnsafeBytes {
			let data = Data($0)
			return Time(data: data)
		}
	}

	mutating func readInt() -> Int?
	{
		let t = Int()
		return readBytes(length: MemoryLayout.size(ofValue: t))?.withUnsafeBytes {
			let data = Data($0)
			return Int(data: data)
		}
	}

	mutating func readCount () -> Int?
	{
		return readInt()
	}

	mutating func readCountedString () -> String?
	{
		guard let c = readInt() else { return nil }
		return readString(length: c)
	}

	mutating func readCurrency () -> Currency?
	{
		guard let id = readCountedString() else { return nil }
		guard let name = readCountedString() else { return nil }
		guard let rank = readInt() else { return nil }
		guard let tokenCount = readCount() else { return nil }
		
		var tokens = [String]()
		for _ in 0 ..< tokenCount
		{
			guard let token = readCountedString() else { return nil }
			tokens.append(token)
		}

		guard let timeRange = readTimeRange() else { return nil }
		
		return Currency(id: id, name: name, rank: rank, tokens: tokens, timeRange: timeRange)
	}
	
	mutating func readTimeRange() -> TimeRange?
	{
		guard let lowerBound = readTime() else { return nil }
		guard let upperBound = readTime() else { return nil }
		
		return TimeRange(uncheckedBounds: (lowerBound, upperBound) )
	}
	
	mutating func readCurrencySet () -> CurrencySet?
	{
		guard let currenciesCount = readInt() else { return nil }
		var currencies = [Currency]()
		for _ in 0 ..< currenciesCount
		{
			guard let currency = readCurrency() else { return nil }
			currencies.append(currency)
		}
		
		return CurrencySet(currencies: currencies)
	}
	
	mutating func readHistoricalValue () -> HistoricalValue?
	{
		guard let time = readTime() else { return nil }
		guard let value = readReal() else { return nil }
		return HistoricalValue(time: time, value: value)
	}
	
	mutating func readHistoricalValues () -> HistoricalValues?
	{
		guard let samplesCount = readCount() else { return nil }
		var samples = [HistoricalValue]()
		for _ in 0 ..< samplesCount
		{
			guard let sample = readHistoricalValue() else { return nil }
			samples.append(sample)
		}

		return HistoricalValues(samples: samples)
	}

	mutating func readTimeRanges () -> TimeRanges?
	{
		guard let rangesCount = readCount() else { return nil }
		var ranges = [TimeRange]()
		for _ in 0 ..< rangesCount
		{
			guard let range = readTimeRange() else { return nil }
			ranges.append(range)
		}
		return TimeRanges(ranges: ranges)
	}
	
	mutating func readDataKey() -> DataKey?
	{
		return readCountedString()
	}
	
	mutating func readCurrencyData () -> CurrencyData?
	{
		guard let key = readDataKey() else { return nil }
		guard let ranges = readTimeRanges() else { return nil }
		guard let historicalValues = readHistoricalValues() else { return nil }
		
		return CurrencyData(key: key, ranges: ranges, values: historicalValues, wasCached: true)
	}
	
	static func defaultEmptyBuffer () -> ByteBuffer
	{
		let a = ByteBufferAllocator()
		return a.buffer(capacity: 0)
	}
}

extension CurrencySet
{
	public func toByteBuffer() -> ByteBuffer
	{
		var b = ByteBuffer.defaultEmptyBuffer()
		b.writeCurrencySet(self)
		return b
	}
}

extension CurrencyData
{
	public func toByteBuffer() -> ByteBuffer
	{
		var b = ByteBuffer.defaultEmptyBuffer()
		b.writeCurrencyData(self)
		return b
	}
}


public class DataProviderBinary: DataCache
{
	let log = Log(clazz: DataProviderDiskSQLite.self)
	var db: Connection! = nil
	let lock = ReadWriteLock()
	
	class S_ {
		static let
			folderName = "\(S.documents)/binary",
			currenciesFileName = "currencies.binary"
	}
	
	public init ()
	{
	}
	
	public func getByteBufferFor(fileName: String) -> ByteBuffer?
	{
		return autoreleasepool {
			guard let dataFolder = getDataFolderUrl(fileName: fileName) else { return nil }

			let data = try? Data(contentsOf: dataFolder.appendingPathComponent(fileName), options: .mappedRead)
			return data?.withUnsafeBytes {
				let bba = ByteBufferAllocator()
				var buffer = bba.buffer(capacity: 0);
				buffer.writeBytes($0)
				return buffer
			}
		}
	}

	public func putByteBufferFor(_ buffer: ByteBuffer, fileName: String)
	{
		buffer.withUnsafeReadableBytes {
			let data = Data($0)
			if let dataFolder = getDataFolderUrl(fileName: fileName)
			{
				try? FileManager.default.createDirectory(at: dataFolder, withIntermediateDirectories: true, attributes: nil)
				try? data.write(to: dataFolder.appendingPathComponent(fileName), options: .atomicWrite)
			}
		}
	}

	func getDataFolderUrl (fileName: String) -> URL?
	{
		if var documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
		{
			documentsURL.appendPathComponent(S_.folderName, isDirectory: true)
			documentsURL.appendPathComponent(String(fileName.prefix(1)), isDirectory: true)
			return documentsURL
		}
		
		return nil
	}


	public func getCurrencies () throws -> CurrencySet?
	{
		return lock.read {
			var b = getByteBufferFor(fileName: S_.currenciesFileName)
			return b?.readCurrencySet()
		}
	}

	public func putCurrencies (_ data: CurrencySet) throws
	{
		return try lock.write {
			putByteBufferFor(data.toByteBuffer(), fileName: S_.currenciesFileName)
		}
	}

	public func getCurrencyData (for currency: Currency, key: DataKey, in range: TimeRange, with resolution: Resolution) throws -> CurrencyData?
	{
		return try lock.read {
			return try getCurrencyData_ (for: currency, key: key, in: range, with: resolution)
		}
	}
	
	public func getCurrencyFileName (for currency: Currency, key: DataKey) -> String
	{
		return "\(currency.id).\(key)"
	}
	
	public func getCurrencyData_ (for currency: Currency, key: DataKey, in range: TimeRange, with resolution: Resolution) throws -> CurrencyData?
	{
		var b = getByteBufferFor(fileName: getCurrencyFileName(for: currency, key: key))
		return b?.readCurrencyData()
	}
	
	public func getCurrencyRanges(for currency: Currency, key: DataKey, in range: TimeRange) throws -> TimeRanges?
	{
		return nil
	}
	
	public func getCurrencyDatas (for currency: Currency, key: DataKey, in range: TimeRange, with resolution: Resolution) throws -> [CurrencyData]?
	{
		if var currencyData = try getCurrencyData(for: currency, key: key, in: range, with: resolution)
		{
			currencyData.wasCached = true
			return [currencyData]
		}
		
		return nil
	}
	
	public func putCurrencyDatas(_ datas: [CurrencyData], for currency: Currency, in range: TimeRange, with resolution: Resolution) throws
	{
		return lock.write {
			for data in datas {
				putByteBufferFor(data.toByteBuffer(), fileName: getCurrencyFileName(for: currency, key: data.key))
			}
		}
	}
}
