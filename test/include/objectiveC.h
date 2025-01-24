#import <os/availability.h>
#import <Foundation/Foundation.h>

// Protocol
@protocol TestProtocol

@property (readonly) NSUInteger length;
@end

// Protocol subtype
@protocol TestProtocol2 <TestProtocol>

@property (readonly) NSUInteger length;
@end

// Interface
API_AVAILABLE(macos(10.11), ios(8.0))
@interface TestInterface : NSObject

@property (readwrite) NSUInteger length;
@end

// Test Availability
API_AVAILABLE(macos(100.11))
@protocol TestAvailability

@property (readonly) NSUInteger length API_AVAILABLE(macos(101.11));
@end

// Interface
@interface TestInterfaceProperties : NSObject

@property (readwrite) NSUInteger intproperty1;
@property (readonly, getter=isintproperty2) BOOL intproperty2;
@property (readwrite, getter=isintproperty3) BOOL intproperty3;
@property (readonly) TestInterface * intproperty4;
@property (readonly) id<TestProtocol> intproperty5;
@property (readonly) NSArray<id<TestProtocol>> *intproperty6;
@property (readonly) NSArray<TestInterface *> *intproperty7;
@end
