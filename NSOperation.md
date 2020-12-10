# 概述

- `NSOperation`、`NSOperationQueue` 是基于 GCD 更高一层的封装，分别对应任务和队列，完全面向对象。但是比 GCD 更简单易用、代码可读性也更高。

- 实现多线程的使用步骤分为两种：

  - 添加到队列中，**在队列的线程中异步执行任务**：

    1. 创建操作：先将需要执行的操作封装到一个 `NSOperation` 对象中。
    2. 创建队列：创建 `NSOperationQueue` 对象。
    3. 将操作加入到队列中：将 `NSOperation` 对象添加到 `NSOperationQueue` 对象中。

  - `start` 方法，**在当前线程中同步执行任务**：

    1. 创建操作：先将需要执行的操作封装到一个 `NSOperation` 对象中。
    2. 调用 `NSOperation` 对象的 `start` 方法。

    > 并非主线程，取决于 `start` 方法执行时所在的线程。

- `NSOperation` 是**非线程安全**的，涉及到线程安全时需要对操作进行加锁。

- 和GCD比较：

  |        | GCD                                        | NSOperation Queue                                           |
  | ------ | ------------------------------------------ | ----------------------------------------------------------- |
  | 层级   | C语言（操作 block）                        | 面向对象（操作 `NSOperation` 对象）                         |
  | 串并行 | Serial 和 Concurrent queue                 | 不支持（可通过 `maxConcurrentOperationCount` 属性变相实现） |
  | 并发数 | 不支持（由系统根据资源情况决定）           | 通过 `maxConcurrentOperationCount` 属性控制                 |
  | 暂停   | `dispatch_suspend` 和 `dispatch_resume`    | 通过 `suspended` 属性控制                                   |
  | 取消   | 不支持                                     | `cancel` 和 `cancelAllOperations`                           |
  | 依赖   | 不支持（可通过 `dispatch_group` 变相实现） | `NSOperation` 对象之间 `addDependency`                      |
  | 顺序   | FIFO                                       | `NSOperation` 对象的状态、优先级和依赖关系                  |
  | 复杂性 | 简单，只需创建 block                       | 复杂，需要使用 `NSOperation` 的子类                         |
  | 复用性 | 差                                         | 强                                                          |

  

# NSOperation

- 任务相关的抽象类，不具备封装操作的能力，必须使用其子类。
  - 使用子类 `NSInvocationOperation`。
  - 使用子类 `NSBlockOperation`。
  - 自定义继承自 NSOperation 的子类，通过实现内部相应的方法来封装操作。
- `NSOperation` 重要方法的默认实现：
  - `main`：空
  - `start`：调用 `main` 方法；执行过程中修改相关状态属性；错误检测，如操作已经完成，已经被取消，尚未准备就绪，正在执行中等，进而不会再去执行相关任务。
  - `cancel`：将 `cancelled` 属性设置为 YES。
- `NSOperation` 的状态属性（`BOOL` 类型）可以通过 KVO 观察获取改变：
  - `isReady`：操作是否准备就绪可以执行；
  - `isExecuting`：操作是否正在执行；
  - `isFinished`：操作是否已经执行完成；
    - 清除其他操作对该操作的依赖；
    - 从队列中移除；
    - 执行 `completionBlock`；
  - `isCancelled`：操作是否已经取消；
  - `isAsynchronous`：操作是否是异步执行，默认为 NO。

## NSInvocationOperation

- 创建任务

  - 方法一：`initWithTarget:selector:object:`

  ```objective-c
  NSInvocationOperation *op = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(task:) object:nil];
  ```

  - 方法二：`initWithInvocation:`

  ```objective-c
  NSMethodSignature *sign = [[self class] instanceMethodSignatureForSelector:@selector(task:)];
  NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sign];
  inv.target = self;
  inv.selector = @selector(task:);
  NSDictionary *dict = @{@"key" : @"value"};
  [inv setArgument:&dict atIndex:2];
  NSInvocationOperation *op = [[NSInvocationOperation alloc] initWithInvocation:inv];
  ```

- 执行任务

  - 方法一：`start` 方法

  ```objective-c
  [op start];
  ```

  - 方法二：添加到队列

  ```objective-c
  NSOperationQueue *queue = [NSOperationQueue mainQueue];
  [queue addOperation:op];
  ```

## NSBlockOperation

- 创建任务：

  - 方法一：创建时附带任务

  ```objective-c
  NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
      NSLog(@"1 %@", [NSThread currentThread]);
  }];
  ```

  - 方法二：单独创建无任务

  ```objective-c
  NSBlockOperation *op = [[NSBlockOperation alloc] init];
  ```

- 追加任务

  ```objective-c
  [op addExecutionBlock:^{
      NSLog(@"2 %@",[NSThread currentThread]);
  }];
  ```

- 执行任务：`start` 方法或添加到队列。

- 当只有一个任务时，`start` 开启的任务一定在当前线程执行，当追加多个任务后，创建任务和追加任务的执行线程则不一定，可能是当前线程，也可能是其他线程。

## 自定义子类

- 对于非并发操作，只需要重写 `main` 方法。
  - `start` 方法返回时操作执行完成；
  - `start` 方法默认实现相关 KVO 功能；
  - `main` 方法中需要创建自动释放池，因为如果是异步操作，无法使用主线程的释放池。
- 对于并发操作，至少需要重写 `start`、`asynchronous`、`executing`、`finished` 方法。
  - `start` 方法不具备异步执行的功能，需要在该方法中自定义实现，不要在该方法中调用 `[super start]`；
  - `asynchronous` 返回 YES，表示并发；
  - `executing` 返回操作的执行状态，在发生变化时需要跑出 KVO；
  - `finished` 返回操作的完成状态，在发生变化时需要跑出 KVO。


# NSOperationQueue

- 将 `NSOperation` 对象添加 `NSOperationQueue` 中，来管理操作对象非常方便：从队列中拿出操作、以及分配到对应线程的工作都是由系统处理的。
- **只要是创建了队列，在队列中的操作，就会在子线程中执行，并且默认并发和异步**。
- 对于添加到队列中的操作，首先进入准备就绪的状态（就绪状态取决于操作之间的依赖关系），然后根据进入就绪状态的操作的开始执行顺序（非结束执行顺序）由操作之间相对的优先级决定（优先级是操作对象自身的属性）。

## 添加操作

- `NSOperationQueue` 队列添加若干个 `NSBlockOperation` 操作：
  - `addOperation:` 添加一个操作。
  - `addOperationWithBlock:` 系统自动封装成一个 `NSBlockOperation` 对象，然后添加到队列中。
  - `addOperations:waitUntilFinished:` 添加多个操作。
  - `addBarrierBlock` 添加一个栅栏操作。

- 操作对象添加 `NSOperationQueue` 中后，不要再修改操作对象的状态。因为操作对象可能会在任何时候运行,改变操作对象的依赖或数据会产生无法预估的问题。只能查看操作对象的状态，比如是否正在运行、等待运行、已经完成等。

## 并发数目

- 设置 `NSOperationQueue` 的属性 `maxConcurrentOperationCount`，表示同一时间最多能调度的 `NSOperation` 对象数。
- 默认值是 -1，不可设置为 0。
- 当设置为 1 时表示 `NSOperationQueue` 每次只能执行一个 `NSOperation` 对象。不过操作对象执行的顺序会依赖于其它因素，比如操作是否准备好和操作对象的优先级等。因此串行化的 operation queue 并不等同于 GCD 中的串行 dispatch queue。

## 操作依赖

- `NSBlockOperation` 操作增加和移除另外一个 `NSBlockOperation` 操作的依赖：

  - `addDependency:` 增加依赖。
  - `removeDependency:` 移除依赖。

  ```objective-c
  NSOperationQueue *queue = [NSOperationQueue mainQueue];
  
  NSBlockOperation *op1 = [NSBlockOperation blockOperationWithBlock:^{
      NSLog(@"任务1");
  }];
  NSBlockOperation *op2 = [NSBlockOperation blockOperationWithBlock:^{
      NSLog(@"任务2");
  }];
  NSBlockOperation *op3 = [NSBlockOperation blockOperationWithBlock:^{
      NSLog(@"任务3");
  }];
  
  // op3操作需要依赖op1和op2操作完成
  [op3 addDependency:op1];
  [op3 addDependency:op2];
      
  // 设置依赖后才可以加入到队列中
  [queue addOperations:@[op3,op2,op1] waitUntilFinished:NO];
  ```

- 具有依赖的操作对象的所有依赖都执行完成才会是 ready 状态。一旦最后一个依赖操作完成，这个操作对象会变成就绪状态并且可以执行。

- 设置依赖后必须使用添加到队列的方式启动，依赖才会生效。不能使用 `start` 方式启动，也不能在添加到队列之后再设置依赖。

- 依赖是不会区分其操作是成功的完成还是失败的完成，即取消操作也视为完成。

## 优先级

- `NSOperation` 的属性 `queuePriority` 决定操作执行的优先顺序：
  - 只适用于同一队列的操作；
  - 依赖关系决定启动顺序，优先级决定开始顺序。
- `NSOperation` 的属性 `qualityOfService` 表示服务质量：
  - 根据CPU，网络和磁盘的分配来创建一个操作的系统优先级；
  - 一个高质量的服务就意味着可以获取更多的资源来更快的完成操作；
  - 正确的设置可以更加智能的分配硬件资源，以便于提高执行效率和控制电量。
- 队列中的操作的执行顺序是根据它们的状态、优先级和依赖关系来决定的。而服务质量则会影响操作的完成时间。

## 暂停取消

- 设置 `NSOperationQueue` 的属性 `suspended`，YES 表示暂停当前队列上尚未开始执行的操作，NO 表示继续执行。

- 调用 `NSOperation` 的方法 `cancel` 取消操作，调用 `NSOperationQueue` 的方法 `cancelAllOperations` 取消队列上的所有操作。
  - 只能取消当前未执行的操作。
  - 取消已经加入队列且依赖其他操作的操作时，系统将忽略依赖关系，并设置状态 `isReady` 为 YES，目的是可以尽快地调用 `start` 方法且不会调用 `main` 方法，并将其从队列中移除。