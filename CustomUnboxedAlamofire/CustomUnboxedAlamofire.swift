//
//  CustomUnboxedAlamofire.swift
//  CustomUnboxedAlamofire
//
//  Created by Shun Nakahara on 11/4/16.
//  Copyright © 2016 KITSUKI Inc. All rights reserved.
//

import Foundation
import Alamofire
import Unbox


public protocol CustomUnboxed {
    init(unboxer: Unbox.Unboxer)
}

// MARK: - Requests

extension DataRequest {
    
    /**
     Adds a handler to be called once the request has finished.
     
     - parameter queue: The queue on which the completion handler is dispatched.
     - parameter keyPath: The key path where object mapping should be performed.
     - parameter options: The JSON serialization reading options. `.allowFragments` by default.
     - parameter completionHandler: A closure to be executed once the request has finished and the data has been mapped by Custom Unbox.
     
     - returns: The request.
     */
    @discardableResult
    public func responseObject<T: CustomUnboxed>(queue: DispatchQueue? = nil, keyPath: String? = nil, options: JSONSerialization.ReadingOptions = .allowFragments, completionHandler: @escaping (DataResponse<T>) -> Void) -> Self {
        return response(queue: queue, responseSerializer: DataRequest.UnboxObjectSerializer(options, keyPath: keyPath), completionHandler: completionHandler)
    }
    
    /**
     Adds a handler to be called once the request has finished.
     
     - parameter queue: The queue on which the completion handler is dispatched.
     - parameter keyPath: The key path where object mapping should be performed.
     - parameter options: The JSON serialization reading options. `.allowFragments` by default.
     - parameter completionHandler: A closure to be executed once the request has finished and the data has been mapped by Custom Unbox.
     
     - returns: The request.
     */
    @discardableResult
    public func responseArray<T: CustomUnboxed>(queue: DispatchQueue? = nil, keyPath: String? = nil, options: JSONSerialization.ReadingOptions = .allowFragments, completionHandler: @escaping (DataResponse<[T]>) -> Void) -> Self {
        return response(queue: queue, responseSerializer: DataRequest.UnboxArraySerializer(options, keyPath: keyPath), completionHandler: completionHandler)
    }
}

// MARK: - Serializers

private extension Request {
    
    static func UnboxObjectSerializer<T: CustomUnboxed>(_ options: JSONSerialization.ReadingOptions, keyPath: String?) -> DataResponseSerializer<T>  {
        return DataResponseSerializer { request, response, data, error in
            if let error = error {
                return .failure(error)
            }
            
            let JSONResponseSerializer = DataRequest.jsonResponseSerializer(options: .allowFragments)
            let result = JSONResponseSerializer.serializeResponse(request, response, data, error)
            
            let jsonCandidate: Any?
            if let keyPath = keyPath , !keyPath.isEmpty {
                jsonCandidate = (result.value as AnyObject?)?.value(forKeyPath: keyPath)
            } else {
                jsonCandidate = result.value
            }
            
            guard let json = jsonCandidate as? UnboxableDictionary else {
                return .failure(CustomUnboxedError(description: "Invalid data."))
            }
            
            do {
                return .success(try Unboxer.performCustomUnboxing(dictionary: json, closure: { (unboxer) -> T? in
                    return T(unboxer: unboxer)
                }))
            } catch let unboxError as UnboxError {
                return .failure(CustomUnboxedError(description: unboxError.description))
            } catch let error as NSError {
                return .failure(error)
            }
        }
    }
    
    static func UnboxArraySerializer<T: CustomUnboxed>(_ options: JSONSerialization.ReadingOptions, keyPath: String?) -> DataResponseSerializer<[T]> {
        return DataResponseSerializer { request, response, data, error in
            if let error = error {
                return .failure(error)
            }
            
            let JSONResponseSerializer = DataRequest.jsonResponseSerializer(options: .allowFragments)
            let result = JSONResponseSerializer.serializeResponse(request, response, data, error)
            
            let jsonCandidate: Any?
            if let keyPath = keyPath , !keyPath.isEmpty {
                jsonCandidate = (result.value as AnyObject?)?.value(forKeyPath: keyPath)
            } else {
                jsonCandidate = result.value
            }
            
            guard let json = jsonCandidate as? [UnboxableDictionary] else {
                return .failure(CustomUnboxedError(description: "Invalid data."))
            }
            
            do {
                return .success(try map(json))
            } catch let unboxError as UnboxError {
                return .failure(CustomUnboxedError(description: unboxError.description))
            } catch let error as NSError {
                return .failure(error)
            }
        }
    }
}

// MARK: - Helpers

public struct CustomUnboxedError: Error, CustomStringConvertible {
    
    public let description: String
}

private func map<T: CustomUnboxed>(_ objects: [UnboxableDictionary]) throws -> [T] {
    
    return try objects.reduce([T]()) { container, rawValue in
        let value: T = try Unboxer.performCustomUnboxing(dictionary: rawValue, closure: { (unboxer) -> T? in
            return T(unboxer: unboxer)
        })
        return container + [value]
    }
}
