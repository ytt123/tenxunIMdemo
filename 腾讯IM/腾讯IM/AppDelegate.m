//
//  AppDelegate.m
//  腾讯IM
//
//  Created by yangtaotao on 2021/5/13.
//

#import "AppDelegate.h"
//config

#import "GenerateTestUserSig.h"
#import <ImSDK/ImSDK.h>
#import "THeader.h"
#import "TCUtil.h"
#import "THelper.h"
#import "UIColor+TUIDarkMode.h"
//vc
#import "LoginController.h"
#import "ContactsVC.h"
#import "ConversationVC.h"
#import "SettingController.h"

#import "TUITabBarController.h"
#import "TNavigationController.h"



@interface AppDelegate ()

@property(nonatomic,strong) NSString *groupID;
@property(nonatomic,strong) NSString *userID;
@property(nonatomic,strong) V2TIMSignalingInfo *signalingInfo;

@end
static AppDelegate *app;
@implementation AppDelegate

+ (instancetype)sharedInstance {
    return app;
}
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    app = self;
    // Override point for customization after application launch.
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserStatus:) name:TUIKitNotification_TIMUserStatusListener object:nil];
    
    [self registNotification];
    [[TUIKit sharedInstance] setupWithAppId:SDKAPPID];
    TUIKitConfig.defaultConfig.avatarType=TAvatarTypeRadiusCorner;
    TUIKitConfig.defaultConfig.avatarCornerRadius=6.f;
    [[TUILocalStorage sharedInstance] login:^(NSString * _Nonnull identifier, NSUInteger appId, NSString * _Nonnull userSig) {
        if(appId == SDKAPPID && identifier.length != 0 && userSig.length != 0){
            [self login:identifier userSig:userSig succ:nil fail:nil];
        } else {
            self.window.rootViewController = [self getLoginController];
        }
    }];
    
    NSLog(@"123");
    return YES;
}
-(void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    // 需要在 Xcode 把 Push Notifications打开
    _deviceToken = deviceToken;
}
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler
{
    // 收到推送普通信息推送（普通消息推送设置代码请参考 TUIMessageController -> sendMessage）
    //普通消息推送格式（C2C）：
    //@"ext" :
    //@"{\"entity\":{\"action\":1,\"chatType\":1,\"content\":\"Hhh\",\"sendTime\":0,\"sender\":\"2019\",\"version\":1}}"
    //普通消息推送格式（Group）：
    //@"ext"
    //@"{\"entity\":{\"action\":1,\"chatType\":2,\"content\":\"Hhh\",\"sendTime\":0,\"sender\":\"@TGS#1PWYXLTGA\",\"version\":1}}"
    
    // 收到推送音视频推送（音视频推送设置代码请参考 TUICall+Signal -> sendAPNsForCall）
    //音视频通话推送格式（C2C）：
    //@"ext" :
    //@"{\"entity\":{\"action\":2,\"chatType\":1,\"content\":\"{\\\"action\\\":1,\\\"call_id\\\":\\\"144115224193193423-1595225880-515228569\\\",\\\"call_type\\\":1,\\\"code\\\":0,\\\"duration\\\":0,\\\"invited_list\\\":[\\\"10457\\\"],\\\"room_id\\\":1688911421,\\\"timeout\\\":30,\\\"timestamp\\\":0,\\\"version\\\":4}\",\"sendTime\":1595225881,\"sender\":\"2019\",\"version\":1}}"
    //音视频通话推送格式（Group）：
    //@"ext"
    //@"{\"entity\":{\"action\":2,\"chatType\":2,\"content\":\"{\\\"action\\\":1,\\\"call_id\\\":\\\"144115212826565047-1595506130-2098177837\\\",\\\"call_type\\\":2,\\\"code\\\":0,\\\"duration\\\":0,\\\"group_id\\\":\\\"@TGS#1BUBQNTGS\\\",\\\"invited_list\\\":[\\\"10457\\\"],\\\"room_id\\\":1658793276,\\\"timeout\\\":30,\\\"timestamp\\\":0,\\\"version\\\":4}\",\"sendTime\":1595506130,\"sender\":\"vinson1\",\"version\":1}}"
    NSDictionary *extParam = [TCUtil jsonSring2Dictionary:userInfo[@"ext"]];
    NSDictionary *entity = extParam[@"entity"];
    if (!entity) {
        return;
    }
    // 业务，action : 1 普通文本推送；2 音视频通话推送
    NSString *action = entity[@"action"];
    if (!action) {
        return;
    }
    // 聊天类型，chatType : 1 单聊；2 群聊
    NSString *chatType = entity[@"chatType"];
    if (!chatType) {
        return;
    }
    // action : 1 普通消息推送
    if ([action intValue] == APNs_Business_NormalMsg) {
        if ([chatType intValue] == 1) {   //C2C
            self.userID = entity[@"sender"];
        } else if ([chatType intValue] == 2) { //Group
            self.groupID = entity[@"sender"];
        }
        if ([[V2TIMManager sharedInstance] getLoginStatus] == V2TIM_STATUS_LOGINED) {
            [self onReceiveNomalMsgAPNs];
        }
    }
    // action : 2 音视频通话推送
    else if ([action intValue] == APNs_Business_Call) {
        // 单聊中的音视频邀请推送不需处理，APP 启动后，TUIkit 会自动处理
        if ([chatType intValue] == 1) {   //C2C
            return;
        }
        // 内容
        NSDictionary *content = [TCUtil jsonSring2Dictionary:entity[@"content"]];
        if (!content) {
            return;
        }
        UInt64 sendTime = [entity[@"sendTime"] integerValue];
        uint32_t timeout = [content[@"timeout"] intValue];
        UInt64 curTime = (UInt64)[[NSDate date] timeIntervalSince1970];
        if (curTime - sendTime > timeout) {
            [THelper makeToast:@"通话接收超时"];
            return;
        }
        self.signalingInfo = [[V2TIMSignalingInfo alloc] init];
        self.signalingInfo.actionType = (SignalingActionType)[content[@"action"] intValue];
        self.signalingInfo.inviteID = content[@"call_id"];
        self.signalingInfo.inviter = entity[@"sender"];
        self.signalingInfo.inviteeList = content[@"invited_list"];
        self.signalingInfo.groupID = content[@"group_id"];
        self.signalingInfo.timeout = timeout;
        self.signalingInfo.data = [TCUtil dictionary2JsonStr:@{SIGNALING_EXTRA_KEY_ROOM_ID : content[@"room_id"], SIGNALING_EXTRA_KEY_VERSION : content[@"version"], SIGNALING_EXTRA_KEY_CALL_TYPE : content[@"call_type"]}];
        if ([[V2TIMManager sharedInstance] getLoginStatus] == V2TIM_STATUS_LOGINED) {
            [self onReceiveGroupCallAPNs];
        }
    }
}
- (void)login:(NSString *)identifier userSig:(NSString *)sig succ:(TSucc)succ fail:(TFail)fail
{
    [[TUIKit sharedInstance] login:identifier userSig:sig succ:^{
        NSLog(@"-----> 登录成功");
        [[TUILocalStorage sharedInstance] saveLogin:identifier withAppId:SDKAPPID withUserSig:sig];
        if (self.deviceToken) {
            V2TIMAPNSConfig *confg = [[V2TIMAPNSConfig alloc] init];
            confg.businessID = sdkBusiId;
            confg.token = self.deviceToken;
            [[V2TIMManager sharedInstance] setAPNS:confg succ:^{
                 NSLog(@"-----> 设置 APNS 成功");
            } fail:^(int code, NSString *msg) {
                 NSLog(@"-----> 设置 APNS 失败");
            }];
        }
        self.window.rootViewController = [app getMainController];
        [self onReceiveNomalMsgAPNs];
        [self onReceiveGroupCallAPNs];
    } fail:^(int code, NSString *msg) {
        NSLog(@"-----> 登录失败");
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"code:%d msdg:%@ ,请检查 sdkappid,identifier,userSig 是否正确配置",code,msg] message:nil delegate:self cancelButtonTitle:@"知道了" otherButtonTitles:nil, nil];
        [alert show];
        self.window.rootViewController = [self getLoginController];
    }];
}
- (void)registNotification
{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
    {
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }
    else
    {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes: (UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert)];
    }
}

- (void)onReceiveNomalMsgAPNs {
    if (self.groupID.length > 0 || self.userID.length > 0) {
        UITabBarController *tab = [app getMainController];
        if (tab.selectedIndex != 0) {
            [tab setSelectedIndex:0];
        }
        self.window.rootViewController = tab;
        UINavigationController *nav = (UINavigationController *)tab.selectedViewController;
        ConversationVC *vc = (ConversationVC *)nav.viewControllers.firstObject;
        [vc pushToChatViewController:self.groupID userID:self.userID];
        self.groupID = nil;
        self.userID = nil;
    }
}

- (void)onReceiveGroupCallAPNs {
    if (self.signalingInfo) {
        [[TUIKit sharedInstance] onReceiveGroupCallAPNs:self.signalingInfo];
        self.signalingInfo = nil;
    }
}

void uncaughtExceptionHandler(NSException*exception){
    NSLog(@"CRASH: %@", exception);
    NSLog(@"Stack Trace: %@",[exception callStackSymbols]);
    // Internal error reporting
}

- (UIViewController *)getLoginController{
    UIStoryboard *board = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    LoginController *login = [board instantiateViewControllerWithIdentifier:@"LoginController"];
    return login;
}

- (UITabBarController *)getMainController{
    
    
//    UIStoryboard *board = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
//    TabbarVC *tab = [board instantiateViewControllerWithIdentifier:@"TabbarVC"];
//    return tab;
    
    
    TUITabBarController *tbc = [[TUITabBarController alloc] init];
    NSMutableArray *items = [NSMutableArray array];
    TUITabBarItem *msgItem = [[TUITabBarItem alloc] init];
    msgItem.title = @"消息"; //@"消息";
    msgItem.selectedImage = [UIImage imageNamed:@"session_selected"];
    msgItem.normalImage = [UIImage imageNamed:@"session_normal"];
    msgItem.controller = [[TNavigationController alloc] initWithRootViewController:[[ConversationVC alloc] init]];
    msgItem.controller.view.backgroundColor = [UIColor d_colorWithColorLight:TController_Background_Color dark:TController_Background_Color_Dark];
    [items addObject:msgItem];

    TUITabBarItem *contactItem = [[TUITabBarItem alloc] init];
    contactItem.title =@"联系人";
    contactItem.selectedImage = [UIImage imageNamed:@"contact_selected"];
    contactItem.normalImage = [UIImage imageNamed:@"contact_normal"];
    contactItem.controller = [[TNavigationController alloc] initWithRootViewController:[[ContactsVC alloc] init]];
    contactItem.controller.view.backgroundColor = [UIColor d_colorWithColorLight:TController_Background_Color dark:TController_Background_Color_Dark];
    [items addObject:contactItem];
   
    TUITabBarItem *setItem = [[TUITabBarItem alloc] init];
    setItem.title = @"我";
    setItem.selectedImage = [UIImage imageNamed:@"myself_selected"];
    setItem.normalImage = [UIImage imageNamed:@"myself_normal"];
    setItem.controller = [[TNavigationController alloc] initWithRootViewController:[[SettingController alloc] init]];
    setItem.controller.view.backgroundColor = [UIColor d_colorWithColorLight:TController_Background_Color dark:TController_Background_Color_Dark];
    [items addObject:setItem];
    
    tbc.tabBarItems = items;

    return tbc;
    
    
}

- (void)onUserStatus:(NSNotification *)notification
{
    TUIUserStatus status = [notification.object integerValue];
    switch (status) {
        case TUser_Status_ForceOffline:
        {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"下线通知" message:@"您的帐号于另一台手机上登录。" delegate:self cancelButtonTitle:@"退出" otherButtonTitles:@"重新登录", nil];
            [alertView show];
        }
            break;
        case TUser_Status_ReConnFailed:
        {
            NSLog(@"连网失败");
        }
            break;
        case TUser_Status_SigExpired:
        {
            NSLog(@"userSig过期");
        }
            break;
        default:
            break;
    }
}


/**
 *强制下线后的响应函数委托
 */
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(buttonIndex == 0){
        // 退出
        [[V2TIMManager sharedInstance] logout:^{
            NSLog(@"登出成功！");
        } fail:^(int code, NSString *msg) {
            NSLog(@"退出登录");
        }];
        self.window.rootViewController = [self getLoginController];
    }else if(buttonIndex == 1){
        // 重新登录
        [[TUILocalStorage sharedInstance] login:^(NSString * _Nonnull identifier, NSUInteger appId, NSString * _Nonnull userSig) {
            [self login:identifier userSig:userSig succ:nil fail:nil];
        }];
    } else {
        self.window.rootViewController = [self getLoginController];
    }
}

@end




