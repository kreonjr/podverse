//
//  Clip.h
//  
//
//  Created by Mitchell Downey on 6/20/15.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Episode, Podcast;

@interface Clip : NSManagedObject

@property (nonatomic, retain) NSNumber * endTime;
@property (nonatomic, retain) NSNumber * startTime;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) Episode *episode;
@property (nonatomic, retain) Podcast *podcast;

@end
