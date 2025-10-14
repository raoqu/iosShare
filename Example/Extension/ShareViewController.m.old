#import "ShareViewController.h"
#import <XExtensionItem/XExtensionItem.h>
#import <MobileCoreServices/MobileCoreServices.h>

@interface ShareViewController ()
@property (nonatomic, strong) NSMutableArray *receivedItems;
@end

@implementation ShareViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.receivedItems = [NSMutableArray array];
    
    // 初始化接收的项目（基本信息）
    for (NSExtensionItem *extensionItem in self.extensionContext.inputItems) {
        XExtensionItem *xExtensionItem = [[XExtensionItem alloc] initWithExtensionItem:extensionItem];
        
        NSMutableDictionary *item = [NSMutableDictionary dictionary];
        item[@"title"] = @"未命名";
        item[@"content"] = @"";
        item[@"timestamp"] = [NSDate date];
        item[@"type"] = @"text";
        item[@"xExtensionItem"] = xExtensionItem; // 保存以便后续处理
        
        [self.receivedItems addObject:item];
    }
}

- (BOOL)isContentValid {
    return YES;
}

- (void)didSelectPost {
    // 获取用户输入的文本
    NSString *userComment = self.contentText;
    
    // 为所有 item 添加用户输入
    for (NSMutableDictionary *item in self.receivedItems) {
        if (userComment && userComment.length > 0) {
            item[@"title"] = userComment;
        }
    }
    
    // 异步处理所有附件后再保存
    [self processAttachmentsWithCompletion:^{
        [self saveSharedItems];
        [self openMainApp];
        [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
    }];
}

- (void)saveSharedItems {
    // 使用 App Group 共享的 UserDefaults
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.cc.raoqu.transany"];
    if (!defaults) {
        NSLog(@"⚠️ Failed to create UserDefaults with App Group suite. Using standard defaults.");
        defaults = [NSUserDefaults standardUserDefaults];
    }
    
    // Load existing items
    NSArray *existingItems = [defaults arrayForKey:@"SharedItems"] ?: @[];
    NSMutableArray *allItems = [existingItems mutableCopy];
    
    // Add new items at the beginning
    for (NSDictionary *item in self.receivedItems) {
        [allItems insertObject:item atIndex:0];
    }
    
    // Save back
    [defaults setObject:allItems forKey:@"SharedItems"];
    [defaults synchronize];
    
    NSLog(@"✅ Saved %lu items to UserDefaults (App Group: group.cc.raoqu.transany)", (unsigned long)self.receivedItems.count);
}

- (void)openMainApp {
    NSURL *url = [NSURL URLWithString:@"transany://"];
    [self.extensionContext openURL:url completionHandler:^(BOOL success) {
        NSLog(success ? @"Opened main app" : @"Failed to open main app");
    }];
}

- (NSArray *)configurationItems {
    return @[];
}

- (void)processAttachmentsWithCompletion:(void (^)(void))completion {
    dispatch_group_t group = dispatch_group_create();
    
    for (NSMutableDictionary *item in self.receivedItems) {
        XExtensionItem *xExtensionItem = item[@"xExtensionItem"];
        if (!xExtensionItem) continue;
        
        for (NSItemProvider *provider in xExtensionItem.attachments) {
            // 处理图片
            if ([provider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeImage]) {
                dispatch_group_enter(group);
                [provider loadItemForTypeIdentifier:(NSString *)kUTTypeImage options:nil completionHandler:^(UIImage *image, NSError *error) {
                    if (image) {
                        NSLog(@"📷 Loaded image: %@", NSStringFromCGSize(image.size));
                        item[@"type"] = @"image";
                        // 保存图片信息（可以保存尺寸等元数据）
                        item[@"content"] = [NSString stringWithFormat:@"图片 %.0fx%.0f", image.size.width, image.size.height];
                    }
                    dispatch_group_leave(group);
                }];
            }
            // 处理 URL
            else if ([provider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeURL]) {
                dispatch_group_enter(group);
                [provider loadItemForTypeIdentifier:(NSString *)kUTTypeURL options:nil completionHandler:^(NSURL *url, NSError *error) {
                    if (url) {
                        NSLog(@"🔗 Loaded URL: %@", url.absoluteString);
                        item[@"type"] = @"url";
                        item[@"content"] = url.absoluteString;
                    }
                    dispatch_group_leave(group);
                }];
            }
            // 处理纯文本
            else if ([provider hasItemConformingToTypeIdentifier:(NSString *)kUTTypePlainText]) {
                dispatch_group_enter(group);
                [provider loadItemForTypeIdentifier:(NSString *)kUTTypePlainText options:nil completionHandler:^(NSString *text, NSError *error) {
                    if (text) {
                        NSLog(@"📝 Loaded text: %@", text);
                        item[@"type"] = @"text";
                        item[@"content"] = text;
                    }
                    dispatch_group_leave(group);
                }];
            }
        }
        
        // 清理临时数据
        [item removeObjectForKey:@"xExtensionItem"];
    }
    
    // 所有异步操作完成后调用 completion
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        NSLog(@"✅ All attachments processed");
        if (completion) {
            completion();
        }
    });
}

@end
