//
//  Parallel.swift
//  altcoin_simulator
//
//  Created by Timothy Prepscius on 6/25/19.
//

import Foundation


func synchronized<T>(_ lock: AnyObject, _ body: () throws -> T) rethrows -> T {
    objc_sync_enter(lock)
    defer { objc_sync_exit(lock) }
    return try body()
}

typealias RepeatWithInterval = DispatchSourceTimer

func repeatWithInterval (_ interval: TimeInterval, _ block: @escaping () -> ()) -> RepeatWithInterval
{
	let source = DispatchSource.makeTimerSource()
	source.schedule(deadline: .now() + interval, repeating: interval)
	source.setEventHandler(handler: { block() })
	source.resume();

	return source
}

func cancelRepeatWithInterval (_ r: RepeatWithInterval)
{
	r.cancel()
}

class ThreadShared<T> {
	typealias Generator = ()->T
	
	var values: [Thread:T] = [:]
	let generator : Generator
	
	init(_ generator: @escaping Generator)
	{
		self.generator = generator
	}
	
	var v : T
	{
		if let c = values[Thread.current]
		{
			return c
		}
		
		let c = generator()
		
		objc_sync_enter(self)
    	defer { objc_sync_exit(self) }
		values[Thread.current] = c
		return c
	}
}

extension Sequence
{
	var count_slow : Int {
		var i = 0
		for _ in self
		{
			i += 1
		}
		
		return i
	}
	
	func index_slow(_ z: Int) -> Element?
	{
		var i = z
		for v in self
		{
			if i == 0
			{
				return v
			}

			i -= 1
		}
		return nil
	}

	func forEach_parallel(_ f: (_ t: Element) ->()) {
		DispatchQueue.concurrentPerform(iterations: self.count_slow) { (index) in
			f(self.index_slow(index)!)
		}
	}

	func map_parallel<T>(_ f: (_ t: Element) -> T) -> [T] {
		var a = [T]()
		let lock = NSLock()
		
		DispatchQueue.concurrentPerform(iterations: self.count_slow) { (index) in
			let r = f(self.index_slow(index)!)
			
			lock.lock()
			defer { lock.unlock() }
			a.append(r)
		}
		
		return a
	}
}

extension Array
{
	var count_slow : Int {
		return self.count
	}
	
	func index_slow(_ i: Int) -> Element?
	{
		return self[i]
	}

}
