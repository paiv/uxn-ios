#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface RomAsset : NSObject

@property (strong, nonatomic, readonly) NSURL* assetUrl;
@property (strong, nonatomic, readonly) NSString* title;
@property (strong, nonatomic, readonly) NSString* romDescription;

@end


@interface RomIndex : NSObject

+ (nullable instancetype)bundledRoms;

@property (assign, nonatomic, readonly) NSUInteger numberOfSections;

- (nullable NSString*)titleForSection:(NSUInteger)section;
- (NSUInteger)numberOfRomsInSection:(NSUInteger)section;
- (nullable NSArray<RomAsset*>*)romsInSection:(NSUInteger)section;
- (nullable RomAsset*)romAtIndexPath:(NSIndexPath*)indexPath;

@end


NS_ASSUME_NONNULL_END
