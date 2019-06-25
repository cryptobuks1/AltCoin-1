//
//  JSONURLTask.swift
//  AltCoinSimulator
//
//  Created by Timothy Prepscius on 6/15/19.
//  Copyright © 2019 Timothy Prepscius. All rights reserved.
//

import Foundation

class WebCache
{
	static let instance = WebCache()

	class S_ {
		static let
			folderName = "altcoin-simulator/http"
	}

	init()
	{
		if let dataFolder = getDataFolderUrl()
		{
			try? FileManager.default.createDirectory(at: dataFolder, withIntermediateDirectories: true, attributes: nil)
		}
	}
	
	func getDataFolderUrl () -> URL?
	{
		if var documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
		{
			documentsURL.appendPathComponent(S_.folderName)
			return documentsURL
		}
		
		return nil
	}
	
	func getFileUrlFor(_ fileName: String) -> URL?
	{
		if var dataFolderUrl = getDataFolderUrl()
		{
			dataFolderUrl.appendPathComponent(fileName)
			return dataFolderUrl
		}
		
		return nil
	}

	func convertUrlToFileName (_ url : URL) -> String
	{
		let s = url.absoluteString
		return s.replacingOccurrences(of: ":", with: "=").replacingOccurrences(of: "/", with: "#")
	}
	
	func getCacheFor (url: URL) -> Any?
	{
		return autoreleasepool {
			if let fileUrl = getFileUrlFor(convertUrlToFileName(url))
			{
				return try? JSONSerialization.jsonObject(with: Data(contentsOf: fileUrl), options: [])
			}
			return nil
		}
	}
	
	func setCacheFor (url: URL, json: Any?) throws
	{
		try autoreleasepool {
			if let json = json, let fileUrl = getFileUrlFor(convertUrlToFileName(url))
			{
				let data = try JSONSerialization.data(withJSONObject: json, options: [])
				try data.write(to: fileUrl, options: .atomic)
			}
		}
	}
}

extension URLSession {

    func withProxy(proxyURL: String, proxyPort: Int) -> URLSession
    {
        let configuration = self.configuration

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

class JSONURLSessionManager
{
	typealias Proxy = (url: String, port: Int)

	static var shared = ThreadShared<JSONURLSessionManager>({ return JSONURLSessionManager() })

	let log = Log(clazz: JSONURLSessionManager.self)
	var session : URLSession! = nil

	init ()
	{
		_ = cycle()
	}

	func cycle () -> Bool
	{
		log.print("cycling")
		
		if let proxy = ProxyFinder.shared.getRandomProxy()
		{
			session = URLSession.shared.withProxy(proxyURL: proxy.url, proxyPort: proxy.port)
			return true
		}
		
		session = URLSession.shared;
		return false
	}
	
	func readFromDisk (fileName: String)
	{
		
	}
}

class JSONURLTask
{
	let log = Log(clazz: JSONURLTask.self)

	enum URLResponseError : Error {
		case statusCodeNot200
	}

	static let shared = JSONURLTask()
	
	func dataTask (with url: URL, callback: @escaping (_ json:Any?, _ error:Error?)->()) -> URLSessionDataTask
	{
		let task = JSONURLSessionManager.shared.v.session.dataTask(with: url)
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
	
	func dataTaskSync (with url: URL, useCache: Bool) -> (json: Any?, error: Error?, wasCached: Bool)
	{
		if useCache, let json = WebCache.instance.getCacheFor(url: url)
		{
			log.print("url cache of \(url.absoluteString)")
			return (json, nil, true)
		}
		
		let sem = DispatchSemaphore(value: 0)
		var result : (Any?, Error?, Bool)! = nil
		
		let task = dataTask(with: url) {
			json, error in
			
			result = (json, error, false)
			sem.signal();
		}
		
		task.resume()
		sem.wait()
		
		log.print("web read of \(url.absoluteString)")

		if useCache
		{
			try? WebCache.instance.setCacheFor(url: url, json: result.0)
		}
		
		return result
	}

	var sleepSeconds = 30.0
	var requestDelaySeconds = 0.0
	var lastRequestSecond : TimeInterval = 0
	
	func sleep(_ delay : Double)
	{
		let usecond : Double = 1000000
		usleep(UInt32(delay * usecond))
	}

	func dataTaskSyncRateLimitRetry (with url: URL, useCache: Bool) -> (json: Any?, error: Error?, wasCached: Bool)
	{
		var alreadySlept = false

		repeat
		{
			do
			{
				let requestTimeSecond = Date().timeIntervalSinceReferenceDate
				let differenceSeconds = requestTimeSecond - lastRequestSecond
				let delay = requestDelaySeconds - differenceSeconds
				if delay > 0
				{
					sleep(delay)
				}

				let result = dataTaskSync(with: url, useCache: useCache)
				if !result.wasCached
				{
					lastRequestSecond = requestTimeSecond
				}
				
				if let error = result.error
				{
					throw error
				}
				
				return result
			}
			catch
			{
				print(error)

				if !JSONURLSessionManager.shared.v.cycle()
				{
					log.print("could not cycle, instead sleeping.")
					print("sleeping for \(sleepSeconds)")
					sleep(sleepSeconds)

					if alreadySlept
					{
						sleepSeconds *= 1.1
					}
					
					if !alreadySlept
					{
						 requestDelaySeconds *= 1.02
						 print("increased sleepSeconds to \(sleepSeconds) requestDelaySeconds \(requestDelaySeconds)")
					}
				
					alreadySlept = true
				}
			}
		} while true
	}

}
