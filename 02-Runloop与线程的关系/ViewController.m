//
//  ViewController.m
//  02-Runloop与线程的关系
//
//  Created by cooci on 2018/12/5.
//  Copyright © 2018 cooci. All rights reserved.
//

#import "ViewController.h"
//#import "LGThread.h"
#import <objc/message.h>

@interface ViewController ()<NSPortDelegate>
@property (nonatomic, strong) NSPort* subThreadPort;
@property (nonatomic, strong) NSPort* mainThreadPort;
//@property (nonatomic, assign) BOOL isStopping;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

//    [self testThredRunLoop];

//    [self cfTimerDemo];
    
//    [self cfObseverDemo];
    
//    [self source0Demo];
    
    [self setupPort];
}

//- (void)testThredRunLoop  {
//    // runloop 和 线程
//    // 主运行循环
//     CFRunLoopRef mainRunloop = CFRunLoopGetMain();
//     // 当前运行循环
//     CFRunLoopRef currentRunloop = CFRunLoopGetCurrent();
//
//    // 子线程runloop 默认不启动
//
//    self.isStopping = NO;
//    LGThread *thread = [[LGThread alloc] initWithBlock:^{
//
//        // thread.name = nil 因为这个变量只是捕捉
//        // LGThread *thread = nil
//        // thread = 初始化 捕捉一个nil进来
//        NSLog(@"%@---%@",[NSThread currentThread],[[NSThread currentThread] name]);
//        [NSTimer scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
//            NSLog(@"hello word");            // 退出线程--结果runloop也停止了
//            if (self.isStopping) {
//                [NSThread exit];
//            }
//        }];
//         [[NSRunLoop currentRunLoop] run];
//    }];
//
//    thread.name = @"lgcode.com";
//    [thread start];
//}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
//    self.isStopping = YES;
    
    NSMutableArray* components = [NSMutableArray array];
    NSData* data = [@"hello" dataUsingEncoding:NSUTF8StringEncoding];
    [components addObject:data];
    [self.subThreadPort sendBeforeDate:[NSDate date] components:components from:self.mainThreadPort reserved:0];
}

#pragma mark - mode演练
- (void)timerDemo{
    
    // CFRunLoopMode 研究
    CFRunLoopRef lp     = CFRunLoopGetCurrent();
    CFRunLoopMode mode  = CFRunLoopCopyCurrentMode(lp);
    NSLog(@"mode == %@",mode);
    CFArrayRef modeArray= CFRunLoopCopyAllModes(lp);
    NSLog(@"modeArray == %@",modeArray);

    NSTimer *timer = [NSTimer timerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
        NSLog(@"fire in home -- %@",[[NSRunLoop currentRunLoop] currentMode]);
    }];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}

#pragma mark - timer
- (void)cfTimerDemo{
    CFRunLoopTimerContext context = {
        0,
        ((__bridge void *)self),
        NULL,
        NULL,
        NULL
    };
    CFRunLoopRef rlp = CFRunLoopGetCurrent();
    /**
     参数一:用于分配对象的内存
     参数二:在什么是触发 (距离现在)
     参数三:每隔多少时间触发一次
     参数四:未来参数
     参数五:CFRunLoopObserver的优先级 当在Runloop同一运行阶段中有多个CFRunLoopObserver 正常情况下使用0
     参数六:回调,比如触发事件,我就会来到这里
     参数七:上下文记录信息
     */
    CFRunLoopTimerRef timerRef = CFRunLoopTimerCreate(kCFAllocatorDefault, 0, 1, 0, 0, lgRunLoopTimerCallBack, &context);
    CFRunLoopAddTimer(rlp, timerRef, kCFRunLoopDefaultMode);

}

void lgRunLoopTimerCallBack(CFRunLoopTimerRef timer, void *info){
    NSLog(@"%@---%@",timer,info);
}

#pragma mark - observe
- (void)cfObseverDemo{
    
    CFRunLoopObserverContext context = {
        0,
        ((__bridge void *)self),
        NULL,
        NULL,
        NULL
    };
    CFRunLoopRef rlp = CFRunLoopGetCurrent();
    /**
     参数一:用于分配对象的内存
     参数二:你关注的事件
          kCFRunLoopEntry=(1<<0),
          kCFRunLoopBeforeTimers=(1<<1),
          kCFRunLoopBeforeSources=(1<<2),
          kCFRunLoopBeforeWaiting=(1<<5),
          kCFRunLoopAfterWaiting=(1<<6),
          kCFRunLoopExit=(1<<7),
          kCFRunLoopAllActivities=0x0FFFFFFFU
     参数三:CFRunLoopObserver是否循环调用
     参数四:CFRunLoopObserver的优先级 当在Runloop同一运行阶段中有多个CFRunLoopObserver 正常情况下使用0
     参数五:回调,比如触发事件,我就会来到这里
     参数六:上下文记录信息
     */
    CFRunLoopObserverRef observerRef = CFRunLoopObserverCreate(kCFAllocatorDefault, kCFRunLoopAllActivities, YES, 0, lgRunLoopObserverCallBack, &context);
    CFRunLoopAddObserver(rlp, observerRef, kCFRunLoopDefaultMode);
}

void lgRunLoopObserverCallBack(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info){
    NSLog(@"%lu-%@",activity,info);
}

#pragma mark - source0:演练

// 就是喜欢玩一下: 我们下面来自定义一个source
- (void)source0Demo{
    
    CFRunLoopSourceContext context = {
        0,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        schedule,
        cancel,
        perform,
    };
    /**
     
     参数一:传递NULL或kCFAllocatorDefault以使用当前默认分配器。
     参数二:优先级索引，指示处理运行循环源的顺序。这里我传0为了的就是自主回调
     参数三:为运行循环源保存上下文信息的结构
     */
    CFRunLoopSourceRef source0 = CFRunLoopSourceCreate(CFAllocatorGetDefault(), 0, &context);
    CFRunLoopRef rlp = CFRunLoopGetCurrent();
    // source --> runloop 指定了mode  那么此时我们source就进入待绪状态
    CFRunLoopAddSource(rlp, source0, kCFRunLoopDefaultMode);
    // 一个执行信号
    CFRunLoopSourceSignal(source0);
    // 唤醒 run loop 防止沉睡状态
    CFRunLoopWakeUp(rlp);
    // 取消 移除
    CFRunLoopRemoveSource(rlp, source0, kCFRunLoopDefaultMode);
    CFRelease(rlp);
}

void schedule(void *info, CFRunLoopRef rl, CFRunLoopMode mode){
    NSLog(@"准备代发");
}

void perform(void *info){
    NSLog(@"执行吧,骚年");
}

void cancel(void *info, CFRunLoopRef rl, CFRunLoopMode mode){
    NSLog(@"取消了,终止了!!!!");
}

#pragma mark - source1: port演示

- (void)setupPort{
    
    self.mainThreadPort = [NSPort port];
    self.mainThreadPort.delegate = self;
    // port - source1 -- runloop
    [[NSRunLoop currentRunLoop] addPort:self.mainThreadPort forMode:NSDefaultRunLoopMode];

    [self task];
}

- (void) task {
    NSThread *thread = [[NSThread alloc] initWithBlock:^{
        self.subThreadPort = [NSPort port];
        self.subThreadPort.delegate = self;
        
        [[NSRunLoop currentRunLoop] addPort:self.subThreadPort forMode:NSDefaultRunLoopMode];
        [[NSRunLoop currentRunLoop] run];
    }];
    
    [thread start];
    // 主线 -- 子线程
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSLog(@"%@", [NSThread currentThread]); // 3

        NSString *str;
        dispatch_async(dispatch_get_main_queue(), ^{
            // 1
            NSLog(@"%@", [NSThread currentThread]);

        });
    });
}

// 线程之间通讯
// 主线程 -- data
// 子线程 -- data1
// 更加低层 -- 内核
// mach

- (void)handlePortMessage:(id)message {
    NSLog(@"%@", [NSThread currentThread]); // 3 1

    unsigned int count = 0;
    Ivar *ivars = class_copyIvarList([message class], &count);
    for (int i = 0; i<count; i++) {
        
        NSString *name = [NSString stringWithUTF8String:ivar_getName(ivars[i])];
//        NSLog(@"%@",name);
    }
    
    sleep(1);
    if (![[NSThread currentThread] isMainThread]) {

        NSMutableArray* components = [NSMutableArray array];
        NSData* data = [@"woard" dataUsingEncoding:NSUTF8StringEncoding];
        [components addObject:data];

        [self.mainThreadPort sendBeforeDate:[NSDate date] components:components from:self.subThreadPort reserved:0];
    }
}



@end
