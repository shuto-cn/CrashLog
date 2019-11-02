#import "CrashHandler.h"
#include <execinfo.h>

NSString * const UncaughtExceptionHandlerSignalExceptionName = @"UncaughtExceptionHandlerSignalExceptionName";
NSString * const UncaughtExceptionHandlerSignalKey = @"UncaughtExceptionHandlerSignalKey";
NSString * const UncaughtExceptionHandlerAddressesKey = @"UncaughtExceptionHandlerAddressesKey";

const NSInteger UncaughtExceptionHandlerSkipAddressCount = 4;
const NSInteger UncaughtExceptionHandlerReportAddressCount = 5;

@implementation CrashHandler

NSDateFormatter *dateFormatter;

+ (NSArray *)backtrace {
    void* callstack[128];
    int frames = backtrace(callstack, 128);
    char **strs = backtrace_symbols(callstack, frames);

    int i;
    NSMutableArray *backtrace = [NSMutableArray arrayWithCapacity:frames];
    for (
        i = UncaughtExceptionHandlerSkipAddressCount;
        i < UncaughtExceptionHandlerSkipAddressCount +
        UncaughtExceptionHandlerReportAddressCount;
        i++)
    {
        [backtrace addObject:[NSString stringWithUTF8String:strs[i]]];
    }
    free(strs);

    return backtrace;
}

+ (NSString *)applicationDocumentsDirectory {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

+ (NSString *)filename {
    NSString * date = [dateFormatter stringFromDate:[NSDate date]];
    long timeStamp = (long)(NSTimeInterval)([[NSDate date] timeIntervalSince1970]);
    return [NSString stringWithFormat:@"crash-%@-%ld.log", date, timeStamp];
}

- (void)handleException:(NSException *)exception {
    NSLog(@" 崩溃 handleException ================================== ");
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"错误" message:@"很抱歉,程序出现异常,即将退出." preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *sure =[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        dismissed = YES;
    }];

    [alertController addAction:sure];

    id rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
    if([rootViewController isKindOfClass:[UINavigationController class]])
    {
        rootViewController = ((UINavigationController *)rootViewController).viewControllers.firstObject;
    }
    if([rootViewController isKindOfClass:[UITabBarController class]])
    {
        rootViewController = ((UITabBarController *)rootViewController).selectedViewController;
    }

    [rootViewController presentViewController:alertController animated:YES completion:nil];

    CFRunLoopRef runLoop = CFRunLoopGetCurrent();
    CFArrayRef allModes = CFRunLoopCopyAllModes(runLoop);

    while (!dismissed) {
        for (NSString *mode in (__bridge NSArray *)allModes) {
            CFRunLoopRunInMode((CFStringRef)mode, 0.001, false);
        }
    }

    CFRelease(allModes);

    [self saveLog:exception];
    NSSetUncaughtExceptionHandler(NULL);

    signal(SIGABRT, SIG_DFL);
    signal(SIGILL, SIG_DFL);
    signal(SIGSEGV, SIG_DFL);
    signal(SIGFPE, SIG_DFL);
    signal(SIGBUS, SIG_DFL);
    signal(SIGPIPE, SIG_DFL);

    if ([[exception name] isEqual:UncaughtExceptionHandlerSignalExceptionName])
    {
        kill(getpid(), [[[exception userInfo] objectForKey:UncaughtExceptionHandlerSignalKey] intValue]);
    }
    else
    {
        [exception raise];
    }
}

- (void)saveLog:(NSException *)exception {
    // NSLog(@"崩溃日志文件==================================");
    // 异常的堆栈信息
    NSArray *stackArray = [exception callStackSymbols];
    // 出现异常的原因
    NSString *reason = [exception reason];
    // 异常名称
    NSString *name = [exception name];
    NSString *exceptionInfo = [NSString stringWithFormat:@"Exception reason：%@\nException name：%@\nException stack：%@",name, reason, stackArray];
    NSLog(@"%@", exceptionInfo);
    NSString * path = [[CrashHandler applicationDocumentsDirectory] stringByAppendingPathComponent:[CrashHandler filename]];
    NSLog(@"崩溃日志文件:%@", path);
    [exceptionInfo writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

@end

void HandleException(NSException *exception) {
    [[[CrashHandler alloc] init]
      performSelectorOnMainThread:@selector(handleException:)
      withObject: exception
      waitUntilDone:YES];

}

void SignalHandler(int signal) {
    NSMutableDictionary *userInfo =
    [NSMutableDictionary
      dictionaryWithObject:[NSNumber numberWithInt:signal]
      forKey:UncaughtExceptionHandlerSignalKey];

    NSArray *callStack = [CrashHandler backtrace];
    [userInfo
      setObject:callStack
      forKey:UncaughtExceptionHandlerAddressesKey];

    [[[CrashHandler alloc] init]
      performSelectorOnMainThread:@selector(handleException:)
      withObject:
        [NSException
          exceptionWithName:UncaughtExceptionHandlerSignalExceptionName
          reason: [
            NSString stringWithFormat:
            NSLocalizedString(@"Signal %d was raised.", nil),
            signal
          ]
          userInfo: [
            NSDictionary
            dictionaryWithObject:[NSNumber numberWithInt:signal]
            forKey:UncaughtExceptionHandlerSignalKey
          ]
        ]
      waitUntilDone:YES
    ];
}

void RegistUncauthExceptionHandler(void) {
    NSLog(@"崩溃日志文件 ============ regist ======================");
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd-HH-mm-ss"];
    NSSetUncaughtExceptionHandler(&HandleException);
    signal(SIGABRT, SignalHandler);
    signal(SIGILL, SignalHandler);
    signal(SIGSEGV, SignalHandler);
    signal(SIGFPE, SignalHandler);
    signal(SIGBUS, SignalHandler);
    signal(SIGPIPE, SignalHandler);
}
