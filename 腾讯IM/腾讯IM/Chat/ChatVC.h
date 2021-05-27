//
//  ChatVC.h
//  腾讯IM
//
//  Created by yangtaotao on 2021/5/13.
//

#import <UIKit/UIKit.h>
#import "TUIChatController.h"
#import "TUnReadView.h"
NS_ASSUME_NONNULL_BEGIN
@class TUIMessageCellData;
@interface ChatVC : UIViewController

@property (nonatomic, strong) TUIConversationCellData *conversationData;
@property (nonatomic, strong) TUnReadView *unRead;
- (void)sendMessage:(TUIMessageCellData*)msg;
@end

NS_ASSUME_NONNULL_END
