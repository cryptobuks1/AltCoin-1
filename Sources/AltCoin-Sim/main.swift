//
//  main.swift
//  AltCoinSimulator
//
//  Created by Timothy Prepscius on 6/14/19.
//  Copyright © 2019 Timothy Prepscius. All rights reserved.
//

import Foundation
import AltCoin

let webDataProvider = DataProviderWeb()
let diskDataProvider = try DataProviderDiskSQLite()
let memoryDataProvider = DataProviderMemory()
let diskCacheProvider = DataProviderCaching (source: webDataProvider, cache: diskDataProvider)

let cacheProvider = DataProviderCaching (source: diskCacheProvider, cache: memoryDataProvider)
//let cacheProvider = DataProviderCaching (source: webDataProvider, cache: diskDataProvider)
//let cacheProvider = DataProviderCaching (source: webDataProvider, cache: memoryDataProvider)

let dataProvider = DataProviderCurrencyFilter(provider: cacheProvider, filter: { $0.rank < 5 })
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

try runner.run(until: TimeEvents.july1st2019)

//try memoryDataProvider.writeTo(diskDataProvider)

