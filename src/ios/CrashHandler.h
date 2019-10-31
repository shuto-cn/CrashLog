#import <UIKit/UIKit.h>

@interface CrashHandler : NSObject {
    BOOL dismissed;
}

@end

void HandleException(NSException *exception);
void SignalHandler(int signal);

void RegistUncauthExceptionHandler(void);
