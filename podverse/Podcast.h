//
//  Podcast.h
//  
//
//  Created by Mitchell Downey on 6/2/15.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Clip, Episode;

@interface Podcast : NSManagedObject

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * summary;
@property (nonatomic, retain) NSString * feedURL;
@property (nonatomic, retain) NSString * itunesAuthor;
@property (nonatomic, retain) NSDate * lastPubDate;
@property (nonatomic, retain) NSString * imageURL;
@property (nonatomic, retain) NSData * image;
@property (nonatomic, retain) NSString * itunesImageURL;
@property (nonatomic, retain) NSData * itunesImage;
@property (nonatomic, retain) NSSet *episodes;
@property (nonatomic, retain) Clip *clip;
@end

@interface Podcast (CoreDataGeneratedAccessors)

- (void)addEpisodesObject:(Episode *)value;
- (void)removeEpisodesObject:(Episode *)value;
- (void)addEpisodes:(NSSet *)values;
- (void)removeEpisodes:(NSSet *)values;

@end
