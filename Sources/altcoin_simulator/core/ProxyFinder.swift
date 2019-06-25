//
//  ProxyFinder.swift
//  altcoin_simulator
//
//  Created by Timothy Prepscius on 6/25/19.
//

import Foundation
import SwiftSoup

class ProxyFinder
{
	typealias Proxy = (url: String, port: Int)
	var proxies = [Proxy]()
	
	static let shared = ProxyFinder()

	init ()
	{
		try? scan()
	}
	
	func clear ()
	{
		proxies.removeAll()
	}
	
	func scan () throws
	{
//		let url = URL(string: "https://www.us-proxy.org/")
		let url = URL(string: "https://free-proxy-list.net/")
		let html = try String(contentsOf: url!, encoding: .utf8)
		let doc: Document = try SwiftSoup.parse(html)
		let trs = try doc.select("tbody > tr")
		
		for (i, tr) in trs.array().enumerated()
		{
			if i > 50
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
		
	}

}
