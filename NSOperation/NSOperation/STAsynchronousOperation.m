//
//  STCustomOperation.m
//  NSOperation
//
//  Created by stone on 2020/9/27.
//

#import "STAsynchronousOperation.h"



static inline NSString * AFKeyPathFromOperationState(STCustomOperationState state) {
    switch (state) {
        case STCustomOperationState_Ready:
            return @"isReady";
        case STCustomOperationState_Executing:
            return @"isExecuting";
        case STCustomOperationState_Finished:
            return @"isFinished";
    }
}

@interface STObject : NSObject

@end

@implementation STObject

- (void)dealloc {
    NSLog(@"STObject dealloc");
}

@end



@implementation STSynchronousOperation

- (void)main {
    if (!self.isCancelled) {
        sleep(1);
        STObject *object = [[STObject alloc] init];
        NSLog(@" %@",[NSThread currentThread]);
    }
}

@end





@interface STAsynchronousOperation ()

@property (nonatomic, strong) NSLock *lock;

@end

@implementation STAsynchronousOperation

- (instancetype)init {
    if (self = [super init]) {
        _state = STCustomOperationState_Ready;
        _lock = [[NSLock alloc] init];
    }
    return self;
}

- (void)setState:(STCustomOperationState)state {
    [_lock lock];
    NSString *oldStateKey = AFKeyPathFromOperationState(self.state);
    NSString *newStateKey = AFKeyPathFromOperationState(state);
    
    [self willChangeValueForKey:newStateKey];
    [self willChangeValueForKey:oldStateKey];
    _state = state;
    [self didChangeValueForKey:oldStateKey];
    [self didChangeValueForKey:newStateKey];
    [_lock unlock];
}


- (BOOL)isFinished {
    return self.state == STCustomOperationState_Finished;
}

- (BOOL)isExecuting {
    return self.state == STCustomOperationState_Executing;
}

- (BOOL)isReady {
    // 需要考虑super的值
    return self.state == STCustomOperationState_Ready && [super isReady];
}

- (void)cancel {
    if (![self isExecuting] && ![self isFinished]) {
        [super cancel];
        self.state = STCustomOperationState_Finished;
    }
}

- (BOOL)isAsynchronous {
    return YES;
}

// 必须实现
- (void)start {
    [_lock lock];
    // 错误检测
    if ([self isCancelled]) {
        return;
    }
    if ([self isReady]) {
        self.state = STCustomOperationState_Executing;
        // 实现并发
        [NSThread detachNewThreadSelector:@selector(main) toTarget:self withObject:nil];
//        sleep(1);
//        static NSInteger i = 0;
//        NSLog(@"这是一个耗时操作：%@", @(++i));
//        self.state = STCustomOperationState_Finished;
    }
    [_lock unlock];
}

- (void)main {
    @autoreleasepool {
//            [self completeOperation];
        sleep(1);
        static NSInteger i = 0;
        NSLog(@"这是一个耗时操作：%@", @(++i));
        self.state = STCustomOperationState_Finished;
    }
}

@end
