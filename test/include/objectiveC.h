// The Objective-C regression fixture, self-contained on purpose: the original imported
// <Foundation/Foundation.h>, which needs the macOS SDK and confined the testset to Apple CI.
// Everything the assertions exercise — protocol inheritance, interface supertypes,
// availability on wrappers and on properties, explicit getters/setters, object-pointer and
// protocol-qualified property types — is spellable with local stand-ins, so the testset runs
// on every host (pinned to -fobjc-runtime=macosx, since clang picks the runtime from the
// target and only Darwin defaults to the non-fragile ABI).
//
// Dropped relative to the original: the NSArray<...> generic properties. Their assertions were
// `broken=true` from the day they were written — generics never worked — and a stand-in NSArray
// would pin a behavior nothing implements.
typedef unsigned long NSUInteger;
typedef signed char BOOL;

// Never emitted: the generator maps NSObject to ObjectiveC.jl's own (see OBJC_ROOTS).
@interface NSObject
@end

// Protocol
@protocol TestProtocol
@property (readonly) NSUInteger length;
@end

// Protocol subtype
@protocol TestProtocol2 <TestProtocol>
@property (readonly) NSUInteger length;
@end

// Interface
__attribute__((availability(macos, introduced=10.11)))
@interface TestInterface : NSObject
@property (readwrite) NSUInteger length;
@end

// Test Availability
__attribute__((availability(macos, introduced=100.11)))
@protocol TestAvailability
@property (readonly) NSUInteger length __attribute__((availability(macos, introduced=101.11)));
@end

// Interface Properties
@interface TestInterfaceProperties : NSObject
@property (readwrite) NSUInteger intproperty1 __attribute__((availability(macos, introduced = 101.11, deprecated = 130.0,
                            message = "Use X instead")));
@property (readonly, getter=isintproperty2) BOOL intproperty2;
@property (readwrite, getter=isintproperty3) BOOL intproperty3;
@property (readonly) TestInterface * intproperty4;
@property (readonly) id<TestProtocol> intproperty5;
@end
