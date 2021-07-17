#import <UIKit/NSIndexPath+UIKitAdditions.h>
#import "RomIndex.h"


@interface RomAsset ()

@property (strong, nonatomic) NSURL* assetUrl;
@property (strong, nonatomic) NSString* title;
@property (strong, nonatomic) NSString* romDescription;

@end


@implementation RomAsset
@end


@interface RomSection : NSObject

@property (strong, nonatomic) NSString* title;
@property (strong, nonatomic) NSArray<RomAsset*>* assets;

@end


@implementation RomSection
@end


@interface RomIndex ()

@property (strong, nonatomic) NSArray<RomSection*>* sections;

@end


@implementation RomIndex

+ (instancetype)bundledRoms {
    NSURL* indexUrl = [NSBundle.mainBundle URLForResource:@"index.json" withExtension:nil subdirectory:@"roms"];
    if (!indexUrl) {
        return nil;
    }
    
    NSData* data = [NSData dataWithContentsOfURL:indexUrl];
    NSArray* index = [NSJSONSerialization JSONObjectWithData:data options:(0) error:nil];
    NSURL* indexRoot = [indexUrl URLByDeletingLastPathComponent];

    NSMutableArray* sections = [NSMutableArray arrayWithCapacity:index.count];
    [index enumerateObjectsUsingBlock:^(NSDictionary* section, NSUInteger idx, BOOL* stop) {
        NSArray* entries = section[@"roms"];
        NSMutableArray* assets = [NSMutableArray arrayWithCapacity:entries.count];
        [entries enumerateObjectsUsingBlock:^(NSDictionary* entry, NSUInteger idx, BOOL* stop) {
            RomAsset* asset = [[RomAsset alloc] init];
            asset.assetUrl = [indexRoot URLByAppendingPathComponent:entry[@"file"]];
            asset.title = [asset.assetUrl URLByDeletingPathExtension].lastPathComponent;
            asset.romDescription = entry[@"description"];
            [assets addObject:asset];
        }];
        
        RomSection* model = [[RomSection alloc] init];
        model.title = section[@"section"];
        model.assets = [NSArray arrayWithArray:assets];
        [sections addObject:model];
    }];
    
    RomIndex* model = [[RomIndex alloc] init];
    model.sections = sections;
    return model;
}

- (NSUInteger)numberOfSections {
    return self.sections.count;
}

- (NSString *)titleForSection:(NSUInteger)section {
    return self.sections[section].title;
}

- (NSUInteger)numberOfRomsInSection:(NSUInteger)section {
    return self.sections[section].assets.count;
}

- (NSArray<RomAsset *> *)romsInSection:(NSUInteger)section {
    return self.sections[section].assets;
}

- (RomAsset *)romAtIndexPath:(NSIndexPath *)indexPath {
    return self.sections[indexPath.section].assets[indexPath.row];
}

@end
