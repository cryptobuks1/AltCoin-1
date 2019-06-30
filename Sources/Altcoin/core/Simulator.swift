//
//  DailySimulator.swift
//  BSON
//
//  Created by Timothy Prepscius on 6/15/19.
//

import Foundation
import SigmaSwiftStatistics

class Simulator
{
	let tradeGenerator : TradeGenerator
	var tradeBook : TradeBook

	init (tradeGenerator: TradeGenerator, tradeBook: TradeBook)
	{
		self.tradeGenerator = tradeGenerator
		self.tradeBook = tradeBook
	}
	
	func execute () throws
	{
		if let trades = try tradeGenerator.generateTrades()
		{
			tradeBook.trades.append(contentsOf: trades)
		}
	}
}

class SimulatorRunner
{
	let log = Log(clazz: SimulatorRunner.self)

	var simulator: Simulator
	var timeProvider: TimeProviderStep
	
	init (simulator: Simulator, timeProvider: TimeProviderStep)
	{
		self.simulator = simulator
		self.timeProvider = timeProvider
	}
	
	func run (until: Time) throws
	{
		while timeProvider.now < until
		{
			log.print("stepping simulation at time \(TimeEvents.toString(timeProvider.now))")
			try simulator.execute()
			timeProvider.step()
		}
	}
}

