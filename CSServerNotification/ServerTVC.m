//
//  ServerTVC.m
//  CSServerNotification
//
//  Created by Tyler  Much on 10/7/14.
//  Copyright (c) 2014 Tyler Much. All rights reserved.
//

#import "ServerTVC.h"
#import "GCDAsyncUdpSocket.h"

@implementation ServerTVC
{
    GCDAsyncUdpSocket *udpSocket;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (udpSocket == nil) {
        [self setupSocket];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
}

- (void)setupSocket {
    udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:[ServerTVC socketQueue]];
    
    NSError *error = nil;
    
    if (![udpSocket bindToPort:0 error:&error]) {
        NSLog(@"Error binding: %@", error);
        return;
    }
    
    if (![udpSocket beginReceiving:&error]) {
        NSLog(@"Error while beginning to receive: %@", error);
        return;
    }
    
    NSLog(@"Ready.");
}

+ (dispatch_queue_t)socketQueue {
    static dispatch_once_t pred = 0;
    __strong static dispatch_queue_t _q;
    dispatch_once(&pred, ^{
        _q = dispatch_queue_create("socket queue", NULL);
    });
    return _q;
}

# pragma mark GCDAsyncUdpSocket Delegate methods

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
      fromAddress:(NSData *)address
withFilterContext:(id)filterContext
{
    
}

@end
