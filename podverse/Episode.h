//
//  Episode.h
//  
//
//  Created by Mitchell Downey on 6/2/15.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Clip, Podcast;

@interface Episode : NSManagedObject

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * summary;
@property (nonatomic, retain) NSDate * pubDate;
@property (nonatomic, retain) NSNumber * duration;
@property (nonatomic, retain) NSString * link;
@property (nonatomic, retain) NSString * mediaURL;
@property (nonatomic, retain) NSString * mediaType;
@property (nonatomic, retain) NSNumber * mediaBytes;
@property (nonatomic, retain) Podcast *podcast;
@property (nonatomic, retain) Clip *clip;

@end
