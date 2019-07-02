//
//  Parallel.swift
//  altcoin_simulator
//
//  Created by Timothy Prepscius on 6/25/19.
//

import Foundation


public func synchronized<T>(_ lock: AnyObject, _ body: () throws -> T) rethrows -> T {
    objc_sync_enter(lock)
    defer { objc_sync_exit(lock) }
    return try body()
}

public typealias RepeatWithInterval = DispatchSourceTimer

public func repeatWithInterval (_ interval: TimeInterval, _ block: @escaping () -> ()) -> RepeatWithInterval
{
	let source = DispatchSource.makeTimerSource()
	source.schedule(deadline: .now() + interval, repeating: interval)
	source.setEventHandler(handler: { block() })
	source.resume();

	return source
}

public func cancelRepeatWithInterval (_ r: RepeatWithInterval)
{
	r.cancel()
}

public class ThreadShared<T> {
	public typealias Generator = ()->T
	
	var values: [Thread:T] = [:]
	let generator : Generator
	
	public init(_ generator: @escaping Generator)
	{
		self.generator = generator
	}
	
	public var v : T
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
	public var count_slow : Int {
		var i = 0
		for _ in self
		{
			i += 1
		}
		
		return i
	}
	
	public func index_slow(_ z: Int) -> Element?
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

	public func forEach_parallel(_ f: (_ t: Element) ->()) {
		DispatchQueue.concurrentPerform(iterations: self.count_slow) { (index) in
			f(self.index_slow(index)!)
		}
	}

	public func map_parallel<T>(_ f: (_ t: Element) -> T) -> [T] {
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

public extension Array
{
	public var count_slow : Int {
		return self.count
	}
	
	public func index_slow(_ i: Int) -> Element?
	{
		return self[i]
	}

}

public class ReadWriteLock
{
	var l = pthread_rwlock_t()
	
	public init ()
	{
		pthread_rwlock_init(&l, nil)
	}
	
	deinit
	{
		pthread_rwlock_destroy(&l)
	}
	
	public func read<T> (_ f: () throws -> T) throws -> T
	{		
		pthread_rwlock_rdlock(&l)
		defer { pthread_rwlock_unlock(&l) }
		
		return try f()
	}

	public func write<T> (_ f: () throws -> T) throws -> T
	{
		pthread_rwlock_wrlock(&l)
		defer { pthread_rwlock_unlock(&l) }
		
		return try f()
	}

	public func read<T> (_ f: () -> T) -> T
	{
		pthread_rwlock_rdlock(&l)
		defer { pthread_rwlock_unlock(&l) }
		
		return f()
	}

	public func write<T> (_ f: () -> T) -> T
	{
		pthread_rwlock_wrlock(&l)
		defer { pthread_rwlock_unlock(&l) }
		
		return f()
	}
}
