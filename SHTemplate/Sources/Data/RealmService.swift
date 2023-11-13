//
//  RealmService.swift
//  SHTemplate
//
//  Created by Oh Sangho on 11/13/23.
//

import Foundation
import RxSwift
import RealmSwift

protocol RealmService {
	
	// 모든 아이템 검색하기.
	func findAll<O: Object>() -> Single<[O]>
	// 특정 아이템 검색하기.
	/// isIncluded: 포함된 property 비교해서 검색.
	/// sortDescriptors: 포함된 property로 정렬.
	func find<O: Object>(
		with isIncluded: @escaping (O) -> Bool,
		sortDescriptors: ((O, O) -> Bool)?
	) -> Single<[O]>
	// object를 업데이트하기. (동일 PK Item이 없으면 추가).
	func update<O: Object>(
		_ object: O,
		updateHandler: ((O) -> Void)?
	) -> Single<O>
	// object의 IDs로 모두 찾아서 삭제.
	func delete<O: Object>(
		_ type: O.Type,
		ids: [Object.ID]
	) -> Single<Void>
}
