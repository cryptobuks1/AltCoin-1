//
//  Log.swift
//  altcoin-simulator
//
//  Created by Timothy Prepscius on 6/17/19.
//

import Foundation

public class LogAlloc
{
	static func destruct (_ out : Any)
	{
#if DEBUG
		Swift.print("destruct: ", out);
#endif
	}

	static func construct (_ out : Any)
	{
#if DEBUG
		Swift.print("construct: ", out);
#endif
	}
}


public class Log
{
	let title : String
	
	init (instance: Any)
	{
		self.title = String(describing: instance)
	}

	init (clazz: Any)
	{
		self.title = String(describing: clazz)
	}
	
	init (title: String)
	{
		self.title = title
	}

	func print(_ v: Any) { Swift.print("\(title): \(v)") }
}

public class LogNull
{
	init (instance: Any)
	{
	}

	init (clazz: Any)
	{
	}
	
	init (title: String)
	{
	}
	
	func print(_ v: Any) { }
}
