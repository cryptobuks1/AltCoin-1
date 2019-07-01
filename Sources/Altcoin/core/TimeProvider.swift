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
	var now_ : Time
	let stepEquation : Equation_P1_R1;
	
	public init (now: Time, stepEquation : @escaping Equation_P1_R1)
	{
		self.now_ = now
		self.stepEquation = stepEquation
	}
	
	public var now: Time {
		return now_
	}
	
	public func step ()
	{
		now_ = stepEquation(now_)
	}
}
