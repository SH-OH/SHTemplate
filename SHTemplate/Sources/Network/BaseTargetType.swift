//
//  BaseTargetType.swift
//  SHTemplate
//
//  Created by Oh Sangho on 11/13/23.
//

import Foundation
import Moya

protocol BaseTargetType: TargetType {}

extension BaseTargetType {
	
	var validationType: ValidationType { .successAndRedirectCodes }
	var url: URL? { URL(string: path, relativeTo: baseURL) }
	
	func getSample(_ fileName: String, ext: String = "json") -> Data {
		guard let url = Bundle.main.url(forResource: fileName, withExtension: ext) else {
			return .init()
		}
		
		do {
			let data = try Data(contentsOf: url)
			
			return data
		} catch {
			print("Failed to load sample data \(fileName) - \(error)")
			
			return .init()
		}
	}
}
