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
            contentLength = response?.expectedContentLength ?? NSURLSessionTransferSizeUnknown
            dispatch_group_leave(group)
        }).resume()
        dispatch_group_wait(group, dispatch_time(DISPATCH_TIME_NOW, Int64(5 * NSEC_PER_SEC)))
        return contentLength
    }
}

//
// NOTE - ClipStreamer can only work if the RSS server has the "Accept-Ranges: bytes" header
//

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
        
        guard let mediaURLString = clip.episode.mediaURL else {
            return
        }
            
        // Get remote file total bytes
        guard let remoteFileSize = NSURL(string: mediaURLString)?.remoteSize else {
            return
        }
        
        guard let calcCustomMediaURL = self.mediaURLWithCustomScheme(mediaURLString, scheme: "http") else {
            return
        }

        let calculateDurationAsset = AVURLAsset(URL: calcCustomMediaURL, options: nil)
        
        // If an episode.duration is availabe then use it. Else, calculate the episode duration.
//        if clip.episode.duration != nil {
//            episodeDuration = Double(clip.episode.duration!)
//        } else {
            episodeDuration = CMTimeGetSeconds(calculateDurationAsset.duration)
            episodeDuration = floor(episodeDuration!)
//        }
        
        // Since the calculated episodeDuration is sometimes different than the duration of the episode according to its RSS feed (see NPR TED Radio Hour; NPR Fresh Air; NPR etc.), override the episode.duration with the calculated episodeDuration and save
//            clip.episode.duration = episodeDuration
//            CoreDataHelper.saveCoreData(nil)
        
        // NOTE: if a media file has metadata in the beginning, the clip start/end times will be off. The following functions determine the mediadataBytesOffset based on the metadata, and adjusts the start/endByteRanges to include this offset.
        let metadataList = calculateDurationAsset.metadata
        var totalMetaDataBytes = 0
        for item in metadataList {
//                print("start over")
//                print(item.key)
//                print(item.keySpace)
//                print(item.commonKey)
//                print(item.value)
//                print(item.dataValue)
//                print(item.extraAttributes)
            if let dataValue = item.dataValue {
                totalMetaDataBytes += dataValue.length
            }
            if item.commonKey != nil && item.value != nil {
//                    if item.commonKey  == "title" {
//                        if let dataValue = item.dataValue {
//                            totalMetaDataBytes += dataValue.length
//                        }
//                    }
//                    if item.commonKey   == "type" {
//                        if let dataValue = item.dataValue {
//                            totalMetaDataBytes += dataValue.length
//                        }
//                    }
//                    if item.commonKey  == "albumName" {
//                        if let dataValue = item.dataValue {
//                            totalMetaDataBytes += dataValue.length
//                        }
//                    }
//                    if item.commonKey   == "artist" {
//                        if let dataValue = item.dataValue {
//                            totalMetaDataBytes += dataValue.length
//                        }
//                    }
//                    if item.commonKey  == "artwork" {
//                        if let dataValue = item.dataValue {
//                            totalMetaDataBytes += dataValue.length
//                        }
//                    }
            }
        }
        metadataBytesOffset = totalMetaDataBytes
        
        // TODO: can we refine the startBytesRange and endBytesRange?
        startBytesRange = metadataBytesOffset + Int((Double(clip.startTime) / episodeDuration) * Double(remoteFileSize - metadataBytesOffset))
        
        // If clip has a valid end time, then use it to determine the End Byte Range Request value. Else use the full episode file size as the End Byte Range Request value.
        if let endTime = clip.endTime {
            endBytesRange = metadataBytesOffset + Int((Double(endTime) / episodeDuration) * Double(remoteFileSize - metadataBytesOffset))
        } else {
            endBytesRange = Int(remoteFileSize)
        }
        
        guard let customSchemeMediaURL = self.mediaURLWithCustomScheme(mediaURLString, scheme: "streaming") else {
            return
        }
        
        let asset = AVURLAsset(URL: customSchemeMediaURL, options: nil)
        
        asset.resourceLoader.setDelegate(self, queue: dispatch_get_main_queue())
        self.pendingRequests = []
        
        let playerItem = AVPlayerItem(asset: asset)
        PVMediaPlayer.sharedInstance.avPlayer = AVPlayer(playerItem: playerItem)

    }

    
    // In order to override the Request header, we need to set a custom scheme
    func mediaURLWithCustomScheme(URLString: String, scheme: String) -> NSURL? {
        guard let url = NSURL(string: URLString), let components = NSURLComponents(URL: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        components.scheme = scheme
        return components.URL
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
            guard let interceptedURL = loadingRequest.request.URL else {
                return false
            }
            let actualURLComponents = NSURLComponents(URL: interceptedURL, resolvingAgainstBaseURL: false)
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

