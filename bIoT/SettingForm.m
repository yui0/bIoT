#import "SettingForm.h"

@implementation SettingForm

- (NSArray *)fields
{
	NSDictionary *dic = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
	NSLog(@"defualts:%@", dic);

	return @[
		@{FXFormFieldKey: @"from", FXFormFieldTitle: @"Sender", FXFormFieldDefaultValue: dic[@"mail_from"]},
		@{FXFormFieldKey: @"to", FXFormFieldTitle: @"Email", FXFormFieldDefaultValue: dic[@"mail_to"]},
		@{FXFormFieldKey: @"host", FXFormFieldTitle: @"SMTP", FXFormFieldDefaultValue: dic[@"mail_host"]},
		@{FXFormFieldKey: @"account", FXFormFieldTitle: @"acount", FXFormFieldDefaultValue: dic[@"mail_account"]},
		@{FXFormFieldKey: @"pwd", FXFormFieldTitle: @"password", FXFormFieldDefaultValue: dic[@"mail_pwd"]},
		@{FXFormFieldKey: @"subject", FXFormFieldTitle: @"Subject", FXFormFieldDefaultValue: dic[@"mail_subject"]},
		@{FXFormFieldKey: @"content", FXFormFieldTitle: @"Content", FXFormFieldDefaultValue: dic[@"mail_content"]},

		@{FXFormFieldTitle: @"Update", FXFormFieldHeader: @"", FXFormFieldAction: @"updateSetting:"},
	];
}
/*- (void)dealloc
{
}*/

@end
