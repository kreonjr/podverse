//
//  Playlist.swift
//

import Foundation

class Playlist {
    var playlistItems:[Dictionary<String,AnyObject>]?
    var title: String
    var url: String?
    var isPublic: Bool? = true
    var lastUpdated: NSDate?
    var playlistId:String?
    
    init(newTitle:String, newURL:String? = nil, newIsPublic:Bool? = true, newLastUpdated:NSDate? = nil, newPlaylistItems:[Dictionary<String,AnyObject>]? = nil, newPlaylistId:String? = nil) {
        title = newTitle
        url = newURL
        lastUpdated = newLastUpdated
        playlistItems = newPlaylistItems
        playlistId = newPlaylistId
        isPublic = newIsPublic
    }
}
