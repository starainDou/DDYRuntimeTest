#import <UIKit/UIKit.h>

@interface DDYRuntimeCell :UITableViewCell

@property (nonatomic, strong) NSString *str;

+ (instancetype)cellWithTabelView:(UITableView *)tableView;

@end

@interface ViewController : UITableViewController

@end

