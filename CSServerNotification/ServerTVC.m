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
    NSMutableArray *ips;
    NSMutableArray *servers; // of NSDictionary
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithTitle:@"Add" style:UIBarButtonItemStylePlain target:self action:@selector(addButtonPressed:)];
    self.navigationItem.rightBarButtonItem = addButton;
    
    UIRefreshControl *rc = [[UIRefreshControl alloc] init];
    rc.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to refresh"];
    [rc addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = rc;
    
    // TODO Load from NSUserDefaults
    ips = [[NSMutableArray alloc] init];
    servers = [[NSMutableArray alloc] init];
    
    if (udpSocket == nil) {
        [self setupSocket];
    }
    
    [self loadServerInfo];
}

- (void)refresh {
    [self loadServerInfo];
    [self.refreshControl endRefreshing];
}

- (void)loadServerInfo {
    servers = [[NSMutableArray alloc] init]; // reset server array
    for (NSString *ip in ips) {
        NSData *data = [NSData dataWithBytes:infoRequest length:25];
        [udpSocket sendData:data toHost:ip port:27015 withTimeout:3 tag:1];
    }
}

- (void)addButtonPressed:(UIBarButtonItem *)button {
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    UIAlertController *addIPController = [UIAlertController alertControllerWithTitle:@"Enter IP Address" message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    [addIPController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"IP Address";
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(alertTextFieldDidChange:) name:UITextFieldTextDidChangeNotification object:textField];
    }];
    
    UIAlertAction *okAction = [UIAlertAction
                               actionWithTitle:@"OK"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction *action)
                               {
                                   UITextField *address = addIPController.textFields.firstObject;
                                   
                                   [ips addObject:address.text];
                                   // TODO save to NSUserDefaults
                                   [self loadServerInfo];
                                   
                                   [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:nil];
                               }];
    okAction.enabled = NO;
    [addIPController addAction:cancelAction];
    [addIPController addAction:okAction];
    [self.parentViewController presentViewController:addIPController animated:YES completion:nil];
}

- (void)alertTextFieldDidChange:(NSNotification *)notification {
    UIAlertController *alertController = (UIAlertController *)self.presentedViewController;
    if (alertController) {
        UITextField *address = alertController.textFields.firstObject;
        UIAlertAction *ok = alertController.actions.lastObject;
        
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\b\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\b" options:0 error:nil];
        ok.enabled = [regex firstMatchInString:address.text options:0 range:NSMakeRange(0, address.text.length)] != nil;
    }
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
    
    [servers addObject:@{
                        @"name" : s,
                        @"map"  : m
                        }];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];;
    });
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [servers count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *reuse = @"servercell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuse];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuse];
    }
    
    NSDictionary *dict = (NSDictionary *)[servers objectAtIndex:indexPath.row];
    
    cell.textLabel.text = dict[@"name"];
    cell.detailTextLabel.text = dict[@"map"];
    return cell;
}

@end
