//
//  DownloadFileGoogleDrive.swift
//  AltCoin
//
//  Created by Timothy Prepscius on 8/10/19.
//

import Foundation
import SwiftSoup
import PerfectCURL

// google- they are the kmart of the internet- and .... "KMart sucks"
public func downloadFromGoogleDrive(_ url: URL, destination: URL) -> Bool
{
	var succeeded = false

	class ShouldBeACallBack : NSObject, URLSessionDelegate, URLSessionDownloadDelegate, URLSessionTaskDelegate {
		public var sem = DispatchSemaphore(value: 0)
		
		public var destination: URL? = nil
		public var error: Error? = nil
		
		var logging = false
		var downloadCount = 0

		public func urlSession(_ session: URLSession,
			downloadTask: URLSessionDownloadTask,
			didWriteData bytesWritten: Int64,
			totalBytesWritten: Int64,
			totalBytesExpectedToWrite: Int64)
		{
			guard logging else { return }
			
			let mb = Double(1024 * 1024)
			let written = Double(totalBytesWritten)/mb
			let expected = Double(totalBytesExpectedToWrite)/mb
			
			let url = downloadTask.currentRequest?.url?.lastPathComponent ?? "unknown"
			let writtenS = String(format:"%.2f", written)
			let expectedS = String(format:"%.2f", expected)
			print("\r\t\(url)\t\(writtenS) / \(expectedS) (mb)                    ", terminator: "")
		}

		func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL)
		{
			self.destination = location
			logging ? print("") : nil
			sem.signal()
		}

		func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?)
		{
			if error != nil
			{
				logging ? print("") : nil
				self.error = error
				sem.signal()
			}
		}
		
		func reset ()
		{
			destination = nil
			error = nil
			sem = DispatchSemaphore(value: 0)
		}
		
		func wait (for task: URLSessionDownloadTask)
		{
			reset()
			task.resume()
			sem.wait()
		}
	}
	
	let delegate = ShouldBeACallBack()
	let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)

	let task = session.downloadTask(with: url)
	delegate.wait(for: task)
	
	print("Finished downloading google drive block html \(delegate.destination?.absoluteString ?? "error")")

	if let file = delegate.destination,
		let html = try? String(contentsOf: file, encoding: .utf8),
		let doc: Document = try? SwiftSoup.parse(html),
		let link = try? doc.getElementById("uc-download-link")?.attr("href"),
		let url = URL(string: link, relativeTo: url)
	{
		print(url.absoluteString)

		print("Starting download")
		let task = session.downloadTask(with: url)
		delegate.logging = true
		delegate.wait(for: task)
	
		do
		{
			if let error = delegate.error {
				throw error
			}
			if let location = delegate.destination {
				try? FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
				try FileManager.default.moveItem(at: location, to: destination.appendingPathExtension("gz"))
				
				succeeded = true
			}
		}
		catch
		{
			print(error)
		}
	}

	return succeeded
}
