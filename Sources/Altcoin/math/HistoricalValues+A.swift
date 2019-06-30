//
//  DataProvider.swift
//  AltCoinSimulator
//
//  Created by Timothy Prepscius on 6/15/19.
//  Copyright © 2019 Timothy Prepscius. All rights reserved.
//

import Foundation
import SigmaSwiftStatistics

extension HistoricalValues
{
	var averageTimeBetweenSamples : Real {
		guard !samples.isEmpty else { return 0.0 }
		
		return (samples.last!.time - samples.first!.time) / Real(samples.count)
	}
	
	var deltaTimes : [Real] {
		guard samples.count > 1 else { return [Real]() }
		
		var times = [Real]()
		var last = samples.first!.time
		for s in samples.dropFirst()
		{
			times.append(s.time - last)
			last = s.time
		}
		
		return times
	}

	var medianTimeBetweenSamples : Real {
		return Sigma.median(deltaTimes) ?? 0.0
	}
	
	
	var stddevTimeBetweenSamples: Real {
		return Sigma.standardDeviationSample(deltaTimes) ?? 0.0
	}

	var velocity : Real {
		guard let first = samples.first, let last = samples.last else {
			return 0
		}
		
		return (last.value - first.value) / (last.time - first.time)
	}
	
	var timeRange: TimeRange? {
		guard let first = samples.first, let last = samples.last else {
			return nil
		}

		return TimeRange(uncheckedBounds: (first.time, last.time))
	}
}


