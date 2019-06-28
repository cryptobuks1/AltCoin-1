//
//  DataTypes+MergeSubset.swift
//  altcoin-simulator
//
//  Created by Timothy Prepscius on 6/20/19.
//

import Foundation

extension TimeRange
{
	static let Zero = TimeRange(uncheckedBounds: (0,0))

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
	
	func intersection(_ r: TimeRange) -> TimeRange?
	{
		let result : TimeRange?
		
		if contains(r.lowerBound) && r.lowerBound < upperBound
		{
			let l = r.lowerBound
			let u = contains(r.upperBound) ? r.upperBound : upperBound
			result = TimeRange(uncheckedBounds: (l, u))
		}
		else
		if contains(r.upperBound) && lowerBound < r.upperBound
		{
			let u = r.upperBound
			let l = contains(r.lowerBound) ? r.lowerBound : lowerBound
			return TimeRange(uncheckedBounds: (l, u))
		}
		else
		if r.contains(self)
		{
			result = self
		}
		else
		{
			result = nil
		}
		
		TimeRange.log.print("intersection \(self) & \(r) -> \(result)")
		return result
	}
	
	func excluding(_ r: TimeRange) -> [TimeRange]
	{
		var result = [TimeRange]()
		
		if contains(r.lowerBound) && lowerBound < r.lowerBound
		{
			result.append(TimeRange(uncheckedBounds: (lowerBound, r.lowerBound)))
		}

		if contains(r.upperBound) && upperBound > r.upperBound
		{
			result.append(TimeRange(uncheckedBounds: (r.upperBound, upperBound)))
		}

		if result.isEmpty
		{
			result.append(self)
		}
		
		TimeRange.log.print("excluding \(self) & \(r) -> \(result)")
		return result
	}
	
	func excluding(_ rs: [TimeRange]) -> [TimeRange]
	{
		var result = [self]
		
		for r in rs
		{
			var resultNext = [TimeRange]()
			for l in result
			{
				resultNext.append(contentsOf: l.excluding(r))
			}
			
			result = resultNext
		}
		
		TimeRange.log.print("excluding \(self) & \(rs) -> \(result)")
		return result
	}
	
	func excluding(_ rs: TimeRanges) -> TimeRanges
	{
		return TimeRanges(ranges: excluding(rs.ranges))
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
	
	func intersection(_ range: TimeRange) -> TimeRanges
	{
		let ranges = self.ranges.map({ return $0.intersection(range) }).compactMap({ return $0 })
		return TimeRanges(ranges: ranges)
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
			wasCached: wasCached
		)
		
		return subset
	}
	
	
}
