#import "ViewController.h"
#import "DDYRuntime.h"

@interface DDYRuntimeCell ()

@property (nonatomic, strong) UILabel *contentLabel;

@end

@implementation DDYRuntimeCell

- (UILabel *)contentLabel {
    if (!_contentLabel) {
        _contentLabel = [[UILabel alloc] init];
        [_contentLabel setTextAlignment:NSTextAlignmentLeft];
        [_contentLabel setFont:[UIFont systemFontOfSize:16]];
        [_contentLabel setNumberOfLines:0];
        [_contentLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
        [_contentLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    }
    return _contentLabel;
}

+ (instancetype)cellWithTabelView:(UITableView *)tableView {
    NSString *cellID = NSStringFromClass([self class]);
    DDYRuntimeCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    return cell?cell:[[self alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor whiteColor];
        [self.contentView addSubview:self.contentLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    //Hvfl与Vvfl分别是水平方向与垂直方向的约束，等下之后会有解析
    NSString *Hvfl = @"H:|-margin-[targetView]-margin-|";
    NSString *Vvfl = @"V:|-margin-[targetView]-margin-|";
    //设置margin的数值
    NSDictionary *metrics = @{ @"margin":@15 };
    //把要添加约束的View转成字典,如 @{ @"targetView":self.contentLabel }
    NSDictionary *views = @{ @"targetView":self.contentLabel };
    //添加对齐方式，
    NSLayoutFormatOptions ops = NSLayoutFormatAlignAllLeft;
    //参数已经设置完了，接收返回的数组，用以self.contentView添加
    NSArray *Hconstraints = [NSLayoutConstraint constraintsWithVisualFormat:Hvfl options:ops metrics:metrics views:views];
    NSArray *Vconstraints = [NSLayoutConstraint constraintsWithVisualFormat:Vvfl options:ops metrics:metrics views:views];
    //self.contentView分别添加水平与垂直方向的约束
    [self.contentView addConstraints:Hconstraints];
    [self.contentView addConstraints:Vconstraints];
}

- (void)setStr:(NSString *)str {
    _str = str;
    self.contentLabel.text = _str;
}

@end


@interface ViewController ()

@property (nonatomic, strong) NSMutableArray *dataArray;

@end

@implementation ViewController

- (NSMutableArray *)dataArray {
    if (!_dataArray) {
        _dataArray = [NSMutableArray array];
    }
    return _dataArray;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    [self.tableView setRowHeight:UITableViewAutomaticDimension];
    [self.tableView setEstimatedRowHeight:44];
    [self loadRuntimeData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSLog(@"666666666:%ld", (long)self.dataArray.count);
    return self.dataArray.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *tempArray = self.dataArray[section][@"listArray"];
    return tempArray.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.dataArray[section][@"title"];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    DDYRuntimeCell *cell = [DDYRuntimeCell cellWithTabelView:tableView];
    cell.str = self.dataArray[indexPath.section][@"listArray"][indexPath.row];
    return cell;
}

- (void)loadRuntimeData {
    
    NSString *targetClassNameString = @"UIAlertView";
    self.navigationItem.title = targetClassNameString;
    
    dispatch_queue_t runtimeSerialQueue = dispatch_queue_create("com.ddyruntime_serialQueue", DISPATCH_QUEUE_SERIAL);
    dispatch_async(runtimeSerialQueue, ^{
        NSArray *tempArray = [DDYRuntime getIvarListOfClass:targetClassNameString];
        if (tempArray.count) {
            NSMutableDictionary *tempDict = [NSMutableDictionary dictionary];
            tempDict[@"title"] = @"IvarsList";
            tempDict[@"listArray"] = tempArray;
            [self.dataArray addObject:tempDict];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    });
    
    dispatch_async(runtimeSerialQueue, ^{
        NSArray *tempArray = [DDYRuntime getPropertiesOfClass:targetClassNameString];
        if (tempArray.count) {
            NSMutableDictionary *tempDict = [NSMutableDictionary dictionary];
            tempDict[@"title"] = @"PropertiesList";
            tempDict[@"listArray"] = tempArray;
            [self.dataArray addObject:tempDict];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    });
    
    dispatch_async(runtimeSerialQueue, ^{
        NSArray *tempArray = [DDYRuntime getMethodsOfClass:targetClassNameString];
        if (tempArray.count) {
            NSMutableDictionary *tempDict = [NSMutableDictionary dictionary];
            tempDict[@"title"] = @"MethodsList";
            tempDict[@"listArray"] = tempArray;
            [self.dataArray addObject:tempDict];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    });
    
    dispatch_async(runtimeSerialQueue, ^{
        NSArray *tempArray = [DDYRuntime getClassMethodsOfClass:targetClassNameString];
        if (tempArray.count) {
            NSMutableDictionary *tempDict = [NSMutableDictionary dictionary];
            tempDict[@"title"] = @"ClassMethods List";
            tempDict[@"listArray"] = tempArray;
            [self.dataArray addObject:tempDict];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    });
    
    dispatch_async(runtimeSerialQueue, ^{
        NSArray *tempArray = [DDYRuntime getProtocolsOfClass:targetClassNameString];
        if (tempArray.count) {
            NSMutableDictionary *tempDict = [NSMutableDictionary dictionary];
            tempDict[@"title"] = @"Protocols List";
            tempDict[@"listArray"] = tempArray;
            [self.dataArray addObject:tempDict];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    });
}

@end

