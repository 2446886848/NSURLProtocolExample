//
//  CustomURLProtocol.m
//  NSURLProtocolExample
//
//  Created by lujb on 15/6/15.
//  Copyright (c) 2015年 lujb. All rights reserved.
//

#import "CustomURLProtocol.h"
#import <UIKit/UIKit.h>

static NSString * const URLProtocolHandledKey = @"URLProtocolHandledKey";

@interface CustomURLProtocol ()

@end

@implementation CustomURLProtocol

+ (BOOL)isImageUrl:(NSURLRequest *)request {
    NSString *extension = request.URL.pathExtension.lowercaseString;
    NSArray *pngTails = @[@"png", @"jpeg", @"gif", @"jpg"];
    return [pngTails containsObject:extension];
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    //只处理http和https请求
    NSString *scheme = [[request URL] scheme];
    BOOL isDealed = [NSURLProtocol propertyForKey:URLProtocolHandledKey inRequest:request] != nil;
    if ([self isImageUrl:request]) {
        return !isDealed;
    } else if ( ([scheme caseInsensitiveCompare:@"http"] == NSOrderedSame ||
     [scheme caseInsensitiveCompare:@"https"] == NSOrderedSame))
    {
        //看看是否已经处理过了，防止无限循环
        if (isDealed) {
            return NO;
        }
        return YES;
    }
    return NO;
}

+ (NSURLRequest *) canonicalRequestForRequest:(NSURLRequest *)request {
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
    
    //读取本地图片
    if ([self.class isImageUrl:mutableReqeust]) {
        NSData *imageData = UIImagePNGRepresentation([UIImage imageNamed:@"image"]);
        
        NSURLResponse *response = [[NSURLResponse alloc] initWithURL:mutableReqeust.URL MIMEType:@"image/png" expectedContentLength:imageData.length textEncodingName:nil];
        [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        [self.client URLProtocol:self didLoadData:imageData];
        [self.client URLProtocolDidFinishLoading:self];
        return;
    } else {
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
    NSString *originHostString = [request.URL host];
    NSRange hostRange = [originUrlString rangeOfString:originHostString];
    if (hostRange.location == NSNotFound) {
        return request;
    }
    
    //定向到bing搜索主页
    NSString *urlString = @"http://cn.bing.com/";
    NSURL *url = [NSURL URLWithString:urlString];
    request.URL = url;

    return request;
}


@end
