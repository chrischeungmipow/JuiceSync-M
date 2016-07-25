//
//  MiPageContentController.m
//  JuiceSync
//
//  Created by Guorong ZHANG on 4/14/14.
//
//

#import "MiPageContentController.h"

@interface MiPageContentController ()

@end

@implementation MiPageContentController

- (id)initWithNibName:(NSUInteger)pageIndex
{
    self = [super initWithNibName:@"PageContent" bundle:nil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.tutorialImageView.image = [UIImage imageNamed:self.imageFile];
    self.commentLabel.text = self.commentText;
    
  
    /*UILabel *commentLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 300, 285, 140)];
        commentLabel.backgroundColor = [UIColor clearColor];
    commentLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:17];
    [commentLabel setNumberOfLines:0];
    commentLabel.lineBreakMode = UILineBreakModeWordWrap;
    commentLabel.textColor = [UIColor whiteColor];
    commentLabel.text = self.commentText;
    [self.view addSubview:commentLabel];
    //self.commentLabel.frame = CGRectMake(50, 10, 100, 99);*/
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
