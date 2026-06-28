#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

typedef NS_ENUM(NSInteger, PetMood) {
    PetMoodIdle,
    PetMoodBlink,
    PetMoodHappy,
    PetMoodSquish,
    PetMoodWalkRight,
    PetMoodWalkLeft,
    PetMoodBack
};

@class PetController;

@interface PetView : NSView
@property(nonatomic, assign) BOOL dimmed;
- (void)setMood:(PetMood)mood;
- (void)pop;
- (void)squish;
- (void)bounce;
- (void)breathe;
@end

@interface PetWindow : NSWindow
@property(nonatomic, weak) PetController *petController;
@end

@interface PetController : NSObject
- (void)show;
- (void)handlePrimaryClick;
- (void)handleDoubleClick;
- (void)beginDrag;
- (void)endDrag;
@end

@interface PetView ()
@property(nonatomic, strong) NSImageView *imageView;
@property(nonatomic, strong) NSTextField *speechBubble;
@property(nonatomic, strong) NSTimer *speechTimer;
@end

@implementation PetView

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (!self) {
        return nil;
    }
    self.wantsLayer = YES;
    self.layer.backgroundColor = NSColor.clearColor.CGColor;

    _imageView = [[NSImageView alloc] initWithFrame:self.bounds];
    _imageView.imageScaling = NSImageScaleProportionallyUpOrDown;
    _imageView.wantsLayer = YES;
    _imageView.layer.anchorPoint = CGPointMake(0.5, 0.05);
    [self addSubview:_imageView];

    _speechBubble = [NSTextField labelWithString:@""];
    _speechBubble.alignment = NSTextAlignmentCenter;
    _speechBubble.font = [NSFont systemFontOfSize:15 weight:NSFontWeightSemibold];
    _speechBubble.textColor = [NSColor colorWithCalibratedWhite:0.08 alpha:1.0];
    _speechBubble.backgroundColor = [NSColor colorWithCalibratedWhite:1.0 alpha:0.92];
    _speechBubble.bezeled = NO;
    _speechBubble.drawsBackground = YES;
    _speechBubble.wantsLayer = YES;
    _speechBubble.layer.cornerRadius = 12;
    _speechBubble.layer.borderColor = [NSColor colorWithCalibratedWhite:0.08 alpha:0.16].CGColor;
    _speechBubble.layer.borderWidth = 1;
    _speechBubble.alphaValue = 0;
    [self addSubview:_speechBubble];

    return self;
}

- (void)layout {
    [super layout];
    self.imageView.frame = self.bounds;
    self.speechBubble.frame = NSMakeRect(NSMidX(self.bounds) - 92, NSMaxY(self.bounds) - 56, 184, 34);
}

- (BOOL)isFlipped {
    return NO;
}

- (NSString *)imageNameForMood:(PetMood)mood {
    switch (mood) {
        case PetMoodBlink:
            return @"carrot_front";
        case PetMoodHappy:
            return @"carrot_front";
        case PetMoodSquish:
            return @"carrot_squish";
        case PetMoodWalkRight:
            return @"carrot_side";
        case PetMoodWalkLeft:
            return @"carrot_side_left";
        case PetMoodBack:
            return @"carrot_back";
        case PetMoodIdle:
        default:
            return @"carrot_front";
    }
}

- (void)setMood:(PetMood)mood {
    self.imageView.image = [NSImage imageNamed:[self imageNameForMood:mood]];
    switch (mood) {
        case PetMoodHappy:
            [self sayRandom:@[@"卜卜！", @"嘿嘿", @"摸到了"]];
            break;
        case PetMoodSquish:
            [self sayRandom:@[@"别捏太扁", @"软乎乎"]];
            break;
        case PetMoodBack:
            [self sayRandom:@[@"我转过去啦", @"晒晒叶子"]];
            break;
        case PetMoodWalkLeft:
        case PetMoodWalkRight:
            [self hideSpeech];
            break;
        default:
            break;
    }
}

- (void)setDimmed:(BOOL)dimmed {
    _dimmed = dimmed;
    self.alphaValue = dimmed ? 0.72 : 1.0;
}

- (void)sayRandom:(NSArray<NSString *> *)options {
    if (options.count == 0) {
        return;
    }
    self.speechBubble.stringValue = options[arc4random_uniform((uint32_t)options.count)];
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.16;
        self.speechBubble.animator.alphaValue = 1;
    } completionHandler:nil];

    [self.speechTimer invalidate];
    self.speechTimer = [NSTimer scheduledTimerWithTimeInterval:1.15 repeats:NO block:^(NSTimer *timer) {
        [self hideSpeech];
    }];
    [[NSRunLoop mainRunLoop] addTimer:self.speechTimer forMode:NSRunLoopCommonModes];
}

- (void)hideSpeech {
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.2;
        self.speechBubble.animator.alphaValue = 0;
    } completionHandler:nil];
}

- (void)animateScaleWithValues:(NSArray<NSNumber *> *)values duration:(CFTimeInterval)duration {
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    animation.values = values;
    animation.duration = duration;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [self.imageView.layer addAnimation:animation forKey:@"scale"];
}

- (void)pop {
    [self animateScaleWithValues:@[@1.0, @1.08, @0.98, @1.0] duration:0.42];
}

- (void)squish {
    [self animateScaleWithValues:@[@1.0, @1.16, @0.88, @1.0] duration:0.38];
}

- (void)bounce {
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"position.y"];
    animation.values = @[@0, @16, @0, @8, @0];
    animation.duration = 0.55;
    animation.additive = YES;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [self.imageView.layer addAnimation:animation forKey:@"bounce"];
}

- (void)breathe {
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    animation.fromValue = @0.985;
    animation.toValue = @1.015;
    animation.duration = 1.2;
    animation.autoreverses = YES;
    animation.repeatCount = 3;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [self.imageView.layer addAnimation:animation forKey:@"breathe"];
}

@end

@implementation PetWindow {
    NSPoint _mouseDownLocation;
    BOOL _isDraggingPet;
}

- (instancetype)initWithContentRect:(NSRect)contentRect {
    self = [super initWithContentRect:contentRect
                            styleMask:NSWindowStyleMaskBorderless
                              backing:NSBackingStoreBuffered
                                defer:NO];
    if (!self) {
        return nil;
    }
    self.opaque = NO;
    self.backgroundColor = NSColor.clearColor;
    self.hasShadow = NO;
    self.acceptsMouseMovedEvents = YES;
    self.movableByWindowBackground = NO;
    return self;
}

- (BOOL)canBecomeKeyWindow {
    return YES;
}

- (void)mouseDown:(NSEvent *)event {
    _mouseDownLocation = event.locationInWindow;
    _isDraggingPet = NO;
    [self.petController beginDrag];
}

- (void)mouseDragged:(NSEvent *)event {
    NSPoint current = event.locationInWindow;
    CGFloat dx = current.x - _mouseDownLocation.x;
    CGFloat dy = current.y - _mouseDownLocation.y;
    if (fabs(dx) + fabs(dy) > 3) {
        _isDraggingPet = YES;
    }
    NSRect frame = self.frame;
    frame.origin.x += dx;
    frame.origin.y += dy;
    [self setFrame:frame display:YES];
}

- (void)mouseUp:(NSEvent *)event {
    [self.petController endDrag];
    if (_isDraggingPet) {
        return;
    }
    if (event.clickCount >= 2) {
        [self.petController handleDoubleClick];
    } else {
        [self.petController handlePrimaryClick];
    }
}

@end

@interface PetController ()
@property(nonatomic, strong) PetWindow *window;
@property(nonatomic, strong) PetView *petView;
@property(nonatomic, strong) NSTimer *idleTimer;
@property(nonatomic, strong) NSTimer *actionResetTimer;
@property(nonatomic, strong) NSTimer *animationTimer;
@property(nonatomic, assign) NSInteger step;
@property(nonatomic, assign) CGFloat scale;
@property(nonatomic, assign) BOOL pinned;
@property(nonatomic, assign) BOOL napping;
@end

@implementation PetController

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }

    _scale = 0.42;
    _pinned = YES;
    _petView = [[PetView alloc] initWithFrame:NSMakeRect(0, 0, [self currentSize].width, [self currentSize].height)];
    _window = [[PetWindow alloc] initWithContentRect:_petView.frame];
    _window.petController = self;
    _window.contentView = _petView;
    [_window setFrame:[self initialFrame] display:NO];
    [self configureMenu];
    [self updateLevel];
    [_petView setMood:PetMoodIdle];
    return self;
}

- (NSSize)currentSize {
    return NSMakeSize(640 * self.scale, 640 * self.scale);
}

- (NSRect)initialFrame {
    NSRect visible = NSScreen.mainScreen.visibleFrame;
    NSSize size = [self currentSize];
    return NSMakeRect(NSMaxX(visible) - size.width - 80, NSMinY(visible) + 56, size.width, size.height);
}

- (void)show {
    [self.window orderFrontRegardless];
    [self startBehaviorLoop];
    [NSApp activateIgnoringOtherApps:NO];
}

- (void)startBehaviorLoop {
    [self.idleTimer invalidate];
    self.idleTimer = [NSTimer scheduledTimerWithTimeInterval:3.0 repeats:YES block:^(NSTimer *timer) {
        [self chooseNextAction];
    }];
    [[NSRunLoop mainRunLoop] addTimer:self.idleTimer forMode:NSRunLoopCommonModes];
}

- (void)chooseNextAction {
    if (self.napping) {
        [self.petView breathe];
        return;
    }

    uint32_t roll = arc4random_uniform(100);
    if (roll < 34) {
        [self blink];
    } else if (roll < 62) {
        [self wander];
    } else if (roll < 78) {
        [self showMood:PetMoodBack duration:1.4];
    } else if (roll < 91) {
        [self.petView bounce];
    } else {
        [self showMood:PetMoodHappy duration:1.0];
        [self.petView pop];
    }
}

- (void)blink {
    [self showMood:PetMoodBlink duration:0.22];
}

- (void)showMood:(PetMood)mood duration:(NSTimeInterval)duration {
    [self.petView setMood:mood];
    [self.actionResetTimer invalidate];
    self.actionResetTimer = [NSTimer scheduledTimerWithTimeInterval:duration repeats:NO block:^(NSTimer *timer) {
        [self.petView setMood:self.napping ? PetMoodBack : PetMoodIdle];
    }];
    [[NSRunLoop mainRunLoop] addTimer:self.actionResetTimer forMode:NSRunLoopCommonModes];
}

- (void)wander {
    [self.animationTimer invalidate];
    NSRect visible = self.window.screen.visibleFrame;
    if (NSIsEmptyRect(visible)) {
        visible = NSScreen.mainScreen.visibleFrame;
    }

    __block NSRect frame = self.window.frame;
    CGFloat sign = arc4random_uniform(2) == 0 ? -1.0 : 1.0;
    CGFloat distance = (60 + arc4random_uniform(121)) * sign;
    CGFloat targetX = MIN(MAX(NSMinX(frame) + distance, NSMinX(visible) + 12), NSMaxX(visible) - NSWidth(frame) - 12);
    PetMood direction = targetX >= NSMinX(frame) ? PetMoodWalkRight : PetMoodWalkLeft;
    NSInteger totalSteps = 30;
    CGFloat delta = (targetX - NSMinX(frame)) / totalSteps;
    self.step = 0;
    [self.petView setMood:direction];

    self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:0.035 repeats:YES block:^(NSTimer *timer) {
        self.step += 1;
        frame.origin.x += delta;
        frame.origin.y += (self.step % 2 == 0) ? 1.0 : -1.0;
        [self.window setFrame:frame display:YES];
        if (self.step >= totalSteps) {
            [timer invalidate];
            [self.petView setMood:PetMoodIdle];
        }
    }];
    [[NSRunLoop mainRunLoop] addTimer:self.animationTimer forMode:NSRunLoopCommonModes];
}

- (void)setPetScale:(CGFloat)newScale {
    self.scale = newScale;
    NSRect frame = self.window.frame;
    CGFloat oldMidX = NSMidX(frame);
    CGFloat oldMinY = NSMinY(frame);
    frame.size = [self currentSize];
    frame.origin.x = oldMidX - NSWidth(frame) / 2;
    frame.origin.y = oldMinY;
    [self.window setFrame:frame display:YES animate:YES];
    self.petView.frame = NSMakeRect(0, 0, frame.size.width, frame.size.height);
    self.petView.needsLayout = YES;
}

- (void)configureMenu {
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"卜卜"];
    NSArray<NSMenuItem *> *items = @[
        [[NSMenuItem alloc] initWithTitle:@"摸摸卜卜" action:@selector(menuPet:) keyEquivalent:@""],
        [[NSMenuItem alloc] initWithTitle:@"让它走走" action:@selector(menuWander:) keyEquivalent:@""],
        [[NSMenuItem alloc] initWithTitle:@"睡觉/唤醒" action:@selector(menuNap:) keyEquivalent:@""]
    ];
    for (NSMenuItem *item in items) {
        item.target = self;
        [menu addItem:item];
    }
    [menu addItem:NSMenuItem.separatorItem];

    NSArray<NSMenuItem *> *sizeItems = @[
        [[NSMenuItem alloc] initWithTitle:@"小号" action:@selector(menuSmall:) keyEquivalent:@"1"],
        [[NSMenuItem alloc] initWithTitle:@"中号" action:@selector(menuMedium:) keyEquivalent:@"2"],
        [[NSMenuItem alloc] initWithTitle:@"大号" action:@selector(menuLarge:) keyEquivalent:@"3"]
    ];
    for (NSMenuItem *item in sizeItems) {
        item.target = self;
        [menu addItem:item];
    }
    [menu addItem:NSMenuItem.separatorItem];

    NSMenuItem *pinItem = [[NSMenuItem alloc] initWithTitle:@"切换置顶" action:@selector(menuPin:) keyEquivalent:@"t"];
    pinItem.target = self;
    pinItem.state = NSControlStateValueOn;
    [menu addItem:pinItem];
    [menu addItem:NSMenuItem.separatorItem];

    NSMenuItem *quitItem = [[NSMenuItem alloc] initWithTitle:@"退出" action:@selector(menuQuit:) keyEquivalent:@"q"];
    quitItem.target = self;
    [menu addItem:quitItem];
    self.petView.menu = menu;
}

- (void)updateLevel {
    self.window.level = self.pinned ? NSFloatingWindowLevel : NSNormalWindowLevel;
    self.window.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces |
        NSWindowCollectionBehaviorFullScreenAuxiliary |
        NSWindowCollectionBehaviorStationary;
}

- (void)sleep {
    self.napping = YES;
    [self.animationTimer invalidate];
    [self.actionResetTimer invalidate];
    [self.petView setMood:PetMoodBack];
    self.petView.dimmed = YES;
    [self.petView breathe];
}

- (void)wake {
    self.napping = NO;
    self.petView.dimmed = NO;
    [self showMood:PetMoodHappy duration:1.0];
    [self.petView pop];
}

- (void)handlePrimaryClick {
    if (self.napping) {
        [self wake];
        return;
    }
    [self showMood:PetMoodHappy duration:1.4];
    [self.petView pop];
}

- (void)handleDoubleClick {
    if (self.napping) {
        [self wake];
        return;
    }
    [self showMood:PetMoodSquish duration:0.7];
    [self.petView squish];
}

- (void)beginDrag {
    [self.animationTimer invalidate];
    [self showMood:PetMoodSquish duration:0.35];
}

- (void)endDrag {
    [self showMood:PetMoodIdle duration:0.2];
}

- (void)menuPet:(id)sender {
    [self handlePrimaryClick];
}

- (void)menuWander:(id)sender {
    [self wander];
}

- (void)menuNap:(id)sender {
    self.napping ? [self wake] : [self sleep];
}

- (void)menuSmall:(id)sender {
    [self setPetScale:0.30];
}

- (void)menuMedium:(id)sender {
    [self setPetScale:0.42];
}

- (void)menuLarge:(id)sender {
    [self setPetScale:0.58];
}

- (void)menuPin:(NSMenuItem *)sender {
    self.pinned = !self.pinned;
    sender.state = self.pinned ? NSControlStateValueOn : NSControlStateValueOff;
    [self updateLevel];
}

- (void)menuQuit:(id)sender {
    [NSApp terminate:nil];
}

@end

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property(nonatomic, strong) PetController *petController;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
    self.petController = [[PetController alloc] init];
    [self.petController show];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return NO;
}

@end

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSApplication *application = NSApplication.sharedApplication;
        AppDelegate *delegate = [[AppDelegate alloc] init];
        application.delegate = delegate;
        [application run];
    }
    return 0;
}
