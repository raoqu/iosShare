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
    
    // Process incoming items
    for (NSExtensionItem *extensionItem in self.extensionContext.inputItems) {
        XExtensionItem *xExtensionItem = [[XExtensionItem alloc] initWithExtensionItem:extensionItem];
        
        NSString *title = xExtensionItem.title ?: @"未命名";
        NSString *contentText = xExtensionItem.attributedContentText.string ?: @"";
        
        NSLog(@"Received item:");
        NSLog(@"  Title: %@", title);
        NSLog(@"  Content: %@", contentText);
        
        // Create item dictionary
        NSMutableDictionary *item = [NSMutableDictionary dictionary];
        item[@"title"] = title;
        item[@"content"] = contentText;
        item[@"timestamp"] = [NSDate date];
        
        // Process attachments
        for (NSItemProvider *provider in xExtensionItem.attachments) {
            if ([provider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeURL]) {
                [provider loadItemForTypeIdentifier:(NSString *)kUTTypeURL options:nil completionHandler:^(NSURL *url, NSError *error) {
                    if (url) {
                        NSLog(@"  URL: %@", url.absoluteString);
                        item[@"type"] = @"url";
                        item[@"content"] = url.absoluteString;
                        if (!item[@"title"] || [item[@"title"] length] == 0) {
                            item[@"title"] = url.absoluteString;
                        }
                    }
                }];
            }
            
            if ([provider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeImage]) {
                NSLog(@"  Has image attachment");
                item[@"type"] = @"image";
            }
            
            if ([provider hasItemConformingToTypeIdentifier:(NSString *)kUTTypePlainText]) {
                [provider loadItemForTypeIdentifier:(NSString *)kUTTypePlainText options:nil completionHandler:^(NSString *text, NSError *error) {
                    if (text) {
                        NSLog(@"  Text: %@", text);
                        item[@"type"] = @"text";
                        item[@"content"] = text;
                    }
                }];
            }
        }
        
        if (!item[@"type"]) {
            item[@"type"] = @"text";
        }
        
        [self.receivedItems addObject:item];
    }
}

- (BOOL)isContentValid {
    return YES;
}

- (void)didSelectPost {
    // Save shared items
    [self saveSharedItems];
    
    // Open main app
    [self openMainApp];
    
    // Complete extension
    [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
}

- (void)saveSharedItems {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
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
    
    NSLog(@"Saved %lu items to UserDefaults", (unsigned long)self.receivedItems.count);
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

@end
