//
//  TCPSocket.h
//  RacecARGO
//
//  Created by Johannes Heucher on 04.02.17.
//  Copyright © 2017 Johannes Heucher. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TCPSocket : NSObject {
    id<NSStreamDelegate> delegate;
}

@property (nonatomic, retain) NSInputStream* inputStream;
@property (nonatomic, retain) NSOutputStream* outputStream;

- (id)initWithDelegate:(id<NSStreamDelegate>)aDelegate;
- (void)connect;
- (void)disconnect;

@end
