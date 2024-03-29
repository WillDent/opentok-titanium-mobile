/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2012 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import "ComTokboxTiOpentokSessionProxy.h"
#import "ComTokboxTiOpentokSubscriberProxy.h"
#import "ComTokboxTiOpentokStreamProxy.h"
#import <Opentok/OTSubscriber.h>

@implementation ComTokboxTiOpentokSubscriberProxy

#pragma mark - Helpers

// TODO: Localization
+ (NSDictionary *)dictionaryForOTError:(OTError *)error
{
    NSString *message;
    switch ([error code]) {
        case OTFailedToConnect:
            message = @"Subscriber failed to connect to stream. Can reattempt connection.";
            break;
            
        case OTConnectionTimedOut:
            message = @"Subscriber timed out while attempting to connect to stream. Can reattempt connection.";
            break;
            
        case OTNoStreamMedia:
            message = @"The stream has no audio or video to subscribe to.";
            break;
            
        case OTInitializationFailure:
            message = @"Subscriber failed to initialize.";
            break;
            
        default:
            message = @"An unknown error occurred";
            break;
    }
    
    return [NSDictionary dictionaryWithObject:message forKey:@"message"];
}

#pragma mark - Initialization

// Overriding designated initializer in order to prevent instantiation from javascript land (hopefully)
- (id)initWithSessionProxy:(ComTokboxTiOpentokSessionProxy *)sessionProxy 
                    stream:(ComTokboxTiOpentokStreamProxy *)streamProxy
                     audio:(BOOL)subscribeToAudio 
                     video:(BOOL)subscribeToVideo;
{
    
    self = [super init];
    
    if (self) {
        // unretained, unsafe reference. be careful
        _sessionProxy = sessionProxy;
        _streamProxy = streamProxy;
        
        _subscriber = [[OTSubscriber alloc] initWithStream:streamProxy.stream delegate:self];
        _subscriber.subscribeToAudio = subscribeToAudio;
        _subscriber.subscribeToVideo = subscribeToVideo;
        
        _subscriberViewProxy = nil;
        
    }
    
    return self;
}

#pragma mark - Deallocation

- (void)dealloc {
    [_subscriber release];
    [_subscriberViewProxy _invalidate];
    [_subscriberViewProxy release];
    
    [super dealloc];
}

#pragma mark - Obj-C only Methods
- (OTSubscriber *)_subscriber
{
    return _subscriber;
}

#pragma mark - Properties

-(id)session
{
    return _sessionProxy;
}

-(id)stream
{
    return _streamProxy;
}

-(ComTokboxTiOpentokSubscriberViewProxy *)view
{
    // TODO: Probably not the best way to return a view, should somehow indicate that createView should
    //       be called first
    if (_subscriberViewProxy) return _subscriberViewProxy;
    return nil;
}

-(id)subscribeToAudio
{
    return NUMBOOL(_subscriber.subscribeToAudio);
}

-(id)subscribeToVideo
{
    return NUMBOOL(_subscriber.subscribeToVideo);
}

#pragma mark - Methods

-(void)close:(id)args
{
    [_subscriber close];
    [_sessionProxy removeSubscriber:self];
}

// TODO: this needs to run on a UI thread?
//       ENSURE_UI_THREAD_1(arg) would not work because the method returns non-void
-(ComTokboxTiOpentokSubscriberViewProxy *)createView:(id)args
{
    NSLog(@"[INFO] creating a subscriber view proxy");
    if (!_subscriberViewProxy) {
        ENSURE_SINGLE_ARG(args, NSDictionary);
        _subscriberViewProxy = [[ComTokboxTiOpentokSubscriberViewProxy alloc] initWithSubscriberProxy:self andProperties:args];
        NSLog(@"[INFO] subscriber view proxy instance created: %@", _subscriberViewProxy.description);
    }
    // TODO: assign properties to existing subscriberViewProxy
    return _subscriberViewProxy;
}

#pragma mark - Subscriber Delegate

- (void)subscriberDidConnectToStream:(OTSubscriber*)subscriber
{
    if ([self _hasListeners:@"subscriberConnected"]) {
        [self fireEvent:@"subscriberConnected"];
    }
}

- (void)subscriber:(OTSubscriber*)subscriber didFailWithError:(OTError*)error
{
    if ([self _hasListeners:@"subscriberFailed"]) {
        
        NSDictionary *errorObject = [ComTokboxTiOpentokSubscriberProxy dictionaryForOTError:error];
        NSDictionary *eventParameters = [NSDictionary dictionaryWithObject:errorObject forKey:@"error"];
        
        [self fireEvent:@"subscriberFailed" withObject:eventParameters];
    }
}

- (void)subscriberVideoDataReceived:(OTSubscriber*)subscriber
{
    if ([self _hasListeners:@"subscriberStarted"]) {
        [self fireEvent:@"subscriberStarted"];
    }
}



@end
