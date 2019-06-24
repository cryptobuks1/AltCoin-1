//
//  DiskDataProvider.swift
//  AltCoinSimulator
//
//  Created by Timothy Prepscius on 6/15/19.
//  Copyright © 2019 Timothy Prepscius. All rights reserved.
//

import Foundation

class DataProviderDiskJSON : DataCache
{
	let log = Log(clazz: DataProviderDiskJSON.self)
	
	class S {
		static let
			folderName = "altcoin-simulator/json",
			currenciesFileName = "currencies.json",
			currencyFileNameTemplate = "currency-{id}.{key}.json",
			templateId = "{id}",
			templateKey = "{key}"
		
	}

	init() throws
	{
		if let dataFolder = getDataFolderUrl()
		{
			try? FileManager.default.createDirectory(at: dataFolder, withIntermediateDirectories: true, attributes: nil)
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

	func getFileUrlFor(_ fileName: String) -> URL?
	{
		if var dataFolderUrl = getDataFolderUrl()
		{
			dataFolderUrl.appendPathComponent(fileName)
			return dataFolderUrl
		}
		
		return nil
	}
	
	func read<T> (fileName: String, type: T.Type) -> T? where T: Decodable
	{
		if let fileURL = getFileUrlFor(fileName)
		{
			do
			{
				return try autoreleasepool { () -> T in
					let data = try Data(contentsOf: fileURL)
					let decoder = JSONDecoder()
					let decoded = try decoder.decode(type, from: data)
					
					log.print("read cache for \(fileName)")
					return decoded
				}
			}
			catch
			{
				// file probably didn't exist, we skip error for now
			}
		}
		
		return nil
	}

	func write<T> (fileName: String, data: T) where T: Encodable
	{
		if let fileURL = getFileUrlFor(fileName)
		{
			do
			{
				try autoreleasepool {
					let encoder = JSONEncoder()
					if let encoded = try? encoder.encode(data)
					{
						try encoded.write(to: fileURL, options: .atomic)
						log.print("wrote cache for \(fileName)")
					}
				}
			}
			catch
			{
				print(error)
			}
		}
	}
	
	func getCurrencies () -> [Currency]?
	{
		return read(fileName: S.currenciesFileName, type: Array<Currency>.self)
	}

	func putCurrencies (_ data: [Currency])
	{
		write(fileName: S.currenciesFileName, data: data)
	}

	func getCurrencyData (for currency: Currency, key: DataKey, in range: TimeRange, with resolution: Resolution) -> CurrencyData?
	{
		let fileName = S.currencyFileNameTemplate
			.replacingOccurrences(of: S.templateId, with: currency.id)
			.replacingOccurrences(of: S.templateKey, with: key)

		var currencyData = read(fileName: fileName, type: CurrencyData.self)
		currencyData?.wasCached = true
		
		return currencyData?.subset(range)
	}
	
	func getCurrencyDatas (for currency: Currency, key: DataKey, in range: TimeRange, with resolution: Resolution) -> [CurrencyData]?
	{
		let fileName = S.currencyFileNameTemplate
			.replacingOccurrences(of: S.templateId, with: currency.id)
			.replacingOccurrences(of: S.templateKey, with: key)

		if var currencyData = read(fileName: fileName, type: CurrencyData.self)
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
			
			let fileName = S.currencyFileNameTemplate
				.replacingOccurrences(of: S.templateId, with: currency.id)
				.replacingOccurrences(of: S.templateKey, with: data.key)

			if let currencyData = read(fileName: fileName, type: CurrencyData.self)
			{
				let merged = currencyData.merge(data)
				write(fileName: fileName, data: merged)
			}
			else
			{
				write(fileName: fileName, data: data)
			}
		}
	}
}
