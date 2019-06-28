//
//  Algorithm.swift
//  altcoin_simulator
//
//  Created by Timothy Prepscius on 6/28/19.
//

import Foundation

// https://stackoverflow.com/questions/31904396/swift-binary-search-for-standard-array

extension RandomAccessCollection {

    func binarySearch(predicate: (Iterator.Element) -> Bool) -> Index {
        var low = startIndex
        var high = endIndex
        while low != high {
            let mid = index(low, offsetBy: distance(from: low, to: high)/2)
            if predicate(self[mid]) {
                low = index(after: mid)
            } else {
                high = mid
            }
        }
        return low
    }
}

//Example usage:
//(0 ..< 778).binarySearch { $0 < 145 } // 145

