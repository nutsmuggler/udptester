//
//  ViewController.m
//  UDPTester
//
//  Created by davide on 03/10/14.
//  Copyright (c) 2014 NT. All rights reserved.
//



#define PORT 8089
#define BUFSIZE 2048


#import "ViewController.h"

// BSD sockets
//
#import <netinet/in.h>
#include <arpa/inet.h>

// Network
#import "CNYNetworkInfoManager.h"

// Categories
#import "UIColor+Conversion.h"


@interface ViewController () {
    int receivingSocket;                         /* our socket */
    ssize_t received_size;                    /* # bytes received */
    unsigned char buffer[BUFSIZE];     /* receive buffer */
    struct sockaddr_in socket_address;     /* remote address */
    socklen_t address_len;            /* length of addresses */
}

@property (nonatomic,strong) NSMutableString *log;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.log = [[NSMutableString alloc] init];

    [self updateServerReceiverUI];
}

#pragma mark - Properties

-(BOOL)isReceiver {
    return self.segmentedControl.selectedSegmentIndex == 1;
}

#pragma mark - Actions

- (IBAction)sendButtonTapped:(id)sender {
    if (!self.segmentedControl.hidden) {
        self.segmentedControl.hidden = YES;
        [self logMessage:@"Working as app"];
    }
    NSString* testString = @"Hi there!";
    NSData* testData = [testString dataUsingEncoding:NSUTF8StringEncoding];
    
    
    [self send:testData ipAddress:[[CNYNetworkInfoManager sharedInstance] broadcastAddress] port:PORT];
    
}

- (IBAction)receiveButtonTapped:(id)sender {
    if (!self.segmentedControl.hidden) {
        self.segmentedControl.hidden = YES;
        [self logMessage:@"Working as robot"];
        
        [NSThread detachNewThreadSelector:@selector(startServer)
                                 toTarget:self
                               withObject:nil];
    }
}

- (IBAction)segmentedControlValueChanged:(UISegmentedControl*)sender {
    [self updateServerReceiverUI];
}
-(void)updateServerReceiverUI {
    self.sendButton.hidden = [self isReceiver];
    self.receiveButton.hidden = ![self isReceiver];
}

#pragma mark - Send message

-(bool) send:(NSData*) msg ipAddress:(NSString*) ip port:(int) p
{
    int sock;
    struct sockaddr_in destination;
    unsigned int echolen;
    int broadcast = 1;
    
    if (msg == nil || ip == nil)
    {
        NSLog(@"Message and/or ip address is null\n");
        return NO;
    }
    
    /* Create the UDP socket */
    if ((sock = socket(AF_INET, SOCK_DGRAM, 0)) < 0)
    {
        NSLog(@"Failed to create socket\n");
        return NO;
    }
    
    /* Construct the server sockaddr_in structure */
    memset(&destination, 0, sizeof(destination));
    
    /* Clear struct */
    destination.sin_family = AF_INET;
    
    /* Internet/IP */
    destination.sin_addr.s_addr = inet_addr([ip UTF8String]);
    
    /* IP address */
    destination.sin_port = htons(p);
    
    /* server port */
    setsockopt(sock,
               IPPROTO_IP,
               IP_MULTICAST_IF,
               &destination,
               sizeof(destination));
    char *cmsg = (char *)[msg bytes];// [msg UTF8String];
    echolen = (unsigned int)strlen(cmsg);
    
    // this call is what allows broadcast packets to be sent:
    if (setsockopt(sock,
                   SOL_SOCKET,
                   SO_BROADCAST,
                   &broadcast,
                   sizeof broadcast) == -1)
    {
        NSLog(@"Cannot switch on broadcast");
        return NO;
    }
    
    NSInteger sentBytes = sendto(sock,
                                  cmsg,
                                  echolen,
                                  0,
                                  (struct sockaddr *) &destination,
                                  sizeof(destination));
    if (sentBytes < 0) {
        NSLog(@"Error: %i", errno);
        return false;
    } else {
        if (sentBytes != echolen)
        {
            NSLog(@"Mismatch in number of sent bytes\n");
            return false;
        }
        else
        {
            NSLog(@"-> Tx: %@",msg);
            [self logSuccess:[NSString stringWithFormat:@"Sent: %@ on port %i - %@", msg,p, [[CNYNetworkInfoManager sharedInstance] currentNetworkSsid]]];
            return true;
        }
    }
}

#pragma mark - Reception

- (void)startServer {
    
    address_len = sizeof(socket_address);

    /* create a UDP socket */

    if((receivingSocket = socket(AF_INET, SOCK_DGRAM, 0)) < 0) {
        NSLog(@"Cannot create socket");
    }
    
    
    /* Mark the socket as non-blocking */
    fcntl(receivingSocket, F_SETFL, O_NONBLOCK);

    memset(&socket_address, 0, sizeof(socket_address));
    socket_address.sin_family = AF_INET;
    socket_address.sin_addr.s_addr = htonl(INADDR_ANY);
    socket_address.sin_port = htons(PORT);
    
    // bind the socket to our address
    if (-1 == bind(receivingSocket,(struct sockaddr *)&socket_address, address_len))
    {
        NSLog(@"error bind failed");
        close(receivingSocket);
        exit(EXIT_FAILURE);
    }
    

    NSLog(@"UDP Server started...");

    [self logSuccess:[NSString stringWithFormat:@"Listening on port %i on %@", PORT, [[CNYNetworkInfoManager sharedInstance] currentNetworkSsid]]];

    @autoreleasepool {
        [self doReceive];
    }

}

-(void)doReceive {
    NSLog(@"Waiting...");
    
    received_size = recvfrom(receivingSocket,
                             (void *)buffer,
                             BUFSIZE,
                             0,
                             (struct sockaddr *)&socket_address,
                             &address_len);
    
    if (received_size > 0) {
        buffer[received_size] = 0;
        NSLog(@"received message: \"%s\"\n", buffer);
        [self logSuccess:[NSString stringWithFormat:@"Received: %s", buffer]];
    }


    
    /* now loop, receiving data and printing what we received */

    [self doReceive];
   
    
}





#pragma mark - Logging

- (void)logError:(NSString *)msg
{
    [self logText:msg withColor:[UIColor redColor]];
}

- (void)logMessage:(NSString *)msg
{
    [self logText:msg withColor:[UIColor blackColor]];
}

- (void)logSuccess:(NSString *)msg
{
    [self logText:msg withColor:[UIColor colorWithRed:0 green:.8 blue:0 alpha:1.0]];

}
- (void)logText:(NSString *)msg withColor:(UIColor*)color
{
    NSString *prefix = [NSString stringWithFormat:@"<font color=\"#%@\">", [color hexStringValue]];
    NSString *suffix = @"</font><br/>";
    
    [self.log appendFormat:@"%@%@%@\n", prefix, msg, suffix];
    
    NSString *html = [NSString stringWithFormat:@"<html><body>%@</body></html>", self.log];
    [self.webView loadHTMLString:html baseURL:nil];
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)sender
{
    NSString *scrollToBottom = @"window.scrollTo(document.body.scrollWidth, document.body.scrollHeight);";
    
    [sender stringByEvaluatingJavaScriptFromString:scrollToBottom];
    //  [self webViewScrollToBottom:webView];
    
}
@end
