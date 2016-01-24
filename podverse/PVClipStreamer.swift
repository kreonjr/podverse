//
//  PVClipStreamer.swift
//  podverse
//
//  Created by Mitchell Downey on 1/23/16.
//  Copyright © 2016 Mitchell Downey. All rights reserved.
//

import UIKit
import AVFoundation
import MobileCoreServices

var playFileContext = "playFileContext"

// Extension to receive a response from the URL and access response header information like file size via byte range
extension NSURL {
    var remoteSize: Int64 {
        var contentLength: Int64 = NSURLSessionTransferSizeUnknown
        let request = NSMutableURLRequest(URL: self, cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 30.0);
        request.HTTPMethod = "HEAD";
        request.timeoutInterval = 5;
        let group = dispatch_group_create()
        dispatch_group_enter(group)
        NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
            if let httpResponse = response as? NSHTTPURLResponse {
                if let contentType = httpResponse.allHeaderFields["Content-Length"] as? String {
                    print(contentType)
                }
            }
            contentLength = response?.expectedContentLength ?? NSURLSessionTransferSizeUnknown
            dispatch_group_leave(group)
        }).resume()
        dispatch_group_wait(group, dispatch_time(DISPATCH_TIME_NOW, Int64(5 * NSEC_PER_SEC)))
        return contentLength
    }
}

class PVClipStreamer: NSObject, AVAssetResourceLoaderDelegate, NSURLConnectionDataDelegate {
    
    static let sharedInstance = PVClipStreamer()
    
    var mediaPlayer: AVPlayer?
    var mediaPlayerItems = [AVPlayerItem]()
    var isObserving = false
    var pendingRequests = [AVAssetResourceLoadingRequest]()
    var mediaFileData = NSMutableData()
    var response: NSURLResponse?
    var connection: NSURLConnection?
    
    var episodeDuration: Double!

    var clipStartTimeInSeconds: Double?
    var clipEndTimeInSeconds: Double?
    var startBytesRange: Int?
    var endBytesRange: Int?
    
    var metadataBytesOffset = 0

    
    func streamClip(clip: Clip) {
        // Reset the connection to nil before streaming a new clip
        self.connection = nil
        
        if let mediaURLString = clip.episode.mediaURL {
            
            // Get remote file total bytes
            let remoteFileSize = NSURL(string: mediaURLString)!.remoteSize
            
            // Calculate duration of remote file and use it to determine episode duration in seconds
            let calculateDurationAsset = AVURLAsset(URL: self.mediaURLWithCustomScheme(mediaURLString, scheme: "http"), options: nil)
            episodeDuration = CMTimeGetSeconds(calculateDurationAsset.duration)
            episodeDuration = floor(episodeDuration!)
            
            // NOTE: if a media file has metadata in the beginning, the clip start/end times will be off. The following functions determine the mediadataBytesOffset based on the metadata, and adjusts the start/endByteRanges to include this offset.
            let metadataList = calculateDurationAsset.metadata
            var totalMetaDataBytes = 0
            for item in metadataList {
                if item.commonKey != nil && item.value != nil {
                    if item.commonKey  == "title" {
                        // totalMetaDataBytes += (item.dataValue?.length)!
                    }
                    if item.commonKey   == "type" {
                        // totalMetaDataBytes += (item.dataValue?.length)!
                    }
                    if item.commonKey  == "albumName" {
                        // totalMetaDataBytes += (item.dataValue?.length)!
                    }
                    if item.commonKey   == "artist" {
                        // totalMetaDataBytes += (item.dataValue?.length)!
                    }
                    if item.commonKey  == "artwork" {
                        totalMetaDataBytes += (item.dataValue?.length)!
                    }
                }
            }
            metadataBytesOffset = totalMetaDataBytes
            
            startBytesRange = metadataBytesOffset + Int((Double(clip.startTime) / episodeDuration) * Double(remoteFileSize))
            
            // If clip has a valid end time, then use it to determine the End Byte Range Request value. Else use the full episode file size as the End Byte Range Request value.
            if clip.endTime != 0 {
                endBytesRange = metadataBytesOffset + Int((Double(clip.endTime) / episodeDuration) * Double(remoteFileSize))
            } else {
                endBytesRange = Int(remoteFileSize)
            }
            
            let asset = AVURLAsset(URL: self.mediaURLWithCustomScheme(mediaURLString, scheme: "streaming"), options: nil)
            
            asset.resourceLoader.setDelegate(self, queue: dispatch_get_main_queue())
            self.pendingRequests = []
            let playerItem = AVPlayerItem(asset: asset)
            PVMediaPlayer.sharedInstance.avPlayer = AVPlayer(playerItem: playerItem)
        }
    }

    
    // In order to override the Request header, we need to set a custom scheme
    func mediaURLWithCustomScheme(URLString: String, scheme: String) -> NSURL {
        let url = NSURL(string: URLString)
        let components = NSURLComponents(URL: url!, resolvingAgainstBaseURL: false)!
        components.scheme = scheme
        return components.URL!
    }
    
    func connection(connection: NSURLConnection, didReceiveResponse response: NSURLResponse) {
        self.mediaFileData = NSMutableData()
        self.response = response as! NSHTTPURLResponse
        self.processPendingRequests()
    }
    
    func connection(connection: NSURLConnection, didReceiveData data: NSData) {
        self.mediaFileData.appendData(data)
        self.processPendingRequests()
    }
    
    func connectionDidFinishLoading(connection: NSURLConnection) {
        // do nothing
    }
    
    func processPendingRequests() {
        var requestsCompleted = [AVAssetResourceLoadingRequest]()
        for loadingRequest in self.pendingRequests {
            self.fillInContentInformation(loadingRequest.contentInformationRequest)
            let didRespondCompletely = self.respondWithDataForRequest(loadingRequest.dataRequest!)
            if didRespondCompletely {
                requestsCompleted.append(loadingRequest)
                loadingRequest.finishLoading()
            }
        }
        for requestCompleted in requestsCompleted {
            for (i, pendingRequest) in self.pendingRequests.enumerate() {
                if requestCompleted == pendingRequest {
                    self.pendingRequests.removeAtIndex(i)
                }
            }
        }
    }

    func fillInContentInformation(contentInformationRequest: AVAssetResourceLoadingContentInformationRequest?) {
        if (contentInformationRequest == nil) {
            return
        }
        if (self.response == nil) {
            return
        }
        
        let mimeType = self.response!.MIMEType
        let unmanagedContentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, mimeType!, nil)
        let cfContentType = unmanagedContentType!.takeRetainedValue()
        contentInformationRequest!.contentType = String(cfContentType)
        contentInformationRequest!.byteRangeAccessSupported = true
        contentInformationRequest!.contentLength = self.response!.expectedContentLength
    }
    
    // This offset seems to be related to buffering, and is not where we control the offset for the Byte Range Request headers.
    func respondWithDataForRequest(dataRequest: AVAssetResourceLoadingDataRequest) -> Bool {
        
        var startOffset = dataRequest.requestedOffset
        if dataRequest.currentOffset != 0 {
            startOffset = dataRequest.currentOffset
        }
        
        let mediaFileDataLength = Int64(self.mediaFileData.length)
        if mediaFileDataLength < startOffset {
            return false
        }
        
        let unreadBytes = mediaFileDataLength - startOffset
        
        let numberOfBytesToRespondWith: Int64
        if Int64(dataRequest.requestedLength) > unreadBytes {
            numberOfBytesToRespondWith = unreadBytes
        } else {
            numberOfBytesToRespondWith = Int64(dataRequest.requestedLength)
        }
        dataRequest.respondWithData(self.mediaFileData.subdataWithRange(NSMakeRange(Int(startOffset), Int(numberOfBytesToRespondWith))))
        let endOffset = startOffset + dataRequest.requestedLength
        let didRespondFully = mediaFileDataLength >= endOffset
        return didRespondFully
    }
    
    func resourceLoader(resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        if self.connection == nil {
            let interceptedURL = loadingRequest.request.URL
            let actualURLComponents = NSURLComponents(URL: interceptedURL!, resolvingAgainstBaseURL: false)
            actualURLComponents!.scheme = "http"
            let actualURL = actualURLComponents!.URL!

            var request = NSURLRequest(URL: actualURL)
            
            let mutableRequest = NSMutableURLRequest(URL: actualURL, cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 60)
            mutableRequest.HTTPMethod = "GET"
            let bytesRequestedString = "bytes=" + String(startBytesRange!) + "-" + String(endBytesRange!)
            mutableRequest.addValue(bytesRequestedString, forHTTPHeaderField: "Range")
            request = mutableRequest
            self.connection = NSURLConnection(request: request, delegate: self, startImmediately: false)
            self.connection!.setDelegateQueue(NSOperationQueue.mainQueue())
            self.connection!.start()
        }
        
        self.pendingRequests.append(loadingRequest)
        return true
    }
    
    func resourceLoader(resourceLoader: AVAssetResourceLoader, didCancelLoadingRequest loadingRequest: AVAssetResourceLoadingRequest) {
        for (i, pendingRequest) in self.pendingRequests.enumerate() {
            if pendingRequest == pendingRequests[i] {
                pendingRequests.removeAtIndex(i)
            }
        }
        pendingRequests = []
    }
    
//    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
//        if self.mediaPlayer!.currentItem!.status == AVPlayerItemStatus.ReadyToPlay {
//            if keyPath == "status" {
//                mediaPlayer!.play()
//            }
//        }
//    }
    
}

