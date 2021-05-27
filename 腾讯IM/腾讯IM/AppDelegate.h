//
//  AppDelegate.h
//  腾讯IM
//
//  Created by yangtaotao on 2021/5/13.
//

#import <UIKit/UIKit.h>
#import "TUIKit.h"
//apns (sdkBusiId 为证书上传控制台后生成，详情请参考文档[离线推送]（https://cloud.tencent.com/document/product/269/44517）)
#ifdef DEBUG
#define sdkBusiId 26841
#else
#define sdkBusiId 26840
#endif


@interface AppDelegate : UIResponder <UIApplicationDelegate>
+ (id)sharedInstance;

@property (nonatomic,strong) UIWindow *window;
@property (nonatomic, strong) NSData *deviceToken;

- (UIViewController *)getLoginController;
- (UITabBarController *)getMainController;
- (void)login:(NSString *)identifier userSig:(NSString *)sig succ:(TSucc)succ fail:(TFail)fail;


@end

