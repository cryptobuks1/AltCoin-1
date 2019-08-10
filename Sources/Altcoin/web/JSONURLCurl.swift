//
//  JSONURLTaskNIO.swift
//  AltCoin
//
//  Created by Timothy Prepscius on 8/7/19.
//

import Foundation
import sajson_swift
import AsyncHTTPClient

import PerfectCURL

class JSONURLSessionManagerCURL : IOSessionManager
{
	typealias Proxy = (url: String, port: Int)

	static var shared = ThreadShared<JSONURLSessionManagerCURL>({ return JSONURLSessionManagerCURL() })

	let log = Log(clazz: JSONURLSessionManagerCURL.self)
	var proxy : Proxy? = nil

	init ()
	{
		_ = cycle()
	}
	
	deinit
	{
	}

	func cycle () -> Bool
	{
		proxy = ProxyFinder.shared.getRandomProxy()
		return true
	}
	
	func get (url: URL) -> CURLRequest
	{
		if let proxy = proxy
		{
			log.print { "using proxy \(proxy) for \(url)" }
			return CURLRequest(url.absoluteString, .proxy(proxy.url), .proxyPort(proxy.port), .connectTimeout(timeOutConnect), .timeout(timeoutResource))
		}
		
		return CURLRequest(url.absoluteString)
	}
}

class CURLTask : IOTask
{
	internal init(request: CURLRequest) {
		self.request = request
	}
	
	var request : CURLRequest!
	
	func resume ()
	{
	}
	
}

class JSONURLTaskCURL : IOURLTask
{
	let logCache = LogNull(clazz: JSONURLTask.self)
	let log = Log(clazz: JSONURLTask.self)

	public func sessionManager () -> IOSessionManager
	{
		return JSONURLSessionManagerCURL.shared.v
	}

	public func dataTask (with url: URL, callback: @escaping (_ json:JSON?, _ error:Error?)->()) -> IOTask
	{
		let request = JSONURLSessionManagerCURL.shared.v.get(url: url);
		
		DispatchQueue.global(qos: .background).async {
			request.perform {
				confirmation in
				
				var transformedError : Error? = nil
				var transformedData : JSON? = nil

				do
				{
					let response = try confirmation()
					if response.responseCode != 200
					{
						throw URLResponseError.statusCodeNot200
					}
					
					var bodyBytes = response.bodyBytes
					try bodyBytes.withUnsafeMutableBytes {
						let data = Data($0)
						let json = try parse(allocationStrategy: .single, input: data)
						transformedData = (data, json)
					}
				}
				catch
				{
					transformedError = error
				}

				callback(transformedData, transformedError)
			}
		}
		
		return CURLTask(request: request)
	}
	
}
