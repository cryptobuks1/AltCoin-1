//
//  TimeProvider.swift
//  altcoin-simulator
//
//  Created by Timothy Prepscius on 6/16/19.
//

import Foundation

public protocol TimeProvider
{
	var now : Time { get }
}

public class TimeProviderStep : TimeProvider
{
	let log = Log(clazz: TimeProviderStep.self)
	
	var now_ : Time
	let stepEquation : Equation_P1_R1;
	
	public init (now: Time, stepEquation : @escaping Equation_P1_R1)
	{
		self.now_ = now
		self.stepEquation = stepEquation
		
		log.print { "TimeProviderStep \(now)" }
	}
	
	public var now: Time {
		return now_
	}
	
	public func step ()
	{
		now_ = stepEquation(now_)
	}
}
