//
//  JSONURLTask.swift
//  AltCoinSimulator
//
//  Created by Timothy Prepscius on 6/15/19.
//  Copyright © 2019 Timothy Prepscius. All rights reserved.
//

import Foundation

class JSONURLTask
{
	enum URLResponseError : Error {
		case statusCodeNot200
	}

	static let shared = JSONURLTask()
	
	func dataTask (with url: URL, callback: @escaping (_ json:Any?, _ error:Error?)->()) -> URLSessionDataTask
	{
		let task = URLSession.shared.dataTask(with: url)
		{
			data, response, error in
			
			var transformedError : Error? = error
			var transformedData : Any? = nil

			// check for a non 200
			if error == nil
			{
				do
				{
					if let urlResponse = response as? HTTPURLResponse
					{
						if urlResponse.statusCode != 200
						{
							throw URLResponseError.statusCodeNot200
						}
					}
			
					transformedData = try JSONSerialization.jsonObject(with: data!, options: [])
				}
				catch
				{
					transformedError = error
				}
			}
			
			callback(transformedData, transformedError)
		}
		
		return task;
	}
	
	func dataTaskSync (with url: URL) -> (json: Any?, error: Error?)
	{
		let sem = DispatchSemaphore(value: 0)
		var result : (Any?, Error?)? = nil
		
		let task = dataTask(with: url) {
			json, error in
			
			result = (json, error)
			sem.signal();
		}
		
		task.resume()
		sem.wait()
		return result!
	}

}
