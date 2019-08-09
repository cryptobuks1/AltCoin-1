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
		
		guard let currencies = try p.getCurrencies()?.currencies else { return nil }

//		var trades = [Trade]()
		let trades : [Trade]? = nil
		
		typealias IdToVelocity = (id: CurrencyId, velocity: Real)
		
		let idToVelocityQ : [IdToVelocity?] = currencies.enumerated().map_parallel { (i, c) -> IdToVelocity? in

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
		idToVelocity.enumerated().filter { $0.0 < 10 }.forEach { (i,iv) in log.print { "\(iv.id): \(iv.velocity)" } }
		
		return trades
	}
	
}
