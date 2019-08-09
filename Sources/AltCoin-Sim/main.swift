//
//  main.swift
//  AltCoinSimulator
//
//  Created by Timothy Prepscius on 6/14/19.
//  Copyright © 2019 Timothy Prepscius. All rights reserved.
//

import Foundation
import AltCoin

let runDataCaching = true
if runDataCaching
{
	let webDataProvider = DataProviderWeb()
	let diskDataProvider = try DataProviderBinary()

	if let currencies = try webDataProvider.getCurrencies()
	{
		try? diskDataProvider.putCurrencies(currencies)
		let allTime = TimeRange(uncheckedBounds: (TimeEvents.firstBubbleStart, TimeEvents.august1st2019))
		
		currencies.currencies.forEach_parallel {
			let currency = $0
		
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
}

let runSimulation = false
if runSimulation
{
	let webDataProvider = DataProviderWeb()
	//let diskDataProvider = try DataProviderDiskSQLite()
	let diskDataProvider = try DataProviderBinary()
	let memoryDataProvider = DataProviderMemory()
	//let diskCacheProvider = DataProviderCaching (source: webDataProvider, cache: diskDataProvider)
	//let cacheProvider = DataProviderCaching (source: diskCacheProvider, cache: memoryDataProvider)

	//let cacheProvider = DataProviderCaching (source: webDataProvider, cache: diskDataProvider)
	let cacheProvider = DataProviderCaching (source: webDataProvider, cache: memoryDataProvider)

	let dataProvider = cacheProvider
	//let dataProvider = DataProviderCurrencyFilter(provider: cacheProvider, filter: { $0.rank < 5 })
	let timeProvider = TimeProviderStep(now: TimeEvents.roundDown(TimeEvents.firstBubbleStart, range: TimeQuantities.Week), stepEquation: StandardTimeEquations.nextDay)

	let relativeDataProvider = RelativeDataProviderConcrete(dataProvider: dataProvider, timeProvider: timeProvider)

	let timeRange = StandardTimeRanges.oneWeek
	let resolution = Resolution.day
	let tradeGenerator = TradeGeneratorVelocitiesMaximum(
		relativeDataProvider: relativeDataProvider,
		timeRange: timeRange,
		resolution: resolution
	)

	let simulator = Simulator(tradeGenerator: tradeGenerator, tradeBook: TradeBook(trades: []))

	let runner = SimulatorRunner(simulator: simulator, timeProvider: timeProvider)

	try runner.run(until: TimeEvents.august1st2019)
}

