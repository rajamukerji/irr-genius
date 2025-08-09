//
//  GrowthPoint.swift
//  IRR Genius
//
//  Created by Raja Mukerji on 7/1/25.
//

import Foundation

struct GrowthPoint: Identifiable, Codable {
    let month: Int
    let value: Double
    var id: Int { month }
}
