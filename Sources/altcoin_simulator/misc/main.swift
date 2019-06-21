//
//  main.swift
//  AltCoinSimulator
//
//  Created by Timothy Prepscius on 6/14/19.
//  Copyright © 2019 Timothy Prepscius. All rights reserved.
//

import Foundation

let webDataProvider = DataProviderWeb()
let diskDataProvider = try DataProviderDiskJSON()
let memoryDataProvider = DataProviderMemory()
let diskCacheProvider = DataProviderCaching (source: webDataProvider, cache: diskDataProvider)
let memoryCacheProvider = DataProviderCaching (source: diskCacheProvider, cache: memoryDataProvider)

let dataProvider = memoryCacheProvider
let timeProvider = TimeProviderStep(now: TimeEvents.firstBubbleStart, stepEquation: StandardTimeEquations.nextDay)

let relativeDataProvider = RelativeDataProviderConcrete(dataProvider: dataProvider, timeProvider: timeProvider)

let timeRange = StandardTimeRanges.fourWeeks
let resolution = Resolution.day
let tradeGenerator = TradeGeneratorVelocitiesMaximum(
	relativeDataProvider: relativeDataProvider,
	timeRange: timeRange,
	resolution: resolution
)

let simulator = Simulator(tradeGenerator: tradeGenerator, tradeBook: TradeBook(trades: []))

let runner = SimulatorRunner(simulator: simulator, timeProvider: timeProvider)

runner.run(until: TimeEvents.firstBubbleCrash)
