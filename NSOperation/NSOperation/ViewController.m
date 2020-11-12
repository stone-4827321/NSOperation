//
//  ViewController.m
//  NSOperation
//
//  Created by stone on 2020/9/24.
//

#import "ViewController.h"
#import "STAsynchronousOperation.h"




@interface ViewController ()

@property (nonatomic) NSInteger ticketSurplusCount;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)testThreadSafe {
    self.ticketSurplusCount = 300;

    // 1.创建 queue1,queue1 代表北京火车票售卖窗口
    NSOperationQueue *queue1 = [[NSOperationQueue alloc] init];
    queue1.maxConcurrentOperationCount = 1;

    // 2.创建 queue2,queue2 代表上海火车票售卖窗口
    NSOperationQueue *queue2 = [[NSOperationQueue alloc] init];
    queue2.maxConcurrentOperationCount = 1;

    // 3.创建卖票操作 op1
    __weak typeof(self) weakSelf = self;
    NSBlockOperation *op1 = [NSBlockOperation blockOperationWithBlock:^{
        [weakSelf saleTicketNotSafe];
    }];

    // 4.创建卖票操作 op2
    NSBlockOperation *op2 = [NSBlockOperation blockOperationWithBlock:^{
        [weakSelf saleTicketNotSafe];
    }];
    
    NSBlockOperation *op3 = [NSBlockOperation blockOperationWithBlock:^{
        [weakSelf saleTicketNotSafe];
    }];
    
    NSBlockOperation *op4 = [NSBlockOperation blockOperationWithBlock:^{
        [weakSelf saleTicketNotSafe];
    }];

    // 5.添加操作，开始卖票
    [queue1 addOperation:op1];
    [queue2 addOperation:op2];
    [queue2 addOperation:op3];
    [queue2 addOperation:op4];
}

- (void)saleTicketNotSafe {
    while (1) {
        if (self.ticketSurplusCount > 0) {
            //如果还有票，继续售卖
            self.ticketSurplusCount--;
            NSLog(@"%@", [NSString stringWithFormat:@"剩余票数:%ld 窗口:%@", (long)self.ticketSurplusCount, [NSThread currentThread]]);
            [NSThread sleepForTimeInterval:0.2];
        } else {
            NSLog(@"所有火车票均已售完");
            break;
        }
    }
}

#pragma mark - NSInvocationOperation

- (void)task:(id)object {
    sleep(1);
    NSLog(@"%@ %@", [NSThread currentThread], object);
}

- (IBAction)NSInvocationOperation_start:(id)sender {
    NSInvocationOperation *op = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(task:) object:@{@"key" : @"value"}];
    op.queuePriority = NSOperationQueuePriorityVeryLow;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [op start];
    });
    op.completionBlock = ^{
        NSLog(@"completionBlock %@", [NSThread currentThread]);
    };
    NSLog(@"done");
}

- (IBAction)NSInvocationOperation_queue:(id)sender {
    //NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    NSInvocationOperation *op = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(task:) object:@{@"key" : @"value"}];
    NSOperationQueue *queue = [NSOperationQueue mainQueue];
    [queue addOperation:op];
    op.completionBlock = ^{
        NSLog(@"completionBlock %@", [NSThread currentThread]);
    };
    NSLog(@"done");
}

- (IBAction)NSInvocationOperation_Invocation:(id)sender {
    NSMethodSignature *sign = [[self class] instanceMethodSignatureForSelector:@selector(task:)];
    NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sign];
    inv.target = self;
    inv.selector = @selector(task:);
    NSDictionary *dict = @{@"key" : @"value"};
    [inv setArgument:&dict atIndex:2];
    NSInvocationOperation *op = [[NSInvocationOperation alloc] initWithInvocation:inv];
    [op start];
    op.completionBlock = ^{
        NSLog(@"completionBlock %@", [NSThread currentThread]);
    };
    NSLog(@"done");
}

#pragma mark - NSBlockOperation

- (IBAction)NSBlockOperation_start:(id)sender {
    NSBlockOperation *op = [[NSBlockOperation alloc] init];
//    NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
//        NSLog(@"1 %@", [NSThread currentThread]);
//    }];
    [op addExecutionBlock:^{
        sleep(1);
        NSLog(@"2 %@",[NSThread currentThread]);
    }];
    [op addExecutionBlock:^{
        sleep(1);
        NSLog(@"3 %@",[NSThread currentThread]);
    }];
    [op addExecutionBlock:^{
        sleep(1);
        NSLog(@"4 %@",[NSThread currentThread]);
    }];
    [op addExecutionBlock:^{
        sleep(1);
        NSLog(@"5 %@",[NSThread currentThread]);
    }];

    [op start];
    
    op.completionBlock = ^{
        NSLog(@"completionBlock");
    };
    NSLog(@"done %@", op.executionBlocks);
}

- (IBAction)NSBlockOperation_queue:(id)sender {
    NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"1 %@", [NSThread currentThread]);
    }];
    [op addExecutionBlock:^{
        sleep(1);
        NSLog(@"2 %@",[NSThread currentThread]);
    }];
    [op addExecutionBlock:^{
        sleep(1);
        NSLog(@"3 %@",[NSThread currentThread]);
    }];
    [op addExecutionBlock:^{
        sleep(1);
        NSLog(@"4 %@",[NSThread currentThread]);
    }];
    [op addExecutionBlock:^{
        sleep(1);
        NSLog(@"5 %@",[NSThread currentThread]);
    }];
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperation:op];
    
    op.completionBlock = ^{
        NSLog(@"completionBlock");
    };
    NSLog(@"done %@", op.executionBlocks);
}

#pragma mark - Custom

- (IBAction)Asynchronous_subclass:(id)sender {
    STSynchronousOperation *op = [[STSynchronousOperation alloc] init];
    [op start];
    NSLog(@"done");
}

- (IBAction)Synchronous_subclass:(id)sender {
}

- (IBAction)subclass:(id)sender {
//    STOperation *op = [[STOperation alloc] init];
//    NSLog(@"1 %d",op.finished);
//    [op start];
////    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
////    [queue addOperation:op];
//    NSLog(@"2 %d",op.finished);
//    NSLog(@"done");
//    op.completionBlock = ^{
//        NSLog(@"completionBlock");
//    };
    
    
//    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
//    queue.maxConcurrentOperationCount = 1;
//
//    STCustomOperation *op1 = [[STCustomOperation alloc] init];
//    STCustomOperation *op2 = [[STCustomOperation alloc] init];
//    STCustomOperation *op3 = [[STCustomOperation alloc] init];
//
//    [queue addOperation:op1];
//    [queue addOperation:op2];
//    [queue addOperation:op3];
//
//    op1.completionBlock = ^{
//        NSLog(@"completionBlock");
//    };
//
//       dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//           [op3 cancel];
//       });
    STAsynchronousOperation *op1 = [[STAsynchronousOperation alloc] init];
    [op1 start];
    NSLog(@"done");
}

#pragma mark - NSOperationQueue

- (IBAction)NSOperationQueue:(id)sender {
    //NSOperationQueue *queue = [NSOperationQueue mainQueue];
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];

    NSInvocationOperation *op = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(task:) object:nil];
    [queue addOperation:op];
    [queue addOperationWithBlock:^{
        sleep(1);
        NSLog(@"1 %@", [NSThread currentThread]);
        NSLog(@"！！！%lld", queue.progress.completedUnitCount);
    }];
    [queue addOperationWithBlock:^{
        sleep(0.5);
        NSLog(@"2 %@", [NSThread currentThread]);
    }];
    [queue addBarrierBlock:^{
        sleep(0.5);
        NSLog(@"3 %@", [NSThread currentThread]);
        //NSLog(@"！！！%lu", (unsigned long)queue.operationCount);
    }];
    [queue addOperationWithBlock:^{
        sleep(0.1);
        NSLog(@"4 %@", [NSThread currentThread]);
    }];
    NSLog(@"done");
}

- (IBAction)maxConcurrentOperationCount:(id)sender {
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = 3;
    for (int i = 0; i < 50; i++) {
        [queue addOperationWithBlock:^{
            [NSThread sleepForTimeInterval:0.2];
            NSLog(@"%d %@", i, [NSThread currentThread]);
        }];
    }
}

- (IBAction)suspended:(id)sender {
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    for (int i = 0; i < 10; i++) {
        if (i == 5) {
            queue.suspended = YES;
            sleep(3);
            queue.suspended = NO;
        }
        if (i == 8) {
            [queue cancelAllOperations];
        }
        [queue addOperationWithBlock:^{
            [NSThread sleepForTimeInterval:0.2];
            NSLog(@"%d %@", i, [NSThread currentThread]);
        }];
    }
}

- (IBAction)Dependency:(id)sender {
    NSOperationQueue *queue = [NSOperationQueue mainQueue];

    NSBlockOperation *op1 = [NSBlockOperation blockOperationWithBlock:^{
        sleep(1);
        NSLog(@"任务1");
    }];
    
    NSBlockOperation *op2 = [NSBlockOperation blockOperationWithBlock:^{
        sleep(2);
        NSLog(@"任务2");
    }];
    
    NSBlockOperation *op3 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"任务3");
    }];
    op3.queuePriority = NSOperationQueuePriorityVeryHigh;
    [op3 addDependency:op1];
    [op3 addDependency:op2];
    
    [queue addOperation:op3];
    [queue addOperation:op2];
    [queue addOperation:op1];
    //[queue addOperations:@[op3,op2,op1] waitUntilFinished:NO];
    
    
//    NSArray *list = @[@(20.44), @(21.27), @(21.06), @(21.03), @(20.51),@(21.10),@(21.21),@(20.37),
//                      @(21.25), @(22.03), @(21.08), @(20.51), @(21.15),@(21.09),
//                      @(18.02), @(21.41), @(20.35), @(21.04)];
//    NSArray *list3 = @[@(44+120), @(27+180), @(6+180), @(3+180), @(51+120),@(10+180),@(21+180),@(37+120),
//                      @(25+180), @(3+240), @(8+180), @(51+120), @(15+180),@(9+180),
//                      @(2), @(41+180), @(35+120), @(4+180)];
//    double sum = 0;
//    for (NSNumber *number in list3) {
//        sum = sum + number.doubleValue + 7 * 60;
//    }
//    //sum = sum + (180)+(240);
//    NSLog(@"%f",sum);
//    NSLog(@"%f",sum/18.0/60);
    

    NSArray *list3 = @[@(26+180), @(17+180), @(23+180), @(31+180), @(55+120),@(35+180),@(1+180),@(54+180),@(42+180),
                      @(37+180), @(47+180), @(47+180), @(1+180)];
    double sum = 0;
    for (NSNumber *number in list3) {
        sum = sum + number.doubleValue + 7 * 60;
    }
    //sum = sum + (180)+(240);
    NSLog(@"%f",sum);
    NSLog(@"%f",sum/13.0/60);
}


@end


