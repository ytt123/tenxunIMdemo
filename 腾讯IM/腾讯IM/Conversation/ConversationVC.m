//
//  ConversationVC.m
//  腾讯IM
//
//  Created by yangtaotao on 2021/5/13.
//

#import "ConversationVC.h"
#import "TUIConversationListController.h"
#import "ChatVC.h"
#import "TPopView.h"
#import "TPopCell.h"
#import "THeader.h"
#import "Toast/Toast.h"
//#import "TUIContactSelectController.h"
#import "ReactiveObjC/ReactiveObjC.h"
#import "TIMUserProfile+DataProvider.h"
#import "TNaviBarIndicatorView.h"
#import "TUIKit.h"
#import "THelper.h"
#import "TCUtil.h"
#import "TIMUserProfile+DataProvider.h"
#import <ImSDK/ImSDK.h>

@interface ConversationVC ()<TUIConversationListControllerDelegate>
@property (nonatomic, strong) TNaviBarIndicatorView *titleView;
@end

@implementation ConversationVC

- (void)viewDidLoad {
    [super viewDidLoad];
    TUIConversationListController *conv = [[TUIConversationListController alloc] init];
    conv.delegate = self;
    [self addChildViewController:conv];
    [self.view addSubview:conv.view];

    //如果不加这一行代码，依然可以实现点击反馈，但反馈会有轻微延迟，体验不好。
    conv.tableView.delaysContentTouches = NO;


//    UIButton *moreButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
//    [moreButton setImage:[UIImage imageNamed:TUIKitResource(@"more")] forState:UIControlStateNormal];
//    [moreButton addTarget:self action:@selector(rightBarButtonClick:) forControlEvents:UIControlEventTouchUpInside];
//    UIBarButtonItem *moreItem = [[UIBarButtonItem alloc] initWithCustomView:moreButton];
//    self.navigationItem.rightBarButtonItem = moreItem;

    [self setupNavigation];
}

/**
 *初始化导航栏
 */
- (void)setupNavigation
{
    _titleView = [[TNaviBarIndicatorView alloc] init];
    [_titleView setTitle:NSLocalizedString(@"AppMainTitle", nil)];
    self.navigationItem.titleView = _titleView;
    self.navigationItem.title = @"";
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onNetworkChanged:) name:TUIKitNotification_TIMConnListener object:nil];
}

/**
 *初始化导航栏Title，不同连接状态下Title显示内容不同
 */
- (void)onNetworkChanged:(NSNotification *)notification
{
    TUINetStatus status = (TUINetStatus)[notification.object intValue];
    switch (status) {
        case TNet_Status_Succ:
            [_titleView setTitle:NSLocalizedString(@"AppMainTitle", nil)];
            [_titleView stopAnimating];
            break;
        case TNet_Status_Connecting:
            [_titleView setTitle:NSLocalizedString(@"AppMainConnectingTitle", nil)];// 连接中...
            [_titleView startAnimating];
            break;
        case TNet_Status_Disconnect:
            [_titleView setTitle:NSLocalizedString(@"AppMainDisconnectTitle", nil)]; // 腾讯·云通信(未连接)
            [_titleView stopAnimating];
            break;
        case TNet_Status_ConnFailed:
            [_titleView setTitle:NSLocalizedString(@"AppMainDisconnectTitle", nil)]; // 腾讯·云通信(未连接)
            [_titleView stopAnimating];
            break;

        default:
            break;
    }
}

/**
 *推送默认跳转
 */
- (void)pushToChatViewController:(NSString *)groupID userID:(NSString *)userID {
    ChatVC *chat = [[ChatVC alloc] init];
    TUIConversationCellData *conversationData = [[TUIConversationCellData alloc] init];
    conversationData.groupID = groupID;
    conversationData.userID = userID;
    chat.conversationData = conversationData;
    [self.navigationController pushViewController:chat animated:YES];
}

/**
 *在消息列表内，点击了某一具体会话后的响应函数
 */
- (void)conversationListController:(TUIConversationListController *)conversationController didSelectConversation:(TUIConversationCell *)conversation
{
    ChatVC *chat = [[ChatVC alloc] init];
    chat.conversationData = conversation.convData;
    [self.navigationController pushViewController:chat animated:YES];
    
    if ([conversation.convData.groupID isEqualToString:@"im_demo_admin"] || [conversation.convData.userID isEqualToString:@"im_demo_admin"]) {
        [TCUtil report:Action_Clickhelper actionSub:@"" code:@(0) msg:@"clickhelper"];
    }
    if ([conversation.convData.groupID isEqualToString:@"@TGS#33NKXK5FK"] || [conversation.convData.userID isEqualToString:@"@TGS#33NKXK5FK"]) {
        [TCUtil report:Action_Clickdefaultgrp actionSub:@"" code:@(0) msg:@"clickdefaultgrp"];
    }
}
@end
