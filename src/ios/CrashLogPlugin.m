#import "CrashHandler.h"
#import "CrashLogPlugin.h"

@implementation CrashLogPlugin

- (void)pluginInitialize
{
    NSLog(@"崩溃日志文件:pluginInitialize");
    RegistUncauthExceptionHandler();
}

@end
