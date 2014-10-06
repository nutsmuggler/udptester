//
//  CNYNetworkInfoManager.m
//  candy-ios
//
//  Created by Davide Benini on 26/09/14.
//  Copyright (c) 2014 Candy. All rights reserved.
//

#import "CNYNetworkInfoManager.h"

// System
#import <ifaddrs.h>
#import <arpa/inet.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#import <SystemConfiguration/SystemConfiguration.h>

#include <stdlib.h>

@implementation CNYNetworkInfoManager

#pragma mark - Singleton constructor
static id __sharedInstance;

+(instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __sharedInstance = [CNYNetworkInfoManager new];
    });
    return __sharedInstance;
}


// Utility: get IP Address
//
- (NSDictionary *)getNetworkInfo{
    NSString *address = @"error";
    NSString *netmask = @"error";
    NSString *broadcast_address = @"error";
    
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                    netmask = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_netmask)->sin_addr)];
                    broadcast_address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_dstaddr)->sin_addr)];
                    
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return @{@"address": address,@"netmask": netmask,@"broadcast_address": broadcast_address};
    
}
- (NSString *)IPAddress {
    return [[self getNetworkInfo] valueForKey:@"address"];
}
- (NSString *)subnetMask {
    return [[self getNetworkInfo] valueForKey:@"netmask"];
}
- (NSString *)broadcastAddress {
    return [[self getNetworkInfo] valueForKey:@"broadcast_address"];
}
-(NSString*)networkSubnet {
    NSString* ipAddress = [self IPAddress];
    NSArray* elements = [ipAddress componentsSeparatedByString:@"."];
    return [NSString stringWithFormat:@"%@.%@.%@",[elements objectAtIndex:0],[elements objectAtIndex:1],[elements objectAtIndex:2]];
}

- (NSDictionary*)SSIDInfo {
    NSArray *ifs = (__bridge_transfer id)CNCopySupportedInterfaces();
    id info = nil;
    for (NSString *ifnam in ifs) {
        info = (__bridge_transfer id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        if (info && [info count]) { break; }
    }
    return info;
}

-(NSString*)currentNetworkSsid {
    NSString* result;
    NSDictionary * info = [self SSIDInfo];
    
    if ([info valueForKey:@"SSID"]) {
        result = [info valueForKey:@"SSID"];
    }
    return result;
}
@end
