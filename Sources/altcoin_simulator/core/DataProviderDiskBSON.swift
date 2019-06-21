//
//  DiskDataProvider.swift
//  AltCoinSimulator
//
//  Created by Timothy Prepscius on 6/15/19.
//  Copyright © 2019 Timothy Prepscius. All rights reserved.
//

import Foundation
import BSON

class DataProviderDiskBSON : DataCache
{
	class S {
		static let
			folderName = "altcoin-simulator/bson",
			currenciesFileName = "currencies.json",
			currencyFileNameTemplate = "currency-{id}.{key}.bson",
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
				let data = try Data(contentsOf: fileURL)
				let decoder = BSONDecoder()
				return try decoder.decode(type, from: Document(data:data))
			}
			catch
			{
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
				let encoder = BSONEncoder()
				if let encoded = try? encoder.encode(data)
				{
					try encoded.makeData().write(to: fileURL, options: .atomic)
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
		return currencyData
	}
	
	func getCurrencyDatas (for currency: Currency, key: DataKey, in range: TimeRange, with resolution: Resolution) -> [CurrencyData]?
	{
		return [getCurrencyData(for: currency, key: key, in: range, with: resolution)].compactMap { $0 }
	}

	func putCurrencyDatas(_ datas: [CurrencyData], for currency: Currency, in range: TimeRange, with resolution: Resolution)
	{
		for data in datas
		{
			let fileName = S.currencyFileNameTemplate
				.replacingOccurrences(of: S.templateId, with: currency.id)
				.replacingOccurrences(of: S.templateKey, with: data.key)
				
			write(fileName: fileName, data: data)
		}
	}
}
