#import "MetalViewController.h"
#import "RomIndex.h"
#import "RomTableViewController.h"


@interface RomTableViewController ()

@property (strong, nonatomic) RomIndex* model;

@end


@implementation RomTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.model = [RomIndex bundledRoms];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"emulator"]) {
        NSIndexPath* indexPath = [self.tableView indexPathForCell:sender];
        if (indexPath) {
            RomAsset* asset = [self.model romAtIndexPath:indexPath];
            if ([segue.destinationViewController isKindOfClass:MetalViewController.class]) {
                MetalViewController* emulator = segue.destinationViewController;
                emulator.romAsset = asset;
            }
        }
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.model.numberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.model numberOfRomsInSection:section];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [self.model titleForSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    RomAsset* asset = [self.model romAtIndexPath:indexPath];
    
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"itemcell" forIndexPath:indexPath];
    
    cell.textLabel.text = asset.title;
    cell.detailTextLabel.text = asset.romDescription;
    
    return cell;
}

@end
