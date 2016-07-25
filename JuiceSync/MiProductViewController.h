//
//  MiProductViewController.h
//  JuiceSync
//
//  Created by Guorong ZHANG on 4/8/14.
//
//

#import <UIKit/UIKit.h>
#import "BlueToothMe.h"
#import <CoreData/CoreData.h>

@interface MiProductViewController : UIViewController<UITableViewDataSource,UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end
