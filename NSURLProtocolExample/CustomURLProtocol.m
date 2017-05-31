//
//  CustomURLProtocol.m
//  NSURLProtocolExample
//
//  Created by lujb on 15/6/15.
//  Copyright (c) 2015年 lujb. All rights reserved.
//

#import "CustomURLProtocol.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static NSString * const URLProtocolHandledKey = @"URLProtocolHandledKey";

@interface CustomURLProtocol ()

@end

@implementation CustomURLProtocol

+ (NSDictionary<NSString *,NSString *> *)replacedUrlMap {
    return objc_getAssociatedObject(self, @selector(replacedUrlMap));
}

+ (void)setReplacedUrlMap:(NSDictionary<NSString *,NSString *> *)replacedUrlMap {
    objc_setAssociatedObject(self, @selector(replacedUrlMap), replacedUrlMap, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    BOOL ret = NO;
    
    //已经处理过的不再处理
    BOOL isDealed = [NSURLProtocol propertyForKey:URLProtocolHandledKey inRequest:request] != nil;
    if (isDealed) {
        return NO;
    }
    for (NSString *originUrl in self.replacedUrlMap.allKeys) {
        if ([request.URL.absoluteString containsString:originUrl]) {
            ret = YES;
            break;
        }
    }
    return ret;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    NSMutableURLRequest *mutableReqeust = [request mutableCopy];
    mutableReqeust = [self redirectHostInRequset:mutableReqeust];
    return mutableReqeust;
}

+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b
{
    return [super requestIsCacheEquivalent:a toRequest:b];
}

- (void)startLoading
{
    NSMutableURLRequest *mutableReqeust = [[self request] mutableCopy];
    
    //打标签，防止无限循环
    [NSURLProtocol setProperty:@YES forKey:URLProtocolHandledKey inRequest:mutableReqeust];
    
    //获取网络资源
    [[[NSURLSession sharedSession] dataTaskWithRequest:mutableReqeust completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        [self.client URLProtocol:self didLoadData:data];
        [self.client URLProtocolDidFinishLoading:self];
        if (error) {
            [self.client URLProtocol:self didFailWithError:error];
        }
    }] resume];
}

- (void)stopLoading
{
}

#pragma mark -- private

/**
 替换原来的域名
 */
+(NSMutableURLRequest*)redirectHostInRequset:(NSMutableURLRequest*)request
{
    if ([request.URL host].length == 0) {
        return request;
    }
    
    NSString *originUrlString = [request.URL absoluteString];
    
    for (NSString *originUrl in self.replacedUrlMap.allKeys) {
        if ([originUrlString containsString:originUrl]) {
            NSString *replacedUrl = [originUrlString stringByReplacingOccurrencesOfString:originUrl withString:self.replacedUrlMap[originUrl]];
            NSURL *url = [NSURL URLWithString:replacedUrl];
            request.URL = url;
            break;
        }
    }
    return request;
}


@end
