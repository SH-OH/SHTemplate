//
//  NetworkService.swift
//  SHTemplate
//
//  Created by Oh Sangho on 11/13/23.
//

import Foundation
import Moya
import RxMoya
import RxSwift

public final class NetworkService<T: BaseTargetType> {
	
	private let provider: MoyaProvider<T>
	
	private lazy var decoder: JSONDecoder = {
		let decoder: JSONDecoder = .init()
		decoder.keyDecodingStrategy = .convertFromSnakeCase
		
		return decoder
	}()
	private let concurrentQueue: DispatchQueue = .init(
		label: "network.concurrent",
		qos: .default,
		attributes: .concurrent
	)
	
	private var cancellableToken: Cancellable?
	
	init(stubClosure: @escaping MoyaProvider<T>.StubClosure) {
		self.provider = Self.createProvider(stubClosure: stubClosure)
	}

	init(plugins: [PluginType] = []) {
		self.provider = Self.createProvider(plugins: plugins)
	}
	
	func request<D: Decodable>(
		_ modelType: D.Type,
		target: T
	) -> Single<D> {
		Single.create { [weak self] observer in
			guard let self else { return Disposables.create() }
			
			self.cancellableToken = self.provider.request(target, callbackQueue: self.concurrentQueue) { result in
				switch result {
				case let .success(response):
					observer(.success(response))
				case let .failure(error):
					observer(.failure(error))
				}
			}
			
			return Disposables.create {
				self.cancellableToken?.cancel()
			}
		}
		.map(modelType, using: decoder)
	}
	
	func cancel() {
		concurrentQueue.async { [weak self] in
			self?.cancellableToken?.cancel()
			self?.cancellableToken = nil
		}
	}
	
	private static func createProvider(
		plugins: [PluginType] = [],
		stubClosure: @escaping MoyaProvider<T>.StubClosure = MoyaProvider.neverStub
	) -> MoyaProvider<T> {
		var plugins = plugins
		plugins.append(NetworkLoggerPlugin())
		let provider = MoyaProvider<T>.init(stubClosure: stubClosure, plugins: plugins)
		
		return provider
	}
}
