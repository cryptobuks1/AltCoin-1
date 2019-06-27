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
