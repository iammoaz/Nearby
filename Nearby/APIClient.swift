//
//  APIClient.swift
//  Nearby
//
//  Created by Muhammad Moaz on 10/06/2016.
//  Copyright © 2016 Muhammad Moaz. All rights reserved.
//

import UIKit

public let APINetworkingErrorDomain = "com.moaz.Nearby.NetworkingError"

public let MissingHTTPResponseError: Int = 10
public let UnexpectedHTTPResponseError: Int = 20

protocol JSONDecodable {
    init?(JSON: [String: AnyObject])
}

protocol Endpoint {
    var baseURL: String { get }
    var path: String { get }
    var parameters: [String: AnyObject] { get }
}

extension Endpoint {
    var queryComponents: [NSURLQueryItem] {
        var components = [NSURLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = NSURLQueryItem(name: key, value: "\(value)")
            components.append(queryItem)
        }
        
        return components
    }
    
    var request: NSURLRequest {
        let components = NSURLComponents(string: baseURL)!
        components.path = path
        components.queryItems = queryComponents
        
        guard let url = components.URL else {
            return NSURLRequest(URL: NSURL(string: baseURL)!)
        }
        
        return NSURLRequest(URL: url)
    }
}

typealias JSON = [String: AnyObject]
typealias JSONCompletion = (JSON?, NSHTTPURLResponse?, NSError?) -> Void
typealias JSONTask = NSURLSessionDataTask

enum APIResult<T> {
    case Success(T)
    case Failure(ErrorType)
}

protocol APIClient {
    var configuration: NSURLSessionConfiguration { get }
    var session: NSURLSession { get }
    
    func JSONTaskWithRequest(request: NSURLRequest, completion: JSONCompletion) -> JSONTask
    func fetch<T: JSONDecodable>(request: NSURLRequest, parse: JSON -> T?, completion: APIResult<T> -> Void)
}

extension APIClient {
    func JSONTaskWithRequest(request: NSURLRequest, completion: JSONCompletion) -> JSONTask {
        let task = session.dataTaskWithRequest(request) { data, response, error in
            
            guard let HTTPResponse = response as? NSHTTPURLResponse else {
                let userInfo = [NSLocalizedDescriptionKey: NSLocalizedString("Missing HTTP Response", comment: "")]
                let error = NSError(domain: APINetworkingErrorDomain, code: MissingHTTPResponseError, userInfo: userInfo)
                completion(nil, nil, error)
                return
            }
            
            if data == nil {
                if let error = error {
                    completion(nil, HTTPResponse, error)
                }
            } else {
                switch HTTPResponse.statusCode {
                case 200:
                    
                    do {
                        let json = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as? [String: AnyObject]
                        completion(json, HTTPResponse, error)
                        
                    } catch let error as NSError {
                        completion(nil, HTTPResponse, error)
                    }
                    
                default:
                    print("Recieved HTTP Response: \(HTTPResponse.statusCode), which was not handled")
                }
            }
        }
        
        return task
    }
    
    func fetch<T>(request: NSURLRequest, parse: JSON -> T?, completion: APIResult<T> -> Void) {
        let task = JSONTaskWithRequest(request) { json, response, error in
            
            dispatch_async(dispatch_get_main_queue()) {
                guard let json = json else {
                    if let error = error {
                        completion(.Failure(error))
                        
                    } else {
                        // TODO: Implement error handling
                    }
                    
                    return
                }
                
                if let resource = parse(json) {
                    completion(.Success(resource))
                    
                } else {
                    let error = NSError(domain: APINetworkingErrorDomain, code: UnexpectedHTTPResponseError, userInfo: nil)
                    completion(.Failure(error))
                }
            }
        }
        
        task.resume()
    }
    
    func fetch<T: JSONDecodable>(endpoint: Endpoint, parse: JSON -> [T]?, completion: APIResult<[T]> -> Void) {
        let request = endpoint.request
        let task = JSONTaskWithRequest(request) { json, response, error in
            dispatch_async(dispatch_get_main_queue()) {
                guard let json = json else {
                    if let error = error {
                        completion(.Failure(error))
                        
                    } else {
                        // TODO: Implement error handling
                    }
                    
                    return
                }
                
                if let resource = parse(json) {
                    completion(.Success(resource))
                    
                } else {
                    let error = NSError(domain: APINetworkingErrorDomain, code: UnexpectedHTTPResponseError, userInfo: nil)
                    completion(.Failure(error))
                }
            }
        }
        
        task.resume()
    }
}



