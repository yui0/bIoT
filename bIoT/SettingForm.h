#import <Foundation/Foundation.h>
#import "FXForms.h"

@interface SettingForm : NSObject <FXForm>

@property (nonatomic, strong) NSString *from;
@property (nonatomic, strong) NSString *to;
@property (nonatomic, strong) NSString *host;
@property (nonatomic, strong) NSString *account;
@property (nonatomic, strong) NSString *pwd;
@property (nonatomic, strong) NSString *subject;
@property (nonatomic, strong) NSString *content;
@property (nonatomic, strong) NSString *content2;
@property (nonatomic, strong) NSString *content3;
@property (nonatomic, strong) NSString *content4;

@end
