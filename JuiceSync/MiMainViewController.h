//
//  MiMainViewController.h
//  JuiceSync
//
//  Created by Guorong ZHANG on 4/8/14.
//
//

#import <UIKit/UIKit.h>
#import "BlueToothMe/BlueToothMe.h"
#import "MiSound.h"
#import "MiLiquidView.h"
#import <CoreMotion/CoreMotion.h>

#define RED_VALUE 20
#define YELLOW_VALUE 30
#define FULL_VALUE 100
#define TEMP_THRESHOLD 55.0
#define IS_IPHONE_5 ( fabs( ( double )[ [ UIScreen mainScreen ] bounds ].size.height - ( double )568 ) < DBL_EPSILON )

@interface MiMainViewController : UIViewController
{
 BlueToothMe *instance;
}

@property (strong, nonatomic) id detailItem;
@property (strong, nonatomic) NSString *deviceName;

@property (weak, nonatomic) IBOutlet UILabel *capacityPercent;

@property (weak, nonatomic) IBOutlet UILabel *chargingState;

@property (weak, nonatomic) IBOutlet UILabel *tempLabel;
@property (weak, nonatomic) IBOutlet UIImageView *tempEmpty;

@property (nonatomic, weak) CBPeripheral *myPeriph;
@property (weak, nonatomic) IBOutlet UIView *grayview;
@property (weak, nonatomic) IBOutlet UILabel *outRangeLabel;

@property (weak, nonatomic) IBOutlet UIButton *batteryAlertBtn;
@property (weak, nonatomic) IBOutlet UIButton *tempAlertBtn;
@property (weak, nonatomic) IBOutlet UIButton *rangeAlertBtn;

@property (weak, nonatomic) IBOutlet UILabel *batteryAlertLabel;
@property (weak, nonatomic) IBOutlet UILabel *tempAlertLabel;
@property (weak, nonatomic) IBOutlet UILabel *rangeAlertLabel;
@property (weak, nonatomic) IBOutlet UILabel *batteryLife;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *renameBarBtn;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *disconnectBarBtn;
//@property (weak, nonatomic) IBOutlet MiLiquidView *liquidView;
@property(nonatomic,strong)MiLiquidView * liquidView;
@property (nonatomic , strong)  NSTimer *theTimer;

+(MiSound*) GetToneShared:(int) mode index:(NSInteger) row;
+(NSString*) GetToneName:(int) mode index:(NSInteger) row;
+(NSArray*) GetToneArray : (int) mode;
+(NSString*) GetSoundName:(int) mode index:(NSInteger) row;

@end
