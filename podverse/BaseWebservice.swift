//
//  BaseWebservice.swift
//  podverse
//
//  Created by Kreon on 1/23/16.
//  Copyright © 2016 Mitchell Downey. All rights reserved.
//
import Foundation
import Alamofire

let BASE_URL = "https://podverse.fm/"
let TEST_URL = "https://podverse.fm/"


public enum HTTP_METHOD {
    case METHOD_POST
    case METHOD_GET
    case METHOD_PUT
    case METHOD_PATCH
    case METHOD_DELETE
    case METHOD_OPTIONS
    case METHOD_HEAD
    case METHOD_TRACE
    case METHOD_CONNECT
}

public enum PARAM_ENCODING {
    case PARAM_ENCODING_URL
    case PARAM_ENCODING_URLEncodedInURL
    case PARAM_ENCODING_JSON
}

public struct ERRORCODES {
    static let ERROR_REQUEST_CREATION_ERROR = 485
    static let ERROR_BAD_HTTP_RESPONSE = 489
    static let ERROR_BAD_RESPONSE_VALUE = 490
}

public class WebService {
    
    private let CompletionBlock:(responseDictionary:Dictionary<String, AnyObject>) -> Void
    private let ErrorBlock:(error:NSError?) -> Void
    
    private let baseURL:String = TEST_URL
    
    private var httpMethod:HTTP_METHOD = .METHOD_POST
    private var paramEncoding:PARAM_ENCODING = .PARAM_ENCODING_JSON
    private var params:Dictionary<String, AnyObject> = Dictionary<String, AnyObject>()
    private var headers:Dictionary<String, String>!
    public var name:String
    
    private var minResponseCode = 200
    private var maxResponseCode = 399
    private var request:Alamofire.Request?
    private static let WEBSERVICE_ERROR_DOMAIN = "Webservice"
    public static let ERROR_KEY = "error"
    public static let VALUE_KEY = "responseValue"
    private var JSONReadingOptions: NSJSONReadingOptions?
    
    init(name:String, completionBlock:(response:Dictionary<String, AnyObject>) -> Void, errorBlock:(error:NSError?) -> Void) {
        self.name = name
        CompletionBlock = completionBlock
        ErrorBlock = errorBlock
    }
    
    public func setHttpMethod(method:HTTP_METHOD) {
        httpMethod = method
    }
    
    public func setParameterEncoding(encoding: PARAM_ENCODING) {
        paramEncoding = encoding
    }
    
    public func setResponseCodeSuccessValue(min:Int, max:Int) {
        if max > min {
            minResponseCode = min
            maxResponseCode = max
        }
        else {
            minResponseCode = max
            maxResponseCode = min
        }
    }
    
    public func call() {
        var alamoMethod = Method.GET
        
        switch httpMethod {
        case .METHOD_POST:
            alamoMethod = .POST
        case .METHOD_GET:
            alamoMethod = .GET
        case .METHOD_PUT:
            alamoMethod = .PUT
        case .METHOD_PATCH:
            alamoMethod = .PATCH
        case .METHOD_DELETE:
            alamoMethod = .DELETE
        case .METHOD_OPTIONS:
            alamoMethod = .OPTIONS
        case .METHOD_HEAD:
            alamoMethod = .HEAD
        case .METHOD_TRACE:
            alamoMethod = .TRACE
        case .METHOD_CONNECT:
            alamoMethod = .CONNECT
        }
        
        if httpMethod == .METHOD_PUT || httpMethod == .METHOD_POST || httpMethod == .METHOD_GET {
            addHeaderWithKey("Authorization", value: Constants.SERVER_AUTHORIZATION_KEY)
        }
        
        if .METHOD_GET == httpMethod && .PARAM_ENCODING_JSON == paramEncoding {
            paramEncoding = .PARAM_ENCODING_URL
        }
        
        var alamoEncoding = ParameterEncoding.JSON
        
        switch paramEncoding {
        case .PARAM_ENCODING_JSON:
            alamoEncoding = .JSON
        case .PARAM_ENCODING_URL:
            alamoEncoding = .URL
        case .PARAM_ENCODING_URLEncodedInURL:
            alamoEncoding = .URLEncodedInURL
        }
        
        let errorBlock = ErrorBlock
        let completionBlock = CompletionBlock
        request = Alamofire.request(alamoMethod, baseURL + name, parameters: params, encoding: alamoEncoding, headers: headers)
        
        guard let mRequest = request else {
            let requestCreationError = NSError(domain: WebService.WEBSERVICE_ERROR_DOMAIN, code: ERRORCODES.ERROR_REQUEST_CREATION_ERROR, userInfo: [WebService.ERROR_KEY: NSLocalizedString("Unable to instantiate network request.", comment: "Unable to instantiate network request.")])
            errorBlock(error:requestCreationError)
            return
        }
        
        let minResponse = minResponseCode
        let maxResponse = maxResponseCode
        
        mRequest.responseJSON(options: self.JSONReadingOptions ?? .AllowFragments, completionHandler: {response  in
            if response.result.isSuccess {
                guard let rawResponse = response.response else {
                    errorBlock(error: NSError(domain: WebService.WEBSERVICE_ERROR_DOMAIN, code: ERRORCODES.ERROR_BAD_HTTP_RESPONSE, userInfo: [WebService.ERROR_KEY: NSLocalizedString("Invalid Http Response.", comment: "Invalid Http Response.")]));
                    return
                }
                
                if rawResponse.statusCode >= minResponse && rawResponse.statusCode <= maxResponse {
                    if let dictionaryResponse = response.result.value as? Dictionary<String, AnyObject> {
                        completionBlock(responseDictionary: dictionaryResponse)
                    }
                    else {
                        errorBlock(error: NSError(domain: WebService.WEBSERVICE_ERROR_DOMAIN, code: ERRORCODES.ERROR_BAD_RESPONSE_VALUE, userInfo: [WebService.ERROR_KEY: NSLocalizedString("Invalid Response Value.", comment: "Invalid Response Value.")]));
                    }
                }
                else {
                    var userInfo:Dictionary<String,AnyObject> = [WebService.ERROR_KEY: NSHTTPURLResponse.localizedStringForStatusCode(rawResponse.statusCode)]
                    if let value = response.result.value {
                        userInfo[WebService.VALUE_KEY] = value
                    }
                    
                    errorBlock(error: NSError(domain: WebService.WEBSERVICE_ERROR_DOMAIN, code: rawResponse.statusCode, userInfo: userInfo));
                }
            }
            else {
                errorBlock(error:response.result.error);
            }
        })
    }
    
    public func cancel() {
        if let Request = request {
            Request.cancel()
        }
    }
    
    public final func addParamWithKey(key:String, value:AnyObject) {
        params[key] = value;
    }
    
    public final func addHeaderWithKey(key:String, value:String) {
        if headers == nil {
            headers = Dictionary<String, String>()
        }
        
        headers[key] = value
    }
    
    public final func setJSONReadingOptions(options: NSJSONReadingOptions) {
        self.JSONReadingOptions = options
    }
}