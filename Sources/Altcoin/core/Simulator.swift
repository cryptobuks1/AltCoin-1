//
//  DailySimulator.swift
//  BSON
//
//  Created by Timothy Prepscius on 6/15/19.
//

import Foundation
import SigmaSwiftStatistics

public class Simulator
{
	let tradeGenerator : TradeGenerator
	var tradeBook : TradeBook

	public init (tradeGenerator: TradeGenerator, tradeBook: TradeBook)
	{
		self.tradeGenerator = tradeGenerator
		self.tradeBook = tradeBook
	}
	
	public func execute () throws
	{
		if let trades = try tradeGenerator.generateTrades()
		{
			tradeBook.trades.append(contentsOf: trades)
		}
	}
}

public class SimulatorRunner
{
	let log = Log(clazz: SimulatorRunner.self)

	var simulator: Simulator
	var timeProvider: TimeProviderStep
	
	public init (simulator: Simulator, timeProvider: TimeProviderStep)
	{
		self.simulator = simulator
		self.timeProvider = timeProvider
	}
	
	public func run (until: Time) throws
	{
		while timeProvider.now < until
		{
			log.print("stepping simulation at time \(TimeEvents.toString(timeProvider.now))")
			try simulator.execute()
			timeProvider.step()
		}
	}
}

