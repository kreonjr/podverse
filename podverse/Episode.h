//
//  Episode.h
//  
//
//  Created by Mitchell Downey on 6/20/15.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Clip, Podcast;

@interface Episode : NSManagedObject

@property (nonatomic, retain) NSNumber * duration;
@property (nonatomic, retain) NSString * link;
@property (nonatomic, retain) NSNumber * mediaBytes;
@property (nonatomic, retain) NSString * mediaType;
@property (nonatomic, retain) NSString * mediaURL;
@property (nonatomic, retain) NSDate * pubDate;
@property (nonatomic, retain) NSString * summary;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * downloadedMediaFileURL;
@property (nonatomic, retain) NSSet *clips;
@property (nonatomic, retain) Podcast *podcast;
@property (nonatomic, retain) NSString * guid;
@end

@interface Episode (CoreDataGeneratedAccessors)

- (void)addClipsObject:(Clip *)value;
- (void)removeClipsObject:(Clip *)value;
- (void)addClips:(NSSet *)values;
- (void)removeClips:(NSSet *)values;

@end
