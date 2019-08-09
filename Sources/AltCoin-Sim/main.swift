//
//  main.swift
//  AltCoinSimulator
//
//  Created by Timothy Prepscius on 6/14/19.
//  Copyright © 2019 Timothy Prepscius. All rights reserved.
//

import Foundation
import AltCoin

let runDataCaching = CommandLine.arguments.contains("--cache")
if runDataCaching
{
	let webDataProvider = DataProviderWeb()
	let diskDataProvider = try DataProviderBinary()

	if let currencies = try webDataProvider.getCurrencies()
	{
		try? diskDataProvider.putCurrencies(currencies)
		let allTime = TimeRange(uncheckedBounds: (TimeEvents.firstBubbleStart, TimeEvents.today12am))
		
		let currencyCount = currencies.currencies.count
		currencies.currencies.enumerated().forEach_parallel {
			let index = $0.0
			let currency = $0.1
		
			print("acquiring currency \(currency.id) \(index)/\(currencyCount)")
		
			autoreleasepool {
				let memoryDataProvider = DataProviderMemory()

				let cacheProviderDM = DataProviderCaching (source: diskDataProvider, cache: memoryDataProvider)
				let cacheProviderWM = DataProviderCaching (source: webDataProvider, cache: memoryDataProvider)


				// read from the disk cache into memory cache
	//			_ = try? cacheProviderDM.getCurrencyDatas(for: currency, key: S.priceUSD, in: allTime, with: .minute)
				
				// read if necessary from the web to the memory cache
				_ = try? cacheProviderWM.getCurrencyDatas(for: currency, key: S.priceUSD, in: allTime, with: .minute)
				
				// write to disk
				try? memoryDataProvider.writeTo(diskDataProvider)
			}
		}
	}
	
	print("finished caching currencies to binary store")
}

let runSimulation =  CommandLine.arguments.contains("--simulate")
if runSimulation
{
	print("beginning simulation")
	
	let webDataProvider = DataProviderWeb(useCacheForCurrencies: true)

	//let diskDataProvider = try DataProviderDiskSQLite()
	let diskDataProvider = DataProviderBinary(readOnly: true)
	let memoryDataProvider = DataProviderMemory()
	
	let diskCacheProvider = DataProviderCaching (source: webDataProvider, cache: diskDataProvider)
	let cacheProvider = DataProviderCaching (source: diskCacheProvider, cache: memoryDataProvider)


	var dataProvider : DataProvider = cacheProvider
	//dataProvider = DataProviderCurrencyFilter(provider: dataProvider, filter: { $0.rank < 5 })

	let timeRange = StandardTimeRanges.oneWeek
	let timeProvider = TimeProviderStep(now: TimeEvents.firstBubbleStart - timeRange.lowerBound, stepEquation: StandardTimeEquations.nextDay)
	let relativeDataProvider = RelativeDataProviderConcrete(dataProvider: dataProvider, timeProvider: timeProvider)

	let resolution = Resolution.day
	let tradeGenerator = TradeGeneratorVelocitiesMaximum(
		relativeDataProvider: relativeDataProvider,
		timeRange: timeRange,
		resolution: resolution
	)

	let simulator = Simulator(tradeGenerator: tradeGenerator, tradeBook: TradeBook(trades: []))

	let runner = SimulatorRunner(simulator: simulator, timeProvider: timeProvider)

	try runner.run(until: TimeEvents.today12am)
}

