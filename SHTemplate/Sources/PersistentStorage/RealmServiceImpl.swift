//
//  RealmServiceImpl.swift
//  SHTemplate
//
//  Created by Oh Sangho on 11/13/23.
//

import Foundation
import RxSwift
import Realm
import RealmSwift

enum RealmServiceError: Error {
	
	case updateFailed(Error)
	case deleteFailed(Error)
}

final class RealmServiceImpl: RealmService {
	
	private let realm: Realm
	
	init(
		configuration: Realm.Configuration
	) {
		guard let realm: Realm = try? Realm(configuration: configuration) else {
			fatalError("Cannot instantiate realm with configuration - \(configuration)")
		}
		
		self.realm = realm
		
		print("=================================================")
		print("realm file url : \(String(describing: configuration.fileURL))")
		print("=================================================")
	}
	
	func findAll<O: Object>() -> Single<[O]> {
		Single.create { [weak self] observer in
			guard let self else { return Disposables.create() }
			
			let objects = self.realm
				.objects(O.self)
			
			observer(.success(objects.map({ $0 })))
			
			return Disposables.create()
		}
		.subscribe(on: MainScheduler.instance)
	}
	
	func find<O: Object>(
		with isIncluded: @escaping (O) -> Bool,
		sortDescriptors: ((O, O) -> Bool)? = nil
	) -> Single<[O]> {
		Single.create { [weak self] observer in
			guard let self else { return Disposables.create() }
			
			let objects = self.realm
				.objects(O.self)
				.filter(isIncluded)
			
			if let sortDescriptors {
				let sorted = objects.sorted(by: sortDescriptors)
				
				observer(.success(sorted.map({ $0 })))
			}
			
			observer(.success(objects.map({ $0 })))
			
			return Disposables.create()
		}
		.subscribe(on: MainScheduler.instance)
	}
	
	func update<O: Object>(
		_ object: O,
		updateHandler: ((O) -> Void)? = nil
	) -> Single<O> {
		Single.create { [weak self] observer in
			guard let self else { return Disposables.create() }
			
			let realm = realm
			
			realm.writeAsync({
				updateHandler?(object)
				realm.add(object, update: .all)
			}, onComplete: { error in
				if let error {
					observer(.failure(error))
					print(RealmServiceError.updateFailed(error))
				} else {
					observer(.success(object))
					print("RealmService update object : \(object)")
				}
			})
			
			return Disposables.create()
		}
		.subscribe(on: MainScheduler.instance)
	}
	
	func delete<O: Object>(
		_ type: O.Type,
		ids: [Object.ID]
	) -> Single<Void> {
		Single.create { [weak self] observer in
			guard let self else { return Disposables.create() }
			
			let realm = self.realm
			let objects = ids.compactMap({
				realm.object(ofType: O.self, forPrimaryKey: $0)
			})
			
			let test = objects
			
			realm.writeAsync({
				realm.delete(objects)
			}, onComplete: { error in
				if let error {
					observer(.failure(error))
					print(RealmServiceError.deleteFailed(error))
				} else {
					observer(.success(()))
					print("RealmService delete objects : \(objects.customMirror)")
				}
			})
			
			return Disposables.create()
		}
		.subscribe(on: MainScheduler.instance)
	}
}

extension Object: Identifiable {}
extension Object: CustomReflectable {
	
	public var customMirror: Mirror {
		Mirror(
			self,
			children: [
				"id": id,
			]
		)
	}
}
