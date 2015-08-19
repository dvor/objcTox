//
//  OCTManagerConfigurationTests.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 15.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

#import "OCTManagerConfiguration.h"

@interface OCTManagerConfigurationTests : XCTestCase

@end

@implementation OCTManagerConfigurationTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testDefaultConfiguration
{
    OCTManagerConfiguration *configuration = [OCTManagerConfiguration defaultConfiguration];

    XCTAssertNotNil(configuration.settingsStorage);
    XCTAssertNotNil(configuration.fileStorage);
    XCTAssertNotNil(configuration.options);
}

- (void)testCopy
{
    OCTManagerConfiguration *configuration = [OCTManagerConfiguration defaultConfiguration];
    configuration.options.IPv6Enabled = YES;
    configuration.options.UDPEnabled = YES;
    configuration.options.proxyType = OCTToxProxyTypeHTTP;
    configuration.options.proxyHost = @"proxy.address";
    configuration.options.proxyPort = 999;
    configuration.options.tcpPort = 777;

    OCTManagerConfiguration *c2 = [configuration copy];

    XCTAssertEqualObjects(configuration.settingsStorage, c2.settingsStorage);
    XCTAssertEqualObjects(configuration.fileStorage, c2.fileStorage);

    XCTAssertEqual(configuration.options.IPv6Enabled, c2.options.IPv6Enabled);
    XCTAssertEqual(configuration.options.UDPEnabled, c2.options.UDPEnabled);
    XCTAssertEqual(configuration.options.proxyType, c2.options.proxyType);
    XCTAssertEqualObjects(configuration.options.proxyHost, c2.options.proxyHost);
    XCTAssertEqual(configuration.options.proxyPort, c2.options.proxyPort);
    XCTAssertEqual(configuration.options.tcpPort, c2.options.tcpPort);
}

@end
