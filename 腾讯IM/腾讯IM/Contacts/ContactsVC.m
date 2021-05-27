//
//  ContactsVC.m
//  腾讯IM
//
//  Created by yangtaotao on 2021/5/13.
//

#import "ContactsVC.h"

#import "TUIContactController.h"
#import "TPopView.h"
#import "TPopCell.h"
#import "THeader.h"

#import "MMLayout/UIView+MMLayout.h"
#import "ReactiveObjC/ReactiveObjC.h"
#import "Toast/Toast.h"
#import "TFriendProfileController.h"
#import "TUIConversationCell.h"
#import "TUIConversationListController.h"
#import "TUIBlackListController.h"
#import "TUINewFriendViewController.h"
#import "ChatVC.h"
#import "TUIContactSelectController.h"
#import "TIMUserProfile+DataProvider.h"
#import <ImSDK/ImSDK.h>
#import "SearchFriendViewController.h"

@interface ContactsVC ()<TPopViewDelegate>

@end

@implementation ContactsVC
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"联系人";

    //如果不加这一行代码，依然可以实现点击反馈，但反馈会有轻微延迟，体验不好。
    self.tableView.delaysContentTouches = NO;
    
    UIButton *moreButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    [moreButton setImage:[UIImage imageNamed:TUIKitResource(@"more")] forState:UIControlStateNormal];
    [moreButton addTarget:self action:@selector(onRightItem:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *moreItem = [[UIBarButtonItem alloc] initWithCustomView:moreButton];
    self.navigationItem.rightBarButtonItem = moreItem;

    
    
}

/**
 *在导航栏中添加右侧按钮，使用popView展示进一步的内容
 */
- (void)onRightItem:(UIButton *)rightBarButton;
{
    NSMutableArray *menus = [NSMutableArray array];
    TPopCellData *friend = [[TPopCellData alloc] init];
    friend.image = TUIKitResource(@"new_friend");
    friend.title = NSLocalizedString(@"ContactsAddFriends", nil); //@"添加好友";
    [menus addObject:friend];

//    TPopCellData *group = [[TPopCellData alloc] init];
//    group.image = TUIKitResource(@"add_group");
//    group.title = NSLocalizedString(@"ContactsJoinGroup", nil);//@"添加群组";
//    [menus addObject:group];

    CGFloat height = [TPopCell getHeight] * menus.count + TPopView_Arrow_Size.height;
    CGFloat orginY = StatusBar_Height + NavBar_Height;
    TPopView *popView = [[TPopView alloc] initWithFrame:CGRectMake(Screen_Width - 140, orginY, 130, height)];
    CGRect frameInNaviView = [self.navigationController.view convertRect:rightBarButton.frame fromView:rightBarButton.superview];
    popView.arrowPoint = CGPointMake(frameInNaviView.origin.x + frameInNaviView.size.width * 0.5, orginY);
    popView.delegate = self;
    [popView setData:menus];
    [popView showInWindow:self.view.window];
}

- (void)popView:(TPopView *)popView didSelectRowAtIndex:(NSInteger)index
{
    if(index == 0){
        //添加好友
        UIViewController *add = [[SearchFriendViewController alloc] init];
        [self.navigationController pushViewController:add animated:YES];
    }
//    if(index == 1){
//        //添加群组
//        UIViewController *add = [[SearchGroupViewController alloc] init];
//        [self.navigationController pushViewController:add animated:YES];
//    }
}
@end
