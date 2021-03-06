//
//  PMTagStore.m
//  Pinmarker
//
//  Created by Kyle Stevens on 3/8/14.
//  Copyright (c) 2014 kilovolt42. All rights reserved.
//

#import "PMTagStore.h"
#import "PMAccountStore.h"
#import "RNEncryptor.h"
#import "RNDecryptor.h"

NSString * const PMTagStoreDidUpdateUserTagsNotification = @"PMTagStoreDidUpdateUserTagsNotification";
NSString * const PMTagStoreUsernameKey = @"PMTagStoreUsernameKey";

@interface PMTagStore ()

@property (nonatomic) NSMutableDictionary *tags;
@property (nonatomic, readonly, copy) NSString *encryptionPassword;

@end

@implementation PMTagStore

#pragma mark - Properties

- (NSMutableDictionary *)tags {
    if (!_tags) _tags = [NSMutableDictionary new];
    return _tags;
}

- (NSString *)encryptionPassword {
    NSString *username = [PMAccountStore sharedStore].defaultUsername;
    return [[PMAccountStore sharedStore] authTokenForUsername:username];
}

#pragma mark - Initializers

- (instancetype)init {
    @throw [NSException exceptionWithName:@"Singleton"
                                   reason:@"Use +sharedStore"
                                 userInfo:nil];
    return nil;
}

- (instancetype)initPrivate {
    self = [super init];
    if (self) {
        NSString *path = [self tagsArchivePath];
        id encryptedData = [[NSData alloc] initWithContentsOfFile:path];

        NSString *password = self.encryptionPassword;

        if (encryptedData && password) {
            NSError *error = nil;
            NSData *decryptedData = [RNDecryptor decryptData:encryptedData withPassword:password error:&error];
            if (!error) {
                _tags = [NSKeyedUnarchiver unarchiveObjectWithData:decryptedData];
            }
        }

        if (!_tags) {
            _tags = [NSMutableDictionary new];
            [self deleteItemForArchivePath:path];
        }

        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(usernameUpdated:) name:PMAccountStoreDidAddUsernameNotification object:nil];
        [center addObserver:self selector:@selector(usernameUpdated:) name:PMAccountStoreDidUpdateUsernameNotification object:nil];
        [center addObserver:self selector:@selector(usernameRemoved:) name:PMAccountStoreDidRemoveUsernameNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Methods

+ (instancetype)sharedStore {
    static PMTagStore *sharedStore = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedStore = [[PMTagStore alloc] initPrivate];
    });

    return sharedStore;
}

- (NSArray *)tagsForUsername:(NSString *)username {
    return self.tags[username];
}

- (void)updateTags:(NSArray *)tags username:(NSString *)username {
    self.tags[username] = tags;
    [self saveTags];
    [self postDidUpdateNotificationWithUsername:username];
}

#pragma mark -

- (NSString *)tagsArchivePath {
    NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = [documentDirectories firstObject];
    return [documentDirectory stringByAppendingPathComponent:@"tags.archive"];
}

- (BOOL)saveTags {
    // Filter out tags associated with a foreign API token from URL schemes
    NSMutableDictionary *tagsToSave = [NSMutableDictionary new];
    for (NSString *username in [PMAccountStore sharedStore].associatedUsernames) {
        NSArray *tagsForUsername = self.tags[username];
        tagsToSave[username] = tagsForUsername ? tagsForUsername : @[];
    }

    NSString *password = self.encryptionPassword;

    if (password) {
        NSData *archivedData = [NSKeyedArchiver archivedDataWithRootObject:self.tags];

        NSError *error;
        NSData *encryptedData = [RNEncryptor encryptData:archivedData withSettings:kRNCryptorAES256Settings password:password error:&error];
        if (!error) {
            NSString *path = [self tagsArchivePath];
            return [encryptedData writeToFile:path atomically:YES];
        }
    }

    return NO;
}

- (BOOL)deleteItemForArchivePath:(NSString *)path {
    NSError *error = nil;
    return [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
}

- (void)usernameUpdated:(NSNotification *)notification {
    NSString *username = notification.userInfo[PMAccountStoreUsernameKey];
    NSString *token = [[PMAccountStore sharedStore] authTokenForUsername:username];

    if (token && ![token isEqualToString:@""]) {
        void (^success)(NSDictionary *) = ^(NSDictionary *responseDictionary) {
            NSArray *sortedTags = [[[responseDictionary keysSortedByValueUsingSelector:@selector(compare:)] reverseObjectEnumerator] allObjects];
            [self updateTags:sortedTags username:username];
        };

        [PMPinboardService requestTagsForAPIToken:token success:success failure:nil];
    }
}

- (void)usernameRemoved:(NSNotification *)notification {
    NSString *username = notification.userInfo[PMAccountStoreUsernameKey];
    [self.tags removeObjectForKey:username];
    [self saveTags];
}

- (void)postDidUpdateNotificationWithUsername:(NSString *)username {
    [[NSNotificationCenter defaultCenter] postNotificationName:PMTagStoreDidUpdateUserTagsNotification
                                                        object:self
                                                      userInfo:@{ PMTagStoreUsernameKey : username }];
}

@end
