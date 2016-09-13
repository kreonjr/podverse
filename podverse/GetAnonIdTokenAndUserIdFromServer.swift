//
//  GetAnonIdTokenAndUserIdFromServer
//  podverse
//

import UIKit

class GetAnonIdTokenAndUserIdFromServer:WebService {
    internal init(completionBlock: (response: AnyObject) -> Void, errorBlock: (error: NSError?) -> Void) {
        super.init(name:"auth/anonLogin", completionBlock: completionBlock, errorBlock: errorBlock)
        
        setHttpMethod(.METHOD_POST)
    }
}