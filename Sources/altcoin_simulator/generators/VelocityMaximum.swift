//
//  FirstDerivativeMaximum.swift
//  altcoin-simulator
//
//  Created by Timothy Prepscius on 6/17/19.
//

import Foundation

class TradeGeneratorVelocitiesMaximum : TradeGeneratorWithDataProviderAndTimeRange
{
	let log = Log(clazz: TradeGeneratorVelocitiesMaximum.self)

	override init (relativeDataProvider : RelativeDataProvider, timeRange: TimeRange, resolution: Resolution)
	{
		super.init(relativeDataProvider: relativeDataProvider, timeRange: timeRange, resolution: resolution)
	}
	
	override func generateTrades() throws -> [Trade]?
	{
		let p = relativeDataProvider
		guard let currencies = try p.getCurrencies() else { return nil }
		
		var trades = [Trade]()
		
		typealias IdToVelocity = (id: CurrencyId, velocity: Real)
		
		var idToVelocity = try currencies.enumerated().map { (i,c) -> IdToVelocity in
			//log.print("\(i)/\(currencies.count)")
			return (id: c.id, velocity: try p.getCurrencyData(for: c, key: S.priceUSD, in: timeRange, with: resolution)?.values.velocity ?? -Real.greatestFiniteMagnitude)
		}
		
		idToVelocity.sort {
			return $0.velocity > $1.velocity
		}
		
		idToVelocity.map { log.print("\($0.id): \($0.velocity)") }
		
		return trades
	}
	
}
