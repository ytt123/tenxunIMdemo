//
//  ConversationVC.h
//  腾讯IM
//
//  Created by yangtaotao on 2021/5/13.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ConversationVC : UIViewController
/**
 *跳转到对应的聊天界面
 */
- (void)pushToChatViewController:(NSString *)groupID userID:(NSString *)userID;
@end

NS_ASSUME_NONNULL_END
