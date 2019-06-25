//
//  main.swift
//  AltCoinSimulator
//
//  Created by Timothy Prepscius on 6/14/19.
//  Copyright © 2019 Timothy Prepscius. All rights reserved.
//

import Foundation

JSONURLSessionManager.shared.addProxies(ProxyFinder.shared.proxies)

let webDataProvider = DataProviderWeb()
let diskDataProvider = try DataProviderDiskJSON()
let memoryDataProvider = DataProviderMemory()
let diskCacheProvider = DataProviderCaching (source: webDataProvider, cache: diskDataProvider)
//let memoryCacheProvider = DataProviderCaching (source: diskCacheProvider, cache: memoryDataProvider)
let memoryCacheProvider = DataProviderCaching (source: webDataProvider, cache: memoryDataProvider)

let dataProvider = memoryCacheProvider
let timeProvider = TimeProviderStep(now: TimeEvents.firstBubbleStart, stepEquation: StandardTimeEquations.nextDay)

let relativeDataProvider = RelativeDataProviderConcrete(dataProvider: dataProvider, timeProvider: timeProvider)

let timeRange = StandardTimeRanges.oneDay
let resolution = Resolution.day
let tradeGenerator = TradeGeneratorVelocitiesMaximum(
	relativeDataProvider: relativeDataProvider,
	timeRange: timeRange,
	resolution: resolution
)

let simulator = Simulator(tradeGenerator: tradeGenerator, tradeBook: TradeBook(trades: []))

let runner = SimulatorRunner(simulator: simulator, timeProvider: timeProvider)

try runner.run(until: TimeEvents.safeNow)
diskDataProvider.flush()
