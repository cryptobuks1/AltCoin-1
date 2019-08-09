//
//  JSONURLTask.swift
//  AltCoinSimulator
//
//  Created by Timothy Prepscius on 6/15/19.
//  Copyright © 2019 Timothy Prepscius. All rights reserved.
//

import Foundation
import sajson_swift



extension URLSession {

    func withProxy(proxyURL: String, proxyPort: Int) -> URLSession
    {
        let configuration = URLSessionConfiguration.ephemeral

		configuration.connectionProxyDictionary = [
			kCFNetworkProxiesHTTPEnable: true,
			kCFNetworkProxiesHTTPProxy: proxyURL,
			kCFNetworkProxiesHTTPPort: proxyPort,
			kCFNetworkProxiesHTTPSEnable: true,
			kCFNetworkProxiesHTTPSProxy: proxyURL,
			kCFNetworkProxiesHTTPSPort: proxyPort
		]
		
		configuration.timeoutIntervalForRequest = 3.0

        return URLSession(configuration: configuration, delegate: self.delegate, delegateQueue: self.delegateQueue)
    }
}

class JSONURLSessionManagerFoundation : IOSessionManager
{
	typealias Proxy = (url: String, port: Int)

	static var shared = ThreadShared<JSONURLSessionManagerFoundation>({ return JSONURLSessionManagerFoundation() })

	let log = Log(clazz: JSONURLSessionManagerFoundation.self)
	var session : URLSession! = nil

	init ()
	{
		_ = cycle()
	}

	func cycle () -> Bool
	{
		log.print { "cycling" }
		
		if let proxy = ProxyFinder.shared.getRandomProxy()
		{
			session = URLSession.shared.withProxy(proxyURL: proxy.url, proxyPort: proxy.port)
			return true
		}
		
		session = URLSession.shared;
		return false
	}
}

extension URLSessionDataTask : IOTask
{

}

class JSONURLTaskFoundation : IOURLTask
{
	enum URLResponseError : Error {
		case statusCodeNot200
	}

	public func sessionManager () -> IOSessionManager
	{
		return JSONURLSessionManagerFoundation.shared.v
	}

	public func dataTask (with url: URL, callback: @escaping (_ json:JSON?, _ error:Error?)->()) -> IOTask
	{
		return autoreleasepool {
			let task = JSONURLSessionManagerFoundation.shared.v.session.dataTask(with: url)
			{
				data, response, error in
				
				var transformedError : Error? = error
				var transformedData : JSON? = nil

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
				
						let json = try parse(allocationStrategy: .single, input: data!)
						transformedData = (data!, json)
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
	}
}

