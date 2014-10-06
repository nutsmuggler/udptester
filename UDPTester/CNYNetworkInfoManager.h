//
//  CNYNetworkInfoManager.h
//  candy-ios
//
//  Created by Davide Benini on 26/09/14.
//  Copyright (c) 2014 Candy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CNYNetworkInfoManager : NSObject

+(instancetype)sharedInstance;

- (NSString *)IPAddress;
- (NSString *)subnetMask;
- (NSString *)broadcastAddress;
- (NSString *)networkSubnet;
- (NSString*)currentNetworkSsid;

@end
