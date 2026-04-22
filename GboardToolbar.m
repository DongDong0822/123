#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface UIInputViewController (GBT)
- (void)gbt_viewDidLoad;
@end

@implementation UIInputViewController (GBT)

- (void)gbt_viewDidLoad {
    [self gbt_viewDidLoad]; // calls original

    if (![NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.google.keyboard"]) return;

    UIView *toolbar = [[UIView alloc] init];
    toolbar.backgroundColor = [UIColor systemGroupedBackgroundColor];
    toolbar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:toolbar];
    [NSLayoutConstraint activateConstraints:@[
        [toolbar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [toolbar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [toolbar.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [toolbar.heightAnchor constraintEqualToConstant:44],
    ]];

    NSArray *items = @[
        @[@"doc.on.doc",                    @"gbt_copy"],
        @[@"doc.on.clipboard",              @"gbt_paste"],
        @[@"arrow.uturn.backward",          @"gbt_undo"],
        @[@"keyboard.chevron.compact.down", @"gbt_dismiss"],
    ];

    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisHorizontal;
    stack.distribution = UIStackViewDistributionFillEqually;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [toolbar addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:toolbar.leadingAnchor],
        [stack.trailingAnchor constraintEqualToAnchor:toolbar.trailingAnchor],
        [stack.topAnchor constraintEqualToAnchor:toolbar.topAnchor],
        [stack.bottomAnchor constraintEqualToAnchor:toolbar.bottomAnchor],
    ]];

    for (NSArray *item in items) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        [btn setImage:[UIImage systemImageNamed:item[0]] forState:UIControlStateNormal];
        [btn addTarget:self action:NSSelectorFromString(item[1]) forControlEvents:UIControlEventTouchUpInside];
        [stack addArrangedSubview:btn];
    }
}

- (void)gbt_copy {
    NSString *sel = self.textDocumentProxy.selectedText;
    if (sel.length > 0) {
        [UIPasteboard generalPasteboard].string = sel;
    } else {
        [[UIApplication sharedApplication] sendAction:@selector(selectAll:) to:nil from:nil forEvent:nil];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] sendAction:@selector(copy:) to:nil from:nil forEvent:nil];
        });
    }
}

- (void)gbt_paste {
    NSString *text = [UIPasteboard generalPasteboard].string;
    if (text) [self.textDocumentProxy insertText:text];
}

- (void)gbt_undo {
    [[UIApplication sharedApplication] sendAction:@selector(undo:) to:nil from:nil forEvent:nil];
}

- (void)gbt_dismiss {
    [self dismissKeyboard];
}

@end

__attribute__((constructor))
static void GBTInit(void) {
    Class cls = objc_getClass("UIInputViewController");
    Method orig = class_getInstanceMethod(cls, @selector(viewDidLoad));
    Method swiz = class_getInstanceMethod(cls, @selector(gbt_viewDidLoad));
    method_exchangeImplementations(orig, swiz);
}
