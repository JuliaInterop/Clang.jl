#import <os/availability.h>
#import <Foundation/Foundation.h>

// Protocol
API_AVAILABLE(macos(10.11), ios(8.0))
@protocol TestProtocol

@property (readonly) NSUInteger length;
@end

// Protocol subtype
API_AVAILABLE(macos(10.11), ios(8.0))
@protocol TestProtocol2 <TestProtocol>

@property (readonly) NSUInteger length;
@end

// Interface
API_AVAILABLE(macos(10.11), ios(8.0))
@interface TestInterface : NSObject

@property (readwrite) NSUInteger length;
@end
