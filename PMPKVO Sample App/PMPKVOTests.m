//
//  PMPKVOTests.m
//  PMPKVO Sample App
//
//  Created by Mark Aufflick on 12/03/12.
//  Copyright (c) 2012 Pumptheory Pty Ltd. All rights reserved.
//

#import "PMPKVOTests.h"

#import "TestObservee.h"
#import "PMPKVObservation.h"

@interface PMPKVOTests ()

@property (retain) TestObservee * observee;
@property BOOL changeObserved;
@property (readonly) NSArray * testSelectors;
@property NSInteger currentTestSelectorIndex;
@property (retain) PMPKVObservation * kvo;

- (void)next;
- (void)checkObservationAndNext;
- (NSString *)currentTest;

@end


@implementation PMPKVOTests

@synthesize observee;
@synthesize changeObserved;
@synthesize currentTestSelectorIndex;
@synthesize kvo = _kvo;

- (NSArray *)testSelectors
{
    return [NSArray arrayWithObjects:
            @"test1NormalKVO",
            @"test1cleanup",
            @"test2simplePMPObservation",
            @"test2cleanup",
            @"test3ObserveeReleasedEarly",
            @"test3cleanup",
            @"test4simpleBlockObservation",
            @"test4cleanup",
            @"test5helperMethodSimplePMPObservation",
            @"test5cleanup",
            @"test6helperMethodObserveeReleasedEarly",
            @"test6cleanup",
            @"test7helperMethodSimpleBlockObservation",
            @"test7cleanup",
            nil];
}

- (void)test1NormalKVO
{
    self.observee = [[[TestObservee alloc] init] autorelease];
    self.observee.observeMe = @"Orig text";
    
    [self.observee addObserver:self forKeyPath:@"observeMe" options:0 context:(void *)1];
    
    self.observee.observeMe = @"New text";
    
    [self checkObservationAndNext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    // checking context to make sure we don't get called for PMPKVO
    NSAssert(object == self.observee && context == (void *)1, @"recieved wrong kvo");
    self.changeObserved = YES;
}

- (void)test1cleanup
{
    [self.observee removeObserver:self forKeyPath:@"observeMe"];
    self.observee = nil; // shouldn't cause any KVO warnings in console
    
    [self next];
}

- (void)test2ObservationViaSelecterForObservation:(id)obs changes:(NSDictionary *)changes;
{
    NSAssert([[self currentTest] isEqualToString:@"test2simplePMPObservation"], @"received wrong kvo");
    self.changeObserved = YES;
}

- (void)test2simplePMPObservation
{
    self.observee = [[[TestObservee alloc] init] autorelease];
    self.observee.observeMe = @"Orig text";
    
    self.kvo = [[[PMPKVObservation alloc] init] autorelease];
    self.kvo.observee = self.observee;
    self.kvo.observer = self;
    self.kvo.keyPath = @"observeMe";
    self.kvo.selector = @selector(test2ObservationViaSelecterForObservation:changes:);
    
    [self.kvo observe];
    
    self.observee.observeMe = @"New text";
    
    [self checkObservationAndNext];
}

- (void)test2cleanup
{
    self.kvo = nil; // will remove the observation
    self.observee = nil; // shouldn't cause any KVO warnings in console
    
    [self next];
}

- (void)test3ObservationViaSelecterForObject:(id)obj changes:(NSDictionary *)changes;
{
    NSAssert([[self currentTest] isEqualToString:@"test3ObserveeReleasedEarly"], @"received wrong kvo");
    self.changeObserved = YES;
}

- (void)test3ObserveeReleasedEarly
{
    self.observee = [[[TestObservee alloc] init] autorelease];
    self.observee.observeMe = @"Orig text";
    
    self.kvo = [[[PMPKVObservation alloc] init] autorelease];
    self.kvo.observee = self.observee;
    self.kvo.observer = self;
    self.kvo.keyPath = @"observeMe";
    self.kvo.selector = @selector(test3ObservationViaSelecterForObject:changes:);
    
    [self.kvo observe];
    
    self.observee.observeMe = @"New text";
    
    [self checkObservationAndNext];
}

- (void)test3cleanup
{
    self.observee = nil; // would cause KVO warning if not for the swizzled dealloc on observee
    self.kvo = nil; // would crash if not for the swizzled dealloc on observee
    
    [self next];
}

- (void)test4simpleBlockObservation
{
    self.observee = [[[TestObservee alloc] init] autorelease];
    self.observee.observeMe = @"Orig text";
    
    self.kvo = [[[PMPKVObservation alloc] init] autorelease];
    self.kvo.observee = self.observee;
    self.kvo.keyPath = @"observeMe";
    
    __block typeof(self) _self = self;
    
    [self.kvo setCallbackBlock:^(PMPKVObservation * obs, NSDictionary * change) {
        NSAssert([[_self currentTest] isEqualToString:@"test4simpleBlockObservation"], @"received wrong kvo");
        _self.changeObserved = YES;
    }];
    
    [self.kvo observe];
    
    self.observee.observeMe = @"New text";
    
    //[self checkObservationAndNext];
    [self next];
}

- (void)test4cleanup
{
    self.kvo = nil; // will remove the observation
    self.observee = nil; // shouldn't cause any KVO warnings in console
    
    [self next];
}

- (void)test5ObservationViaSelecterForObservation:(id)obs changes:(NSDictionary *)changes;
{
    NSAssert([[self currentTest] isEqualToString:@"test5helperMethodSimplePMPObservation"], @"received wrong kvo");
    self.changeObserved = YES;
}

- (void)test5helperMethodSimplePMPObservation
{
    self.observee = [[[TestObservee alloc] init] autorelease];
    self.observee.observeMe = @"Orig text";
    
    self.kvo = [PMPKVObservation observe:self.observee
                                observer:self
                                selector:@selector(test5ObservationViaSelecterForObservation:changes:)
                                 keyPath:@"observeMe"
                                 options:0];
        
    self.observee.observeMe = @"New text";
    
    [self checkObservationAndNext];
}

- (void)test5cleanup
{
    self.kvo = nil; // will remove the observation
    self.observee = nil; // shouldn't cause any KVO warnings in console
    
    [self next];
}

- (void)test6ObservationViaSelecterForObject:(id)obj changes:(NSDictionary *)changes;
{
    NSAssert([[self currentTest] isEqualToString:@"test6helperMethodObserveeReleasedEarly"], @"received wrong kvo");
    self.changeObserved = YES;
}

- (void)test6helperMethodObserveeReleasedEarly
{
    self.observee = [[[TestObservee alloc] init] autorelease];
    self.observee.observeMe = @"Orig text";
    
    self.kvo = [PMPKVObservation observe:self.observee
                                observer:self
                                selector:@selector(test6ObservationViaSelecterForObject:changes:)
                                 keyPath:@"observeMe"
                                 options:0];
    
    self.observee.observeMe = @"New text";
    
    [self checkObservationAndNext];
}

- (void)test6cleanup
{
    self.observee = nil; // would cause KVO warning if not for the swizzled dealloc on observee
    self.kvo = nil; // would crash if not for the swizzled dealloc on observee
    
    [self next];
}

- (void)test7helperMethodSimpleBlockObservation
{
    self.observee = [[[TestObservee alloc] init] autorelease];
    self.observee.observeMe = @"Orig text";
    
    __block typeof(self) _self = self;
    
    self.kvo = [PMPKVObservation observe:self.observee
                                 keyPath:@"observeMe"
                                 options:0
                                callback:^(PMPKVObservation *observation, NSDictionary *changeDictionary) {
                                    NSAssert([[_self currentTest] isEqualToString:@"test7helperMethodSimpleBlockObservation"], @"received wrong kvo");
                                    _self.changeObserved = YES;
                                }];
        
    self.observee.observeMe = @"New text";
    
    //[self checkObservationAndNext];
    [self next];
}

- (void)test7cleanup
{
    self.kvo = nil; // will remove the observation
    self.observee = nil; // shouldn't cause any KVO warnings in console
    
    [self next];
}

/*
 *
 * Machinery
 *
 */

- (void)runTests
{
    self.currentTestSelectorIndex = -1;
    [self next];
}

- (NSString *)currentTest
{
    return [self.testSelectors objectAtIndex:self.currentTestSelectorIndex];
}

// NB: doing all this in seperate runloop cycles to make sure not-yet autoreleased objects
//     don't mask any issues

- (void)_next
{
    self.currentTestSelectorIndex++;
    if (self.currentTestSelectorIndex < [self.testSelectors count])
    {
        NSLog(@"Running test method: %@", [self currentTest]); //TODO: log to window
        [self performSelector:NSSelectorFromString([self currentTest])];
    }
    else
    {
        NSAlert * alert = [NSAlert alertWithMessageText:@"Tests complete"
                                          defaultButton:@"Cool"
                                        alternateButton:nil
                                            otherButton:nil
                              informativeTextWithFormat:@"Make sure you check the logs for KVO warnings"];
        [alert runModal];
    }
}

- (void)next
{
    [self performSelector:@selector(_next) withObject:nil afterDelay:0];
}

- (void)_checkObservationAndNext
{
    NSAssert(self.changeObserved, @"No change observed");
    
    NSLog(@"Confirmed change observation");
    
    self.changeObserved = NO;
    
    [self _next];
}

- (void)checkObservationAndNext
{
    [self performSelector:@selector(_checkObservationAndNext) withObject:nil afterDelay:0];
}

@end