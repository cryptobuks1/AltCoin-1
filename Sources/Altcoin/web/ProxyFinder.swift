//
//  ProxyFinder.swift
//  altcoin_simulator
//
//  Created by Timothy Prepscius on 6/25/19.
//

import Foundation
import SwiftSoup

public class ProxyFinder
{
	public typealias Proxy = (url: String, port: Int)
	
	var urlStrings = ["https://www.sslproxies.org/", "https://www.us-proxy.org/", "https://free-proxy-list.net/"]
	var urlStringIndex = 0
	
	var proxies = [Proxy]()
	var repeater : RepeatWithInterval? = nil
	
	static let shared = ProxyFinder()

	public init ()
	{
//		try? scan()
		
//		repeater = repeatWithInterval(60.0) {
//			try? self.scan()
//		}
	}
	
	public func getRandomProxy () -> Proxy?
	{
		objc_sync_enter(self)
    	defer { objc_sync_exit(self) }

		let proxy = proxies.popLast()
		if proxies.isEmpty
		{
			try? scan()
		}

		return proxy
//		return proxies.randomElement()
	}
	
	func clear ()
	{
		proxies.removeAll()
	}
	
	func scan () throws
	{
//		objc_sync_enter(self)
//    	defer { objc_sync_exit(self) }

		proxies.removeAll()

		let url = URL(string: urlStrings[urlStringIndex % urlStrings.count])
		urlStringIndex += 1
		
		let html = try String(contentsOf: url!, encoding: .utf8)
		let doc: Document = try SwiftSoup.parse(html)
		let trs = try doc.select("tbody > tr")
		
		for (i, tr) in trs.array().enumerated()
		{
			if i > 100
			{
				break
			}
			
			if let tds = try? tr.select("td").array(),
				let ip = try? tds[0].text(),
				let port = try? tds[1].text(),
				let p = Int(port)
			{
				print("scan found \(ip):\(p)")
				proxies.append((ip, p))
			}
		}
		
		proxies = proxies.reversed()
		
	}

}
