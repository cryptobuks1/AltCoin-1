//
//  DataTypes+MergeSubset.swift
//  altcoin-simulator
//
//  Created by Timothy Prepscius on 6/20/19.
//

import Foundation

extension TimeRange
{
	func round(_ r : TimeInterval) -> TimeRange
	{
		return TimeRange(uncheckedBounds: (floor(lowerBound/r) * r, ceil(upperBound/r) * r))
	}

	func contains(_ r: TimeRange) -> Bool {
		return contains(r.lowerBound) && contains(r.upperBound)
	}
	
	func extends (_ r: TimeRange) -> Bool {
		return contains(r.lowerBound) || contains(r.upperBound)
	}
	
	func extend (_ r: TimeRange) -> TimeRange {
		guard !contains(r) else { return self }
		assert(extends(r))
		
		return contains(r.lowerBound) ?
			TimeRange(uncheckedBounds: (lowerBound, r.upperBound)) :
			TimeRange(uncheckedBounds: (r.lowerBound, upperBound))
	}
}

extension TimeRanges
{
	func contains(_ range: TimeRange) -> Bool
	{
		let matches = ranges.filter { $0.contains(range) }
		
		TimeRanges.log.print("\(ranges.map{ TimeEvents.toString($0) }) && \(TimeEvents.toString(range)) \(matches.count)")
		return !matches.isEmpty
	}
	
	func merge (_ range: TimeRange) -> TimeRanges
	{
		var distinct = [TimeRange]()
		var overlap = [TimeRange]()
		
		for r in ranges
		{
			if r.contains(range)
			{
				overlap.append(r)
			}
			else
			{
				if range.contains(r)
				{
					// remove the sub range by ignoring
				}
				else
				{
					if r.extends(range)
					{
						overlap.append(r.extend(range))
					}
					else
					{
						distinct.append(r)
					}
				}
			}
		}
		
		if overlap.isEmpty
		{
			overlap.append(range)
		}
		
		var reduce = overlap.first!
		for m in overlap.dropFirst()
		{
			reduce = reduce.extend(m)
		}
		
		distinct.append(reduce)
		return TimeRanges(ranges: distinct)
	}
	
	func merge (_ ranges: TimeRanges) -> TimeRanges
	{
		var timeRange = self
		for range in ranges.ranges
		{
			timeRange = timeRange.merge(range)
		}
		
		return timeRange
	}
}

extension HistoricalValues
{
	func merge(_ rhs: HistoricalValues?) -> HistoricalValues
	{
		guard let rhs = rhs else { return self }
		let unique = Array(Set(samples + rhs.samples)).sorted {
			return $0.time < $1.time
		}
		
		HistoricalValues.log.print("merged \(samples.count) + \(rhs.samples.count) -> \(unique.count)")
		
		return HistoricalValues(samples: unique)
	}

	func subRange(_ range: TimeRange) -> HistoricalValues
	{
		return HistoricalValues(samples: samples.filter { range.contains($0.time) })
	}
}

extension CurrencyData
{
	func merge(_ rhs : CurrencyData) -> CurrencyData?
	{
		return CurrencyData(
			key: key,
			ranges: ranges.merge(rhs.ranges),
			values: values.merge(rhs.values),
			cacheTime: cacheTime,
			wasCached: wasCached
		)
	}
	
	func subset(_ requestedRange: TimeRange) -> CurrencyData?
	{
		guard ranges.contains(requestedRange) else { return nil }
		
		let subset = CurrencyData(
			key: key,
			ranges: TimeRanges(ranges:[requestedRange]),
			values: values.subRange(requestedRange),
			cacheTime: cacheTime,
			wasCached: wasCached
		)
		
		return subset
	}
	
	
}
