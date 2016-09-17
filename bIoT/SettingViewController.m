#import "FXForms.h"
#import "SettingForm.h"
//#import "SettingViewController.h"

@interface SettingViewController : UIViewController <FXFormControllerDelegate>

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) FXFormController *formController;

@end

@implementation SettingViewController

- (void)viewDidLoad
{
	[super viewDidLoad];

	// we'll assume that tableView has already been set via a nib or the -loadView method
	self.formController = [FXFormController new];
	self.formController.tableView = self.tableView;
	self.formController.delegate = self;
	self.formController.form = [SettingForm new];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

	// reload the table
	[self.tableView reloadData];
}

- (void)updateSetting:(UITableViewCell<FXFormFieldCell> *)cell
{
	SettingForm *f = cell.field.form;
//	NSLog(@"mail:%@", f.from);
	NSUserDefaults *_defaults = [NSUserDefaults standardUserDefaults];
	[_defaults setObject:f.from forKey:@"mail_from"];
	[_defaults setObject:f.to forKey:@"mail_to"];
	[_defaults setObject:f.host forKey:@"mail_host"];
	[_defaults setObject:f.account forKey:@"mail_account"];
	[_defaults setObject:f.pwd forKey:@"mail_pwd"];
	[_defaults setObject:f.subject forKey:@"mail_subject"];
	[_defaults setObject:f.content forKey:@"mail_content"];
	[_defaults synchronize];

	[[[UIAlertView alloc] initWithTitle:@"Updated" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
	[self.navigationController popViewControllerAnimated:YES];
}

@end
