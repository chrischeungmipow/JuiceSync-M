//
//  MiPageContentController.h
//  JuiceSync
//
//  Created by Guorong ZHANG on 4/14/14.
//
//

#import <UIKit/UIKit.h>
#define IS_IPHONE_5 ( fabs( ( double )[ [ UIScreen mainScreen ] bounds ].size.height - ( double )568 ) < DBL_EPSILON )

@interface MiPageContentController : UIViewController
@property (weak, nonatomic) IBOutlet UIImageView *tutorialImageView;
@property (weak, nonatomic) IBOutlet UILabel *commentLabel;

@property NSUInteger pageIndex;
@property NSString *commentText;
@property NSString *imageFile;

@end

