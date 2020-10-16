//
//  STCustomOperation.h
//  NSOperation
//
//  Created by stone on 2020/9/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM (NSUInteger, STCustomOperationState) {
    STCustomOperationState_Ready,
    STCustomOperationState_Executing,
    STCustomOperationState_Finished
};

@interface STAsynchronousOperation : NSOperation

@property (nonatomic) STCustomOperationState state;

@end

@interface STSynchronousOperation : NSOperation

@end

NS_ASSUME_NONNULL_END
