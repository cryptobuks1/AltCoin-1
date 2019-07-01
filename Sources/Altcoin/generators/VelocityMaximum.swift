//
//  FirstDerivativeMaximum.swift
//  altcoin-simulator
//
//  Created by Timothy Prepscius on 6/17/19.
//

import Foundation

public class TradeGeneratorVelocitiesMaximum : TradeGeneratorWithDataProviderAndTimeRange
{
	let log = Log(clazz: TradeGeneratorVelocitiesMaximum.self)

	public override init (relativeDataProvider : RelativeDataProvider, timeRange: TimeRange, resolution: Resolution)
	{
		super.init(relativeDataProvider: relativeDataProvider, timeRange: timeRange, resolution: resolution)
	}
	
	public override func generateTrades() throws -> [Trade]?
	{
		let p = relativeDataProvider
		
		// this line has the filter, which will get only the top 5 currencies
//		guard let currencies = try p.getCurrencies()?.filter({ return $0.rank < 5 }) else { return nil }

		// this line does not have the first, so it will get all currencies
		guard let currencies = try p.getCurrencies() else { return nil }

		var trades = [Trade]()
		
		typealias IdToVelocity = (id: CurrencyId, velocity: Real)
		
		let idToVelocityQ : [IdToVelocity?] = try currencies.currencies.enumerated().map { (i, c) -> IdToVelocity? in

			//log.print("\(i)/\(currencies.count)")
			do
			{
				if let velocity = try p.getCurrencyData(for: c, key: S.priceUSD, in: timeRange, with: resolution)?.values.velocity
				{
					return (id: c.id, velocity: velocity)
				}
			}
			catch
			{
				print(error)
			}
			
			return nil
		}
		
		var idToVelocity : [IdToVelocity] = idToVelocityQ.compactMap { return $0 }
		idToVelocity.sort { return $0.velocity > $1.velocity }
		idToVelocity.forEach { log.print("\($0.id): \($0.velocity)") }
		
		return trades
	}
	
}
