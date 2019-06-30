//
//  Extensions.swift
//  altcoin_simulator
//
//  Created by Timothy Prepscius on 6/27/19.
//

import Foundation

extension Double
{
	init?(any: Any?)
	{
		if let v = any as? Double { self.init(v); return }
		if let v = any as? Float { self.init(v); return }
		if let v = any as? Int { self.init(v); return }
		if let v = any as? UInt { self.init(v); return }
		if let v = any as? Int32 { self.init(v); return }
		if let v = any as? UInt32 { self.init(v); return }
		if let v = any as? UInt64 { self.init(v); return }
		if let v = any as? UInt64 { self.init(v); return }

		return nil
	}
}

extension Int
{
	init?(any: Any?)
	{
		if let v = any as? Int { self.init(v); return }
		if let v = any as? UInt { self.init(v); return }
		if let v = any as? Int32 { self.init(v); return }
		if let v = any as? UInt32 { self.init(v); return }
		if let v = any as? UInt64 { self.init(v); return }
		if let v = any as? UInt64 { self.init(v); return }

		return nil
	}
}

extension Array
{
	func isSorted (_ c : (Element, Element) -> Bool) -> Bool
	{
		guard !isEmpty else { return true }
		
		var l = first!
		for r in dropFirst()
		{
			if !c(l, r)
			{
				return false
			}
			l = r
		}
		
		return true
	}
}

extension Sequence
{
	func unique<K : Hashable>(_ keyFunction: (Element) -> K) -> [Element]
	{
		var result = [Element]()
		var added = Set<K>()
		for element in self {
			let key = keyFunction(element)
			if !added.contains(key) {
				result.append(element)
				added.insert(key)
			}
		}
		
		return result
	}
	
	func hasDuplicates<K : Hashable>(_ keyFunction: (Element) -> K) -> Bool
	{
		var added = Set<K>()
		for element in self {
			let key = keyFunction(element)
			if added.contains(key) {
				return true
			}
			
			added.insert(key)
		}
		
		return false
	}
}
