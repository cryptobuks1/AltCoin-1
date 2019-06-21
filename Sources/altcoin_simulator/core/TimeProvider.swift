//
//  TimeProvider.swift
//  altcoin-simulator
//
//  Created by Timothy Prepscius on 6/16/19.
//

import Foundation

protocol TimeProvider
{
	var now : Time { get }
}

class TimeProviderStep : TimeProvider
{
	var now_ : Time
	let stepEquation : Equation_P1_R1;
	
	init (now: Time, stepEquation : @escaping Equation_P1_R1)
	{
		self.now_ = now
		self.stepEquation = stepEquation
	}
	
	var now: Time {
		return now_
	}
	
	func step ()
	{
		now_ = stepEquation(now_)
	}
}
