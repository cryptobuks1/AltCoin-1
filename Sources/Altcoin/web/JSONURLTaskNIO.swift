//
//  JSONURLTaskNIO.swift
//  AltCoin
//
//  Created by Timothy Prepscius on 8/7/19.
//

import Foundation
import sajson_swift
import AsyncHTTPClient

import NIO

class JSONURLSessionManagerNIO : IOSessionManager
{
	typealias Proxy = (url: String, port: Int)

	static var shared = ThreadShared<JSONURLSessionManagerNIO>({ return JSONURLSessionManagerNIO() })

	let log = Log(clazz: JSONURLSessionManagerNIO.self)
	var session : HTTPClient! = nil

	init ()
	{
		_ = cycle()
	}
	
	deinit
	{
		try? session?.syncShutdown()
	}

	func cycle () -> Bool
	{
		try? session?.syncShutdown()
		
		log.print { "cycling" }
		
		if let proxy = ProxyFinder.shared.getRandomProxy()
		{
			session = HTTPClient(eventLoopGroupProvider: .createNew, configuration: .init(certificateVerification: .noHostnameVerification, followRedirects: true, timeout: HTTPClient.Timeout(connect: .seconds(TimeAmount.Value(timeOutConnect)), read: .seconds(TimeAmount.Value(timeoutResource))), proxy: .server(host: proxy.url, port: proxy.port)))
			return true
		}
		
		session = HTTPClient(eventLoopGroupProvider: .createNew)
		return false
	}
}

class NIOTask : IOTask
{
	internal init(future: EventLoopFuture<HTTPClient.Response>?) {
		self.future = future
	}
	
	var future : EventLoopFuture<HTTPClient.Response>!
	
	func resume ()
	{
		
	}
}

class JSONURLTaskNIO : IOURLTask
{
	let logCache = LogNull(clazz: JSONURLTask.self)
	let log = Log(clazz: JSONURLTask.self)

	enum URLResponseError : Error {
		case statusCodeNot200
	}

	public func sessionManager () -> IOSessionManager
	{
		return JSONURLSessionManagerNIO.shared.v
	}

	public func dataTask (with url: URL, callback: @escaping (_ json:JSON?, _ error:Error?)->()) -> IOTask
	{
		let future = JSONURLSessionManagerNIO.shared.v.session.get(url: url.absoluteString)
		
		future.whenComplete
		{
			result in
			
			var transformedError : Error? = nil
			var transformedData : JSON? = nil

			switch result {

			case .success(let response):

				do
				{
					if response.status != .ok
					{
						throw URLResponseError.statusCodeNot200
					}
			
					try response.body?.withUnsafeReadableBytes {
						let data = Data($0)
						let json = try parse(allocationStrategy: .single, input: data)
						transformedData = (data, json)
					}
				}
				catch
				{
					transformedError = error
				}
				break;
				
			case .failure(let error):
				transformedError = error
				break;
			}

			callback(transformedData, transformedError)
		}
		
		return NIOTask(future: future)
	}
	
}
