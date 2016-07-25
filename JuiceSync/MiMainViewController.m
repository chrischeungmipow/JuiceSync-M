//
//  MiMainViewController.m
//  JuiceSync
//
//  Created by Guorong ZHANG on 4/8/14.
//
//

#import "MiMainViewController.h"
#import "MiAppDelegate.h"

#import "QBAnimationSequence.h"
#import "QBAnimationGroup.h"
#import "QBAnimationItem.h"
@interface MiMainViewController ()
{
    UIAlertView *alertDiscon, *alertRename;
    int connectionAlert;//flag to indicate the disconnect occure on the initial period or user operating  time
    enum
    {
        begin = 0,
        operate,
        end,
    };
    NSTimer *cannotEstablishTimer;
    UIAlertView *disconnectAlert;
    NSTimer *operateTimer;
    NSTimer *chargingtimer;
    NSInteger i;
    NSInteger bcapacityThres;
    float stateValue;
    uint16_t temperatureC;
    NSTimer *temptimer;
    NSTimer *temptimer2;
    NSTimer *rangetimer;
    NSInteger  tempRSSI;
    BOOL once10, once20, once30,once100;
    BOOL battcharging;
    UILocalNotification* localNotification;
    UILocalNotification* rangelocalNotification;
    QBAnimationSequence *_sequence;
    UIImageView *indicator,*tempBody;
    
    CGAffineTransform currentTransform;
    CGAffineTransform newTransform;

}
@property (nonatomic, strong) CMMotionManager* motionManager;
@property (nonatomic, strong) CADisplayLink* motionDisplayLink;
@property (nonatomic) float motionLastYaw;

@end

@implementation MiMainViewController
@synthesize capacityPercent,chargingState,detailItem,deviceName,myPeriph,tempEmpty,tempLabel,grayview,outRangeLabel,tempAlertBtn,batteryAlertBtn,rangeAlertBtn,batteryAlertLabel,tempAlertLabel,rangeAlertLabel,batteryLife;

static MiSound * toneDefaultbatt, *toneOnebatt, *toneTwobatt, *toneThreebatt, *toneFourbatt;
static NSArray *toneArraybatt;
static MiSound * toneDefaulttemp, *toneOnetemp, *toneTwotemp, *toneThreetemp, *toneFourtemp, *toneFivetemp;
static NSArray *toneArraytemp;
static MiSound * toneDefaultrange, *toneOnerange, *toneTworange, *toneThreerange, *toneFourrange;
static NSArray *toneArrayrange;
static NSArray *batteryToneArray, *tempToneArray, *rangeToneArray;
static NSArray *batterySoundNameArray, *tempSoundNameArray, *rangeSoundNameArray;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:YES forKey:@"grayviewhidden"];
    
    tempBody = [[UIImageView alloc] initWithFrame:CGRectMake(108, 300, 1, 22)];
    [[self.view viewWithTag:0] addSubview:tempBody];
   
    i = 0;
    //chargingtimer = [NSTimer scheduledTimerWithTimeInterval:(0.8)target:self selector:@selector(chargingLoop) userInfo:nil repeats:YES];
    once10 = true;
    once20 = true;
    once30 = true;
    once100 = true;
    battcharging = NO;
   
    localNotification = [[UILocalNotification alloc] init];
    rangelocalNotification = [[UILocalNotification alloc] init];
    [self initToneArray];
    [self startTempTimer];
    
    indicator.hidden = YES;
    indicator = [[UIImageView alloc] initWithFrame:CGRectMake(36, 33, 242, 242)];
    [[self.view viewWithTag:0] addSubview:indicator];
    QBAnimationItem *item1 = [QBAnimationItem itemWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveLinear|UIViewAnimationOptionAllowUserInteraction animations:^{
        indicator.transform = CGAffineTransformRotate(indicator.transform, M_PI/4);
    }];
    QBAnimationGroup *group1 = [QBAnimationGroup groupWithItems:@[item1]];
    _sequence = [[QBAnimationSequence alloc] initWithAnimationGroups:@[group1] repeat:YES];
    
    batteryAlertLabel.text = NSLocalizedString(@"BattAlert", @"");
    tempAlertLabel.text = NSLocalizedString(@"TempAlert", @"");
    rangeAlertLabel.text = NSLocalizedString(@"AwayAlert", @"");
    batteryLife.text = NSLocalizedString(@"BattLife", @"");
    self.renameBarBtn.title = NSLocalizedString(@"Rename", @"");
    self.disconnectBarBtn.title = NSLocalizedString(@"Disconnect", @"");

    //liquid view
    self.view.userInteractionEnabled=YES;
    self.liquidView = [[MiLiquidView alloc] initWithFrame:CGRectMake(52, 48, ViewWidth-55*2,ViewWidth-55*2)];
    //[self.liquidView initLiquidView:CGRectMake(52, 48, ViewWidth-55*2,ViewWidth-55*2)];
    self.liquidView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.liquidView];
    [self.view bringSubviewToFront:capacityPercent];
    [self.view bringSubviewToFront:chargingState];
    
    [self startGravity];
    currentTransform=self.liquidView.transform;
    [self.liquidView setProgress:0.0/100 animated:YES];
    

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedCharBatteryStateUpdate:)
                                                 name:@"CharBatteryStateUpdate"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedCharBatteryCapacityUpdate:)
                                                 name:@"CharBatteryCapacityUpdate"
                                               object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reconnectTimer)
                                                 name:@"ReconnectTimer"
                                               object:nil];
    
    
}

-(void) startTempTimer {
    [temptimer invalidate];
    temptimer = [NSTimer scheduledTimerWithTimeInterval:(20)target:self selector:@selector(showTempAlert) userInfo:nil repeats:YES];
}

-(void) stopTempTimer {
    
    [temptimer invalidate];
}

-(void) startTempTimer2 {
    
    [temptimer2 invalidate];
    temptimer2 = [NSTimer scheduledTimerWithTimeInterval:(300)target:self selector:@selector(showTempAlert) userInfo:nil repeats:YES];
}

-(void) startRangeTimer {
    [rangetimer invalidate];
    rangetimer = [NSTimer scheduledTimerWithTimeInterval:(5)target:self selector:@selector(CheckRSSI) userInfo:nil repeats:NO];
}


-(void) initToneArray{
    
    NSBundle *mainBundle = [NSBundle mainBundle];
    toneDefaultbatt = [[MiSound alloc] initWithContentsOfFile:[mainBundle pathForResource:@"lowbattery" ofType:@"mp3"]];
    toneOnebatt = [[MiSound alloc] initWithContentsOfFile:[mainBundle pathForResource:@"lowbattery1" ofType:@"mp3"]];
    toneTwobatt = [[MiSound alloc] initWithContentsOfFile:[mainBundle pathForResource:@"lowbattery2" ofType:@"mp3"]];
    toneThreebatt = [[MiSound alloc] initWithContentsOfFile:[mainBundle pathForResource:@"lowbattery3" ofType:@"mp3"]];
    toneFourbatt = [[MiSound alloc] initWithContentsOfFile:[mainBundle pathForResource:@"lowbattery4" ofType:@"mp3"]];
    toneArraybatt = [[NSArray alloc] initWithObjects:toneDefaultbatt,toneOnebatt,toneTwobatt,toneThreebatt,toneFourbatt,nil];
    
    
    toneDefaulttemp = [[MiSound alloc] initWithContentsOfFile:[mainBundle pathForResource:@"hightemper1" ofType:@"mp3"]];
    toneOnetemp = [[MiSound alloc] initWithContentsOfFile:[mainBundle pathForResource:@"hightemper2" ofType:@"mp3"]];
    toneTwotemp = [[MiSound alloc] initWithContentsOfFile:[mainBundle pathForResource:@"hightemper3" ofType:@"mp3"]];
    toneThreetemp = [[MiSound alloc] initWithContentsOfFile:[mainBundle pathForResource:@"hightemper4" ofType:@"mp3"]];
    toneFourtemp = [[MiSound alloc] initWithContentsOfFile:[mainBundle pathForResource:@"hightemper5" ofType:@"mp3"]];
    toneFivetemp= [[MiSound alloc] initWithContentsOfFile:[mainBundle pathForResource:@"hightemper6" ofType:@"mp3"]];
    toneArraytemp = [[NSArray alloc] initWithObjects:toneDefaulttemp,toneOnetemp,toneTwotemp,toneThreetemp,toneFourtemp,toneFivetemp,nil];
    
    
    toneDefaultrange = [[MiSound alloc] initWithContentsOfFile:[mainBundle pathForResource:@"outrange1" ofType:@"mp3"]];
    
    toneTworange = [[MiSound alloc] initWithContentsOfFile:[mainBundle pathForResource:@"outrange3" ofType:@"mp3"]];
    toneThreerange = [[MiSound alloc] initWithContentsOfFile:[mainBundle pathForResource:@"outrange4" ofType:@"mp3"]];
    toneFourrange = [[MiSound alloc] initWithContentsOfFile:[mainBundle pathForResource:@"outrange5" ofType:@"mp3"]];
    toneOnerange = [[MiSound alloc] initWithContentsOfFile:[mainBundle pathForResource:@"outrange2" ofType:@"mp3"]];
    toneArrayrange = [[NSArray alloc] initWithObjects:toneDefaultrange,toneOnerange,toneTworange,toneThreerange,toneFourrange,nil];
    
    batteryToneArray = [[NSArray alloc]initWithObjects:@"Default",@"Tone One",@"Tone Two",@"Tone Three",@"Tone Four", nil];
    tempToneArray = [[NSArray alloc]initWithObjects:@"Default",@"Tone One",@"Tone Two",@"Tone Three",@"Tone Four",@"Tone Five", nil];
    rangeToneArray = [[NSArray alloc]initWithObjects:@"Default",@"Tone One",@"Tone Two",@"Tone Three",@"Tone Four", nil];
    
    batterySoundNameArray = [[NSArray alloc]initWithObjects:@"lowbattery.mp3",@"lowbattery1.mp3",@"lowbattery2.mp3",@"lowbattery3.mp3",@"lowbattery4.mp3", nil];
    tempSoundNameArray = [[NSArray alloc]initWithObjects:@"hightemper1.mp3",@"hightemper2.mp3",@"hightemper3.mp3",@"hightemper4.mp3",@"hightemper5.mp3",@"hightemper6.mp3", nil];
    rangeSoundNameArray = [[NSArray alloc]initWithObjects:@"outrange1.mp3",@"outrange2.mp3",@"outrange3.mp3",@"outrange4.mp3",@"outrange5.mp3", nil];
    
}

+(MiSound*) GetToneShared:(int) mode index:(NSInteger) row{
    
    MiSound *tempTone;
    switch (mode) {
        case 0:
            tempTone = [toneArraybatt objectAtIndex:row];
            break;
        case 1:
            tempTone = [toneArraytemp objectAtIndex:row];
            break;
        case 2:
            tempTone = [toneArrayrange objectAtIndex:row];
            break;
            
        default:
            break;
    }
    
    return tempTone;
}



+(NSString*) GetToneName:(int) mode index:(NSInteger) row{

    NSString *tempString;
    switch (mode) {
        case 0:
            tempString = [batteryToneArray objectAtIndex:row];
            break;
        case 1:
            tempString = [tempToneArray objectAtIndex:row];
            break;
        case 2:
            tempString = [rangeToneArray objectAtIndex:row];
            break;
            
        default:
            break;
    }
    
    
    return tempString;

}

+(NSString*) GetSoundName:(int) mode index:(NSInteger) row{
    
    NSString *tempString;
    switch (mode) {
        case 0:
            tempString = [batterySoundNameArray objectAtIndex:row];
            break;
        case 1:
            tempString = [tempSoundNameArray objectAtIndex:row];
            break;
        case 2:
            tempString = [rangeSoundNameArray objectAtIndex:row];
            break;
            
        default:
            break;
    }
    
    
    return tempString;
    
}

+(NSArray*) GetToneArray : (int) mode{

    NSArray * tempArray;
    switch (mode) {
        case 0:
            tempArray = batteryToneArray;
            break;
        case 1:
            tempArray = tempToneArray;
            break;
        case 2:
            tempArray = rangeToneArray;
            break;
            
        default:
            break;
    }
    return tempArray;

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated{
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedPeriphConnectedNotification:)
                                                 name:@"PeriphConnected"
                                               object:nil];
    
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedPeriphDisconnectedNotification:)
                                                 name:@"PeriphDisconnected"
                                               object:nil];
    
    //[[NSNotificationCenter defaultCenter] removeObserver:self name:@"PeriphDisconnectedErrorDelete" object:nil];
    
    //[[NSNotificationCenter defaultCenter] addObserver:self
    //                                         selector:@selector(periphDisconnectedErrorDelete:)
    //                                             name:@"PeriphDisconnectedErrorDelete"
    //                                           object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reconnectedTimerInvalidate)
                                                 name:@"ReconnectedTimerInvalidate"
                                               object:nil];
    
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedCharBatteryStateFound:)
                                                 name:@"CharBatteryStateFound"
                                               object:nil];
    
   
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedCharBatteryNameFound:)
                                                 name:@"CharBatteryNameFound"
                                               object:nil];
    
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedCharAlertFound:)
                                                 name:@"CharAlertFound"
                                               object:nil];
    
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedCharCapacityFound:)
                                                 name:@"CharCapacityFound"
                                               object:nil];
    
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedCharBatteryNameUpdate:)
                                                 name:@"CharBatteryNameUpdate"
                                               object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedCharBatteryAlertUpdate:)
                                                 name:@"CharBatteryAlertUpdate"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"BluetoothOFF" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedBluetoothOFF:)
                                                 name:@"BluetoothOFF"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"BluetoothOFFWaitOn" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedBluetoothOFFWaitOn:)
                                                 name:@"BluetoothOFFWaitOn"
                                               object:nil];
    
    
    
    instance = [BlueToothMe shared];
    connectionAlert = begin;
    if (detailItem)
    {
        myPeriph = (CBPeripheral*) detailItem;
        
        
        NSLog(@"ready to connected %@", deviceName);
        if (deviceName == nil)
        {
            deviceName=myPeriph.name;
        }
        self.title =deviceName;
        
    }
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL grayviewshow =[userDefaults boolForKey:@"grayviewhidden"];
    grayview.hidden = grayviewshow;
    
    /*operateTimer = [NSTimer scheduledTimerWithTimeInterval:1.9
                                                    target:self
                                                  selector:@selector(toOperateTimer)
                                                  userInfo:nil
                                                   repeats:NO];
    */
    
    BOOL batteryOn = [userDefaults boolForKey:@"batteryAlertEnable"];
    BOOL tempOn = [userDefaults boolForKey:@"tempAlertEnable"];
    BOOL rangeOn = [userDefaults boolForKey:@"rangeAlertEnable"];
    //[mySwitch setOn:tempswitch];
    
    if (batteryOn) {
        [batteryAlertBtn setImage:[UIImage imageNamed:@"btn_BatteryAlert"] forState:UIControlStateNormal];
        
    }else{
        [batteryAlertBtn setImage:[UIImage imageNamed:@"btn_BatteryAlert_a"] forState:UIControlStateNormal];
        
    }
    
    if (tempOn) {
        [tempAlertBtn setImage:[UIImage imageNamed:@"btn_TempAlert"] forState:UIControlStateNormal];
        
    }else{
        [tempAlertBtn setImage:[UIImage imageNamed:@"btn_TempAlert_a"] forState:UIControlStateNormal];
        
    }
    
    if (rangeOn) {
        [rangeAlertBtn setImage:[UIImage imageNamed:@"btn_RangeAlert"] forState:UIControlStateNormal];
        
    }else{
        [rangeAlertBtn setImage:[UIImage imageNamed:@"btn_RangeAlert_a"] forState:UIControlStateNormal];
        
    }
    
}

-(void) viewWillDisappear:(BOOL)animated{

    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ReconnectedTimerInvalidate" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"PeriphConnected" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"PeriphDisconnected" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"CharBatteryStateFound" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"CharBatteryNameFound" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"CharAlertFound" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"CharCapacityFound" object:nil];
    //[[NSNotificationCenter defaultCenter] removeObserver:self name:@"CharBatteryStateUpdate" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"CharBatteryNameUpdate" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"CharBatteryAlertUpdate" object:nil];
    //[[NSNotificationCenter defaultCenter] removeObserver:self name:@"CharBatteryCapacityUpdate" object:nil];
    //[[NSNotificationCenter defaultCenter] removeObserver:self name:@"RSSIUpdate" object:nil];
    
    NSLog(@"removed observers");
    
}

- (void)receivedCharBatteryStateFound:(NSNotification *) notification {
    
    CBCharacteristic *myCharacter = [instance.fastCharsCBUUID objectForKey:[CBUUID UUIDWithString:BATTERY_STATE_CHAR_UUID]];
    
    if (myCharacter) {
        //[instance.testPeripheral setNotifyValue:YES forCharacteristic:myCharacter];
    }
}

- (void)receivedCharBatteryNameFound:(NSNotification *) notification {
    
    CBCharacteristic *myCharacter = [instance.fastCharsCBUUID objectForKey:[CBUUID UUIDWithString:BATTERY_NAME_CHAR_UUID]];
    
    if (myCharacter) {
        //[instance.testPeripheral setNotifyValue:YES forCharacteristic:myCharacter];
    }
}


- (void)receivedCharAlertFound:(NSNotification *) notification {
    
    CBCharacteristic *myCharacter = [instance.fastCharsCBUUID objectForKey:[CBUUID UUIDWithString:ALART_LEVEL_CHAR_UUID ]];
    
    if (myCharacter) {
        //[instance.testPeripheral setNotifyValue:YES forCharacteristic:myCharacter];
    }
}

- (void)receivedCharCapacityFound:(NSNotification *) notification {
    
    CBCharacteristic *myCharacter = [instance.fastCharsCBUUID objectForKey:[CBUUID UUIDWithString:BATTERY_CAPACITY_CHAR_UUID]];
    
    if (myCharacter) {
        instance = [BlueToothMe shared];
        [instance.testPeripheral readValueForCharacteristic:myCharacter];
    }
}


- (void)receivedCharBatteryStateUpdate:(NSNotification *) notification {
    
    CBCharacteristic *myChar = (CBCharacteristic*)[notification object];
    //NSData *myData = [myChar value];
    //NSString* stateString = [[NSString alloc] initWithData:myData encoding:NSUTF8StringEncoding];
    if(myChar.value){
        
        const uint8_t *myData = [myChar.value bytes];
        stateValue=[[NSString stringWithFormat:@"%d", myData[5]] floatValue];
        
        if (stateValue == 3) {
            
            battcharging = YES;
            
        }else{
            
            battcharging = NO;
        }
        
        //Charging or not
        if (stateValue == 2) {
            indicator.hidden = NO;
            chargingState.text= NSLocalizedString(@"State_Discharging0", @"");
            indicator.image = [UIImage imageNamed:@"Indicator_bar.png"];
            [_sequence start];
            
        }else if(stateValue==3)
        {
            indicator.hidden = NO;
            chargingState.text= NSLocalizedString(@"State_Charging0", @"");
            indicator.image = [UIImage imageNamed:@"Indicator_body_green.png"];
            [_sequence start];
            
        }else
        {
            indicator.hidden = YES;
            chargingState.text = @"";
            [_sequence stop];
        }

        
        //The temperature
        uint16_t temperatureCelsius=0;
        if ((myData[0]&0x01) == 0) {
            temperatureCelsius = myData[1];
        }
        else
        {
            temperatureCelsius = CFSwapInt16LittleToHost(*(uint16_t *)(&myData[1]));
        }
        int temperatureFahrenheit = 1.8*[[NSString stringWithFormat:@"%d", temperatureCelsius] intValue] +32;
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSInteger tempunit = [userDefaults  integerForKey:@"tempUnit"];
        if(tempunit == 0)
        {
            tempLabel.text = [NSString stringWithFormat:@"%d%@", temperatureCelsius,@"°C"];
        }else
        {
            tempLabel.text = [NSString stringWithFormat:@"%d%@", temperatureFahrenheit,@"°F"];
        }
        [self showTempChart:temperatureCelsius];
        temperatureC = temperatureCelsius;
        
    }
}

/*
- (void) chargingLoop{
    
    i++;
    if (i == 3){
        i = 0;
    }
    switch (i) {
        case 0:
            if(stateValue==2)
            {
                
                chargingState.text= NSLocalizedString(@"State_Discharging1", @"");
                
            }else if(stateValue==3)
            {
                chargingState.text= NSLocalizedString(@"State_Charging1", @"");
                
            }else
            {
                chargingState.text = @"";
            }
            break;
        case 1:
            if(stateValue==2)
            {
                
                chargingState.text= NSLocalizedString(@"State_Discharging2", @"");
                
            }else if(stateValue==3)
            {
                chargingState.text= NSLocalizedString(@"State_Charging2", @"");
                
            }else
            {
                chargingState.text = @"";
            }
            break;
        case 2:
            if(stateValue==2)
            {
                
                chargingState.text= NSLocalizedString(@"State_Discharging3", @"");
                
            }else if(stateValue==3)
            {
                chargingState.text= NSLocalizedString(@"State_Charging3", @"");
                
            }else
            {
                chargingState.text = @"";
            }
            break;
        default:
            break;
    }
    
}
*/
- (void)receivedCharBatteryNameUpdate:(NSNotification *) notification {
    
    CBCharacteristic *myChar = (CBCharacteristic*)[notification object];
    NSLog(@"Renamed device and posted notification");
    
}

- (void)receivedCharBatteryAlertUpdate:(NSNotification *) notification {
    
    CBCharacteristic *myChar = (CBCharacteristic*)[notification object];
    
    
}




- (void)receivedCharBatteryCapacityUpdate:(NSNotification *) notification {
    
    CBCharacteristic *myChar = (CBCharacteristic*)[notification object];
    const uint8_t *reportData = [myChar.value bytes];
    NSInteger bcapacity = [[NSString stringWithFormat:@"%d", reportData[0]] intValue];
    
    if (bcapacity!=17) {
        capacityPercent.text = [NSString stringWithFormat:@"%ld%@", (long)bcapacity,@"%"];
        [self showBatteryChart:bcapacity];
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        BOOL batteryswitchon = [userDefaults boolForKey:@"batteryAlertEnable"];
        NSInteger soundrow = [userDefaults integerForKey:@"batteryalarmrow"];
        MiSound *soundToPlay = [MiMainViewController  GetToneShared:0 index:soundrow ];
        
        NSMutableArray *tempobject = [userDefaults objectForKey:@"batteryAlertMulti"];
        
        if (bcapacity >bcapacityThres) { //if recharge, recover all alert switch
            once10 = true;
            once20 = true;
            once30 = true;
        }
        MiAppDelegate *appDelegate = (MiAppDelegate *)[[UIApplication sharedApplication] delegate];
        
        for (NSObject *row in tempobject){
            
            NSNumber *tempNum = (NSNumber*) row;
            int rownumber = [tempNum intValue];
            NSInteger selectedIndex = rownumber;
            if(batteryswitchon && !battcharging){
                if (selectedIndex == 0 &&bcapacity == 10 &&once10) {
                    once10 = false;
                    bcapacityThres = bcapacity;
                    if(appDelegate.isBackground){
                   
                    [[UIApplication sharedApplication] cancelAllLocalNotifications];
                    if(localNotification){
                        
                        localNotification.alertBody = NSLocalizedString(@"LowBattAlertContent", @"");
                        localNotification.soundName = [MiMainViewController  GetSoundName:0 index:soundrow];// UILocalNotificationDefaultSoundName;
                        localNotification.alertAction = @"Show me the item";
                        
                    }
                    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
                    }else{
                    
                     [soundToPlay play];
                    
                    }
                }
                
                if (selectedIndex == 1 &&bcapacity == 20 &&once20) {
                    once20 = false;
                    bcapacityThres = bcapacity;
                    
                    if(appDelegate.isBackground){
                    [[UIApplication sharedApplication] cancelAllLocalNotifications];
                    if(localNotification){
                        
                        localNotification.alertBody = NSLocalizedString(@"LowBattAlertContent", @"");
                        localNotification.soundName = [MiMainViewController  GetSoundName:0 index:soundrow];//UILocalNotificationDefaultSoundName;
                        localNotification.alertAction = @"Show me the item";
                        
                    }
                    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
                    }else{
                        [soundToPlay play];
                    
                    }
                }
                if (selectedIndex == 2 &&bcapacity == 30 &&once30) {
                    once30 = false;
                    bcapacityThres = bcapacity;
                    
                    if(appDelegate.isBackground){
                    [[UIApplication sharedApplication] cancelAllLocalNotifications];
                    if(localNotification){
                        
                        localNotification.alertBody = NSLocalizedString(@"LowBattAlertContent", @"");
                        localNotification.soundName = [MiMainViewController  GetSoundName:0 index:soundrow];//UILocalNotificationDefaultSoundName;
                        localNotification.alertAction = @"Show me the item";
                        
                        
                    }
                    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
                    }else{
                     [soundToPlay play];
                    }
                    
                }
                
            }
            
            
        }
        //NSLog(@"............%d",bcapacity);
        if (bcapacity == 100 && battcharging && once100) {
            once100 = false;
            //chargingState.text = NSLocalizedString(@"ChargeFilled", @"");
            localNotification.alertBody = NSLocalizedString(@"ChargeComplete", @"");
            localNotification.soundName = UILocalNotificationDefaultSoundName;
            localNotification.alertAction = @"Show me the item";
            [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
            
        }
        
        if(bcapacity < 90)
        {
            once100 = true;
        }
        
    }
    
}



-(void)reconnectTimer{
    [[NSUserDefaults standardUserDefaults]setObject:[self GetUUID] forKey:@"lastConnectUUID"];
    tempRSSI = -130;
    [self startRangeTimer];
    NSLog(@"Disconnect abnormally");
}
// To show the chart dynamically Invoke by receivedCharBatteryCapacityUpdate
-(void) showBatteryChart:(NSInteger) bcapacity{
  
        [self.liquidView setProgress:(double)bcapacity/100 animated:YES];

        if (bcapacity<=RED_VALUE){
           
        }
        if (bcapacity>RED_VALUE&&bcapacity<=YELLOW_VALUE){
            
        }
        if (bcapacity>YELLOW_VALUE&&bcapacity<=FULL_VALUE) {
            
            //batteryBottom.image = [UIImage imageNamed:@"battery_bottom_green.png"];
        }
        
   
}

-(void)showTempChart:(uint16_t)temperatureCelsius{
    //NSLog(@"new temp chart");
    if (IS_IPHONE_5) {
   
        if (temperatureCelsius < TEMP_THRESHOLD){
            tempBody.image = [UIImage imageNamed:@"temp_body_blue.png"];
            tempBody.frame = CGRectMake(82, 333, temperatureCelsius*1.10, 12);
            tempEmpty.image = [UIImage imageNamed:@"temp_empty_blue.png"];
            //[[self.view viewWithTag:1] addSubview:tempEmpty];
        
        }else{
            tempBody.image = [UIImage imageNamed:@"temp_body_red.png"];
            tempBody.frame = CGRectMake(82, 333, temperatureCelsius*1.10, 12);
            tempEmpty.image = [UIImage imageNamed:@"temp_empty_red.png"];
        
             }
        
                }else{
                    if (temperatureCelsius < TEMP_THRESHOLD){
                        tempBody.image = [UIImage imageNamed:@"temp_body_blue.png"];
                        tempBody.frame = CGRectMake(82, 290, temperatureCelsius*1.10, 10);
                        tempEmpty.image = [UIImage imageNamed:@"temp_empty_blue.png"];
                        //[[self.view viewWithTag:1] addSubview:tempEmpty];
                        
                    }else{
                        tempBody.image = [UIImage imageNamed:@"temp_body_red.png"];
                        tempBody.frame = CGRectMake(82, 290, temperatureCelsius*1.10, 10);
                        tempEmpty.image = [UIImage imageNamed:@"temp_empty_red.png"];
                        //[[self.view viewWithTag:1] addSubview:tempEmpty];
                        
                    }
                
                
                }
    
}

- (void) showTempAlert {
    
    if (temperatureC >= TEMP_THRESHOLD ) {
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSInteger soundrow = [userDefaults integerForKey:@"tempalarmrow"];
        
        BOOL tempswitchon = [userDefaults boolForKey:@"tempAlertEnable"];
        MiAppDelegate *appDelegate = (MiAppDelegate *)[[UIApplication sharedApplication] delegate];
        if (tempswitchon) {
            
            
            if(appDelegate.isBackground){
            [[UIApplication sharedApplication] cancelAllLocalNotifications];
            if(localNotification){
                
                localNotification.alertBody = NSLocalizedString(@"TempAlertContent", @"");
                localNotification.soundName = [MiMainViewController  GetSoundName:1 index:soundrow];//UILocalNotificationDefaultSoundName;
                localNotification.alertAction = @"Show me the item";
                [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
                
                      }
            }else{
            
            MiSound *soundToPlay = [MiMainViewController  GetToneShared:1 index:soundrow ];
            [soundToPlay play];
            }
            
            [self stopTempTimer];
            [self startTempTimer2];
        }
    }
    
}
- (IBAction)disconnectDevice:(id)sender { 
    
    [[NSUserDefaults standardUserDefaults]setObject:nil forKey:@"lastConnectUUID"];
    
    [self backToMain];
    
    NSLog(@"have disconnected");

}


- (IBAction)renamedevice:(id)sender {
    
    alertRename =  [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"RenameDevice", @"")
                                              message: NSLocalizedString(@"Renamemsg", @"")
                                             delegate:self
                                    cancelButtonTitle: NSLocalizedString(@"cancel", @"")
                                    otherButtonTitles: NSLocalizedString(@"OK", @""),nil];
    
    alertRename.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alertRename show];

}


-(void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    if (alertView == alertRename) {
        
        if ([title isEqualToString:@"OK"])//0=cancel, 1=OK
        {
            
            CBCharacteristic *myCharacter = [instance.fastCharsCBUUID objectForKey:[CBUUID UUIDWithString:@"FFFF"]];
            
            if (myCharacter) {
                
                UITextField *deviceNameInput = [alertView textFieldAtIndex:0];
                
                if (deviceNameInput.text != nil && ![deviceNameInput.text isEqualToString:@""] ) {
                    // NSLog(@"devName %@", deviceNameInput.text);
                    self.deviceName = deviceNameInput.text;
                    self.title = self.deviceName;
                    
                    NSData* valData = [deviceNameInput.text dataUsingEncoding:NSUTF8StringEncoding];
                    [instance.testPeripheral writeValue:valData forCharacteristic:myCharacter type:CBCharacteristicWriteWithResponse];
                    [instance.testPeripheral readValueForCharacteristic:myCharacter];
                    
                    [instance idleScanReset];
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"RenameRefresh" object:self.detailItem];
                    
                }
            }
            
            
        }
    }
    
    
}


- (void)receivedPeriphConnectedNotification:(NSNotification *) notification {
    
    CBPeripheral *reconnPeriph = (CBPeripheral*)[notification object];
    if(reconnPeriph){
        NSLog(@"reconnect success");
        [[NSUserDefaults standardUserDefaults]setObject:nil forKey:@"lastConnectUUID"];
        myPeriph = reconnPeriph;
        [instance.manager connectPeripheral:myPeriph
                                    options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBConnectPeripheralOptionNotifyOnDisconnectionKey]];
        grayview.hidden = YES;
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setBool:YES forKey:@"grayviewhidden"];
    }
}

- (void)receivedPeriphDisconnectedNotification:(NSNotification *) notification {
    
    //[self setDisconnected];
    
    switch (connectionAlert) {
        case begin:
        {
            
            [instance.manager connectPeripheral:self.detailItem
                                        options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBConnectPeripheralOptionNotifyOnDisconnectionKey]];
            
            break;
        }
        case operate:
            
            break;
            
        case end:
            break;
        default:
            break;
    }
    
}

/*
-(void)periphDisconnectedErrorDelete:(NSNotification *)notification{
    
    [[NSUserDefaults standardUserDefaults]setObject:[self GetUUID] forKey:@"lastConnectUUID"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ReconnectDelay" object:nil];
    [self startRangeTimer];
 
    NSLog(@"Disconnect abnormally");
}*/


-(void) reconnectedTimerInvalidate{
    
  // while(!grayview.isHidden)
  // {
  //     //just delay until grayview is indeed hidden
  // }
    grayview.hidden = YES;
    tempRSSI = -1;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:YES forKey:@"grayviewhidden"];
    NSLog(@"reconneted");
    if(rangelocalNotification){
    [[UIApplication sharedApplication] cancelLocalNotification:rangelocalNotification];
      }
}

-(void)CheckRSSI{
    
    if (tempRSSI == -130) {
    
    NSLog(@"checking");
    grayview.hidden = NO;
    outRangeLabel.text = NSLocalizedString(@"outRangeAlert", @"");
    [_sequence stop];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSInteger soundrow = [userDefaults integerForKey:@"rangealarmrow"];
    [userDefaults setBool:NO forKey:@"grayviewhidden"];
    BOOL rangeswitchon = [userDefaults boolForKey:@"rangeAlertEnable"];
    MiAppDelegate *appDelegate = (MiAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (rangeswitchon) {
        
        if (appDelegate.isBackground) {
            
        if(rangelocalNotification){
            [[UIApplication sharedApplication] cancelLocalNotification:rangelocalNotification];
            rangelocalNotification.alertBody = NSLocalizedString(@"RangeAlertContent", @"");
            rangelocalNotification.soundName = [MiMainViewController  GetSoundName:2 index:soundrow];//UILocalNotificationDefaultSoundName;
            rangelocalNotification.alertAction = @"Show me the item";
            rangelocalNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:0.01];
            [[UIApplication sharedApplication] scheduleLocalNotification:rangelocalNotification];
            NSLog(@"Sent notification");
                             }
        
        }else{
            
            MiSound *soundToPlay = [MiMainViewController  GetToneShared:2 index:soundrow];
            [soundToPlay play];            //localNotification = nil;
            
        }
    
     }
  }
}



/*
 -(void)toBatteryOFF{
 
 if(!myPeriph.isConnected){
 
 batteryOffLabel.text= NSLocalizedString(@"BatteryOFFAlert", @"");
 grayview.hidden = NO;
 NSLog(@"show battery off");
 
 }
 
 else{
 
 grayview.hidden = YES;
 
 NSLog(@"reswitch battery on successfully");
 
 }
 }
 */

-(void)toOperateTimer{
    connectionAlert = operate;
}

-(void)toCannotEstablishTimer{
    //myPeriph = (CBPeripheral*) self.detailItem;
    if (!myPeriph.isConnected) {
        UIAlertView *connectEstablishAlert = [[UIAlertView alloc] initWithTitle:@"Cannot Establish Connection!"
                                                                        message:@"Connection fail."
                                                                       delegate:nil
                                                              cancelButtonTitle:@"OK"
                                                              otherButtonTitles:nil];
        // [connectEstablishAlert show];
        //[self backToMain];
    }
    
    
}



-(void)displayDisconnectAlert{
    disconnectAlert = [[UIAlertView alloc] initWithTitle:@"JuiceSync disconnected!"
                                                 message:[NSString stringWithFormat:@"%@ disconnected",self.deviceName]
                                                delegate:nil
                                       cancelButtonTitle:@"OK"
                                       otherButtonTitles:nil];
    [disconnectAlert show];
    
}

- (NSString *)GetUUID
{
    CFUUIDRef theUUID = [myPeriph UUID];
    if (theUUID == 0x0) {
        //NSLog(@"Yes");
        return nil;
    }else{
        CFStringRef string = CFUUIDCreateString(NULL, theUUID);
        return (__bridge_transfer NSString *)string ;
    }
}


- (void)receivedBluetoothOFF:(NSNotification *) notification{

    
    [self backToMain];




}
- (void)receivedBluetoothOFFWaitOn:(NSNotification *) notification{
    
    grayview.hidden = NO;
    outRangeLabel.text = NSLocalizedString(@"BlueTooth_OFF", @"");
    
}

- (BOOL)isGravityActive
{
    return self.motionDisplayLink != nil;
}

- (void)startGravity
{
    if ( ! [self isGravityActive]) {
        self.motionManager = [[CMMotionManager alloc] init];
        self.motionManager.deviceMotionUpdateInterval =0.1;// 0.02; // 50 Hz
        
        self.motionLastYaw = 0;
        _theTimer= [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(motionRefresh:) userInfo:nil repeats:YES];
    }
    if ([self.motionManager isDeviceMotionAvailable]) {
        // to avoid using more CPU than necessary we use ``CMAttitudeReferenceFrameXArbitraryZVertical``
        [self.motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryZVertical];
    }
}
- (void)motionRefresh:(id)sender
{
    
    // compute the device yaw from the attitude quaternion
    // http://en.wikipedia.org/wiki/Conversion_between_quaternions_and_Euler_angles
    CMQuaternion quat = self.motionManager.deviceMotion.attitude.quaternion;
    double yaw = asin(2*(quat.x*quat.z - quat.w*quat.y));//
  
    //NSLog(@"%f ...%f",quat.y, yaw);
    // TODO improve the yaw interval (stuck to [-PI/2, PI/2] due to arcsin definition
    if (quat.y  < - 0.5) {
        yaw =yaw  + M_PI;
    }
    else if(quat.y > 0.5)
    {
        yaw = yaw - M_PI;
    }else{
        yaw *= -1;
    }// reverse the angle so that it reflect a *liquid-like* behavior
    //yaw += M_PI_2;  // because for the motion manager 0 is the calibration value (but for us 0 is the horizontal axis)
   // NSLog(@"%f ...%f",quat.z, yaw);
    if (self.motionLastYaw == 0) {
        self.motionLastYaw = yaw;
    }
    
    // kalman filtering
    static float q = 0.1;   // process noise
    static float s = 0.1;   // sensor noise
    static float p = 0.1;   // estimated error
    static float k = 0.5;   // kalman filter gain
    
    float x = self.motionLastYaw;
    p = p + q;
    k = p / (p + s);
    x = x + k*(yaw - x);
    p = (1 - k)*p;
    
    newTransform=CGAffineTransformRotate(currentTransform,-x);
    self.liquidView.transform=newTransform;
    self.motionLastYaw = x;
}

- (void)stopGravity
{
    if ([self isGravityActive]) {
        [self.motionDisplayLink invalidate];
        self.motionDisplayLink = nil;
        self.motionLastYaw = 0;
        [_theTimer invalidate];
        _theTimer=nil;
        
        self.motionManager = nil;   // release the motion manager memory
    }
    if ([self.motionManager isDeviceMotionActive])
        [self.motionManager stopDeviceMotionUpdates];
}

-(void)backToMain{
    
    //simulate become active but can change if needed
    NSLog(@"where2");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DelegateBecomeActiveNoReload" object:nil];
    
    connectionAlert = end;
    
    [instance.manager cancelPeripheralConnection:myPeriph];
    NSLog(@"cancel %@", myPeriph.name);
    
    //[instance startScan];
    //[instance setScanDuration:FAST_SCAN];
    [instance idleScanReset];
    [cannotEstablishTimer invalidate];
    [operateTimer invalidate];
    [rangetimer invalidate];
    [self.navigationController popToRootViewControllerAnimated:NO];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"CharBatteryStateUpdate" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"CharBatteryCapacityUpdate" object:nil];
   
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ReconnectTimer" object:nil];
}


/*
 -(void) dealloc{
 [batteryBody release];

 [capacityPercent release];
 [chargingState release];
 [super dealloc];
 
 }*/

@end
