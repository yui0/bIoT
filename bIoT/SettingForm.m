#import "SettingForm.h"

@implementation SettingForm

- (NSArray *)fields
{
	NSDictionary *dic = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
	NSLog(@"defualts:%@", dic);

	return @[
		@{FXFormFieldKey: @"from", FXFormFieldTitle: @"Sender", FXFormFieldDefaultValue: dic[@"mail_from"], FXFormFieldType: FXFormFieldTypeEmail},
		@{FXFormFieldKey: @"to", FXFormFieldTitle: @"Email", FXFormFieldDefaultValue: dic[@"mail_to"], FXFormFieldType: FXFormFieldTypeEmail},
		@{FXFormFieldKey: @"host", FXFormFieldTitle: @"SMTP", FXFormFieldDefaultValue: dic[@"mail_host"], FXFormFieldType: FXFormFieldTypeEmail},
		@{FXFormFieldKey: @"account", FXFormFieldTitle: @"acount", FXFormFieldDefaultValue: dic[@"mail_account"]},
		@{FXFormFieldKey: @"pwd", FXFormFieldTitle: @"password", FXFormFieldDefaultValue: dic[@"mail_pwd"], FXFormFieldType: FXFormFieldTypePassword},

		@{FXFormFieldKey: @"subject", FXFormFieldTitle: @"Subject", FXFormFieldDefaultValue: dic[@"mail_subject"]},
		@{FXFormFieldKey: @"content", FXFormFieldTitle: @"Content", FXFormFieldDefaultValue: dic[@"mail_content"]},
		@{FXFormFieldKey: @"content2", FXFormFieldTitle: @"Content2", FXFormFieldDefaultValue: dic[@"mail_content2"]},
		@{FXFormFieldKey: @"content3", FXFormFieldTitle: @"Content3", FXFormFieldDefaultValue: dic[@"mail_content3"]},
		@{FXFormFieldKey: @"content4", FXFormFieldTitle: @"Content4", FXFormFieldDefaultValue: dic[@"mail_content4"]},

		@{FXFormFieldTitle: @"Update", FXFormFieldHeader: @"", FXFormFieldAction: @"updateSetting:"},
	];
}
/*- (void)dealloc
{
}*/

@end
