//
//  ServerTVC.m
//  CSServerNotification
//
//  Created by Tyler  Much on 10/7/14.
//  Copyright (c) 2014 Tyler Much. All rights reserved.
//

#import "ServerTVC.h"
#import "GCDAsyncUdpSocket.h"

static unsigned char infoRequest[] = {0xFF, 0xFF, 0xFF, 0xFF, 0x54, 0x53, 0x6F, 0x75, 0x72, 0x63, 0x65, 0x20, 0x45, 0x6E, 0x67, 0x69,
                                0x6E, 0x65, 0x20, 0x51, 0x75, 0x65, 0x72, 0x79, 0x00};

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
    unsigned char *bytes = (unsigned char *)data.bytes;
    unsigned char *curr = bytes;
    
    unsigned char *name, *map;
    
    for (int i = 0; i < 4; i++) {
        if (*(curr++) != 0xFF) {
            NSLog(@"Did not find 0xFFFFFFFF prefix");
            return;
        }
    }
    
    if (*(curr++) != 0x49) {
        NSLog(@"Header invalid (should always be 0x49).");
        return;
    }
    
    // protocol
    curr++;
    
    name = curr;
    
    while (*(curr++) != 0x00);
    
    map = curr;
    
    NSString *s;
    NSString *m;
    s = [NSString stringWithUTF8String:(char *)name];
    m = [NSString stringWithUTF8String:(char *)map];
    
    NSLog(@"Name: %@", s);
    NSLog(@"Map: %@", m);
    
}

@end
