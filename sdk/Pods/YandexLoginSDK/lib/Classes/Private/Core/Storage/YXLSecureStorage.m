#import "YXLSecureStorage.h"

@interface YXLSecureStorage ()

@property (nonatomic, copy, readonly) NSDictionary *keychainQuery;

@end

@implementation YXLSecureStorage

- (instancetype)initWithKey:(NSString *)key
{
    NSParameterAssert(key);
    self = [super init];
    if (self != nil) {
        _keychainQuery = @{
                           (id)kSecClass : (id)kSecClassGenericPassword,
                           (id)kSecAttrService : key,
                           (id)kSecAttrAccount : key
                           };
    }
    return self;
}

- (NSDictionary *)storedObject
{
    NSMutableDictionary *selectQuery = [self.keychainQuery mutableCopy];
    selectQuery[(id)kSecReturnData] = @YES;
    selectQuery[(id)kSecMatchLimit] = (id)kSecMatchLimitOne;

    CFTypeRef dataTypeRef = NULL;
    NSDictionary *storedObject = nil;
    if (SecItemCopyMatching((__bridge CFDictionaryRef)selectQuery, &dataTypeRef) == errSecSuccess) {
        NSData *data = CFBridgingRelease(dataTypeRef);
        @try {
            storedObject = [NSKeyedUnarchiver unarchivedObjectOfClasses:[NSSet setWithObjects:
                                                                         [NSDictionary class],
                                                                         [NSString class],
                                                                         [NSArray class],
                                                                         [NSNumber class], nil] fromData:data error:nil];
        }
        @catch (NSException *_) {
        }
    }
    return storedObject;
}

- (void)setStoredObject:(NSDictionary *)storedObject
{
    SecItemDelete((__bridge CFDictionaryRef)self.keychainQuery);
    if (storedObject != nil) {
        NSMutableDictionary *query = [self.keychainQuery mutableCopy];
        query[(id)kSecValueData] = [NSKeyedArchiver archivedDataWithRootObject:storedObject requiringSecureCoding:YES error:nil];
        SecItemAdd((__bridge CFDictionaryRef)query, NULL);
    }
}

@end
