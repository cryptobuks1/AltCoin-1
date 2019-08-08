//
//  JSONURLGeneric.swift
//  AltCoin
//
//  Created by Timothy Prepscius on 8/7/19.
//

import Foundation
import sajson_swift

public typealias JSON = (data: Data, doc: sajson_swift.Document)
public typealias JSONNode = sajson_swift.Value

public protocol IOTask
{
	func resume ()
}

public protocol IOURLTask
{
	func dataTask (with url: URL, callback: @escaping (_ json:JSON?, _ error:Error?)->()) -> IOTask
	func sessionManager () -> IOSessionManager
}

public protocol IOSessionManager
{
	func cycle () -> Bool
}

class WebCache
{
	static let instance = WebCache()

	class S_ {
		static let
			folderName = "\(S.documents)/http"
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
	
	func getCacheFor (url: URL) -> JSON?
	{
		if let fileUrl = getFileUrlFor(convertUrlToFileName(url))
		{
			if let data = try? Data(contentsOf: fileUrl),
				let json = try? parse(allocationStrategy: .single, input: data)
			{
				return (data, json)
			}
		}
		return nil
	}
	
	func setCacheFor (url: URL, json: JSON?) throws
	{
		if let json = json, let fileUrl = getFileUrlFor(convertUrlToFileName(url))
		{
			let data = json.0
			try data.write(to: fileUrl, options: .atomic)
		}
	}
}



class JSONURLTask
{
	static let shared = JSONURLTask()
	
	let logCache = LogNull(clazz: JSONURLTask.self)
	let log = Log(clazz: JSONURLTask.self)
	
	let worker : IOURLTask = JSONURLTaskFoundation()
	
	func dataTaskSync (with url: URL, useCache: Bool) -> (json: JSON?, error: Error?, wasCached: Bool)
	{
		if useCache, let json = WebCache.instance.getCacheFor(url: url)
		{
			logCache.print { "url cache of \(url.absoluteString)" }
			return (json, nil, true)
		}
		
		let sem = DispatchSemaphore(value: 0)
		var result : (JSON?, Error?, Bool)! = nil
		
		let task = worker.dataTask(with: url) {
			json, error in
			
			result = (json, error, false)
			sem.signal();
		}
		
		task.resume()
		sem.wait()
		
		log.print { "web read of \(url.absoluteString)" }

		if useCache
		{
			try? WebCache.instance.setCacheFor(url: url, json: result.0)
		}
		
		return result
	}

	var sleepSeconds = 30.0
	var requestDelaySeconds = 0.25
	var lastRequestSecond : TimeInterval = 0
	
	func sleep(_ delay : Double)
	{
		let usecond : Double = 1000000
		usleep(UInt32(delay * usecond))
	}

	func dataTaskSyncRateLimitRetry (with url: URL, useCache: Bool) -> (json: JSON?, error: Error?, wasCached: Bool)
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

				if !worker.sessionManager().cycle()
				{
					log.print { "could not cycle, instead sleeping." }
					log.print { "sleeping for \(sleepSeconds)" }
					sleep(sleepSeconds)

					if alreadySlept
					{
						sleepSeconds *= 1.1
					}
					
					if !alreadySlept
					{
						 requestDelaySeconds *= 1.02
						 log.print { "increased sleepSeconds to \(sleepSeconds) requestDelaySeconds \(requestDelaySeconds)" }
					}
				
					alreadySlept = true
				}
			}
		} while true
	}

}

