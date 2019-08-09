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

let timeOutConnect = 3
let timeoutResource = 6

class WebCache
{
	static let instance = WebCache()

	class S_ {
		static let
			folderName = "\(S.documents)/http"
	}
	
	private func obsolete_convertUrlToFileName (_ url : URL) -> String
	{
		let s = url.absoluteString
		return s.replacingOccurrences(of: ":", with: "=").replacingOccurrences(of: "/", with: "#")
	}


	private func obsolete_getDataFolderUrl () -> URL?
	{
		if var documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
		{
			documentsURL.appendPathComponent(S_.folderName)
			return documentsURL
		}
		
		return nil
	}
	
	private func transferObsoleteFile(_ url: URL)
	{
		objc_sync_enter(self)
    	defer { objc_sync_exit(self) }
	
	
	
		let fileName = obsolete_convertUrlToFileName(url)
		guard let folder = obsolete_getDataFolderUrl() else { return }
		let oldFilePath = folder.path + "/" + fileName
		let oldFileUrl = folder.appendingPathComponent(fileName)
		guard FileManager.default.fileExists(atPath: oldFilePath) else { return }

		guard let newFileUrl = getDataFileUrl(url) else { return }
		try? FileManager.default.createDirectory(at: newFileUrl.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
		
		do {
			try FileManager.default.moveItem(at: oldFileUrl, to: newFileUrl)
			print("transfered \(oldFileUrl) to \(newFileUrl)")
		}
		catch
		{
			print(error)
		}
	}

	init()
	{
	}
	
	private func getDataFileUrl (_ url: URL) -> URL?
	{
		if var documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
		{
			documentsURL.appendPathComponent(S_.folderName, isDirectory: true)
			documentsURL.appendPathComponent(url.host!, isDirectory: true)
			
			var relativePath = url.relativePath.substring(from: 1)
			let isDirectory = url.absoluteString.suffix(1) == "/"
			isDirectory ? relativePath.append("/_") : nil
			documentsURL.appendPathComponent(relativePath, isDirectory: false)
			return documentsURL
		}
		
		return nil
	}
	

	func getCacheFor (url: URL) -> JSON?
	{
		return autoreleasepool {
			transferObsoleteFile(url)
			
			if let fileUrl = getDataFileUrl(url)
			{
				if let data = try? Data(contentsOf: fileUrl),
					let json = try? parse(allocationStrategy: .single, input: data)
				{
					return (data, json)
				}
				
				return nil
			}
			return nil
		}
	}
	
	func setCacheFor (url: URL, json: JSON?) throws
	{
		try autoreleasepool {
			if let json = json, let fileUrl = getDataFileUrl(url)
			{
				try? FileManager.default.createDirectory(at: fileUrl.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)

				let data = json.0
				try data.write(to: fileUrl, options: .atomic)
			}
		}
	}
}



class JSONURLTask
{
	static let shared = JSONURLTask()
	
	let logCache = LogNull(clazz: JSONURLTask.self)
	let log = Log(clazz: JSONURLTask.self)
	
	let worker : IOURLTask = JSONURLTaskNIO()
	
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

