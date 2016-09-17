//
//  bCentral
//
//  Created by Yuichiro Nakada on 2016/09/09.
//  Copyright © 2016 Yuichiro Nakada. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import <AudioToolbox/AudioServices.h>
#import "ViewController.h"
#import "BLEuuid.h"
#import "SMTPMessage.h"
#import "SettingForm.h"

@interface ViewController () <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (strong, nonatomic) CBCentralManager	*centralManager;
@property (strong, nonatomic) CBPeripheral	*discoveredPeripheral;
@property (strong, nonatomic) NSMutableData	*data;
@property (strong, nonatomic) NSUserDefaults	*defaults;

//@property (weak, nonatomic) IBOutlet UILabel	*lblStatus;
@property (weak, nonatomic) IBOutlet UIButton	*button;

@end

@implementation ViewController

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];
	[self initUserData];

	// Start up the CBCentralManager
	_centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
	[_button setTitle:@"Searching..." forState:UIControlStateNormal];

	// And somewhere to store the incoming data
	_data = [NSMutableData new];
}

- (void)viewWillDisappear:(BOOL)animated
{
	// Don't keep it going while we're not showing.
	[self.centralManager stopScan];
	NSLog(@"Scanning stopped");

	[super viewWillDisappear:animated];
}

#pragma mark - Central Methods

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
//	if (central.state != CBCentralManagerStatePoweredOn) return;
//	[self scan];

	NSString * state = nil;

	switch (central.state) {
	case CBCentralManagerStateUnsupported:
		state = @"The platform/hardware doesn't support Bluetooth Low Energy.";
		break;
	case CBCentralManagerStateUnauthorized:
		state = @"The app is not authorized to use Bluetooth Low Energy.";
		break;
	case CBCentralManagerStatePoweredOff:
		state = @"Bluetooth is currently powered off.";
		[self cleanup];
		break;
	case CBCentralManagerStatePoweredOn:
		[self scan];
		return;
	case CBCentralManagerStateUnknown:
	default:
		return;
	}

	NSLog(@"Central manager state: %@", state);

	UIAlertView *alert = [UIAlertView new];
	[alert setMessage:state];
	[alert addButtonWithTitle:@"OK"];
	[alert show];

//	FXFormViewController *controller = [FXFormViewController new];
//	controller.formController.form = [SettingForm new];
//	SettingViewController *controller = [SettingViewController new];
//	[self presentViewController: controller animated:YES completion: nil];

	return;
}

- (void)scan
{
	[self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:BATTERY_SERVICE_UUID]] options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];
	NSLog(@"Scanning started");
//	_lblStatus.text = @"Scanning started";
	[_button setTitle:@"Scanning started" forState:UIControlStateNormal];
}

// This callback comes whenever a peripheral that is advertising the SERVICE_UUID is discovered.
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
	NSLog(@"Discovered %@ at %@", peripheral.name, RSSI);
//	_lblStatus.text = [NSString stringWithFormat:@"Discovered %@ at %@", peripheral.name, RSSI];
	[_button setTitle:[NSString stringWithFormat:@"Discovered %@ at %@", peripheral.name, RSSI] forState:UIControlStateNormal];

	// Ok, it's in range - have we already seen it?
	if (self.discoveredPeripheral != peripheral) {
		// Save a local copy of the peripheral, so CoreBluetooth doesn't get rid of it
		self.discoveredPeripheral = peripheral;

		// And connect
		NSLog(@"Connecting to peripheral %@", peripheral);
		[self.centralManager connectPeripheral:peripheral options:nil];
	}
}

// If the connection fails for whatever reason, we need to deal with it.
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
	NSLog(@"Failed to connect to %@. (%@)", peripheral, [error localizedDescription]);
	[self cleanup];
}

// We've connected to the peripheral, now we need to discover the services and characteristics to find the characteristic.
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
	NSLog(@"Peripheral Connected");
//	_lblStatus.text = @"Peripheral Connected";
	[_button setTitle:@"Peripheral Connected" forState:UIControlStateNormal];

	// Stop scanning
	[self.centralManager stopScan];
	NSLog(@"Scanning stopped");

	// Clear the data that we may already have
	[self.data setLength:0];

	// Make sure we get the discovery callbacks
	peripheral.delegate = self;

	// Search only for services that match our UUID
//	[peripheral discoverServices:@[[CBUUID UUIDWithString:SERVICE_UUID]]];
	NSArray *services = [NSArray arrayWithObjects:/*[CBUUID UUIDWithString:ALERT_SERVICE_UUID],*/
		[CBUUID UUIDWithString:BATTERY_SERVICE_UUID], nil];
	[peripheral discoverServices:services];
}

// The Transfer Service was discovered
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
	if (error) {
		NSLog(@"Error discovering services: %@", [error localizedDescription]);
		[self cleanup];
		return;
	}

	// Discover the characteristic we want...

	// Loop through the newly filled peripheral.services array, just in case there's more than one.
	for (CBService *service in peripheral.services) {
		[peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:BATTERY_UUID]] forService:service];
		[peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:BATTERY_POWER_STATE_UUID]] forService:service];
	}
}

// The Transfer characteristic was discovered.
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
	// Deal with errors (if any)
	if (error) {
		NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
		[self cleanup];
		return;
	}

	// Again, we loop through the array, just in case.
	for (CBCharacteristic *characteristic in service.characteristics) {
		// And check if it's the right one
		if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:BATTERY_POWER_STATE_UUID]]) {
			// If it is, subscribe to it
			[peripheral setNotifyValue:YES forCharacteristic:characteristic];
		}
	}

	// Once this is complete, we just need to wait for the data to come in.
}

// This callback lets us know more data has arrived via notification on the characteristic
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
	if (error) {
		NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
		return;
	}

	NSLog(@"Received: %@", characteristic.value);
//	_lblStatus.text = [NSString stringWithFormat:@"Received: %@", characteristic.value];

	ushort value;
	NSMutableData *data = [NSMutableData dataWithData:characteristic.value];
	[data increaseLengthBy:8];
	[data getBytes:&value length:sizeof(value)];
//	[characteristic.value getBytes:&value length:1];
//	_lblStatus.text = [NSString stringWithFormat:@"Received: %hu", value];
	[_button setTitle:[NSString stringWithFormat:@"Received: %hu", value] forState:UIControlStateNormal];

	if (value == 1) {
		// PUSH!
		AudioServicesPlaySystemSound(1000);

		SMTPMessage *message = [SMTPMessage new];
		message.from = [_defaults stringForKey:@"mail_from"];
		message.to = [_defaults stringForKey:@"mail_to"];
		message.host = [_defaults stringForKey:@"mail_host"];
		message.account = [_defaults stringForKey:@"mail_account"];
		message.pwd = [_defaults stringForKey:@"mail_pwd"];

		message.contentType = @"text/plain";
		message.subject = [_defaults stringForKey:@"mail_subject"];
		message.content = [_defaults stringForKey:@"mail_content"];

		[message send:^(SMTPMessage * message, double now, double total) {
		} success:^(SMTPMessage * message) {
			NSLog(@"response = %@", [[NSString alloc] initWithData:message.response encoding:NSUTF8StringEncoding]);
		} failure:^(SMTPMessage * message, NSError * error) {
			NSLog(@"error = %@", error);
		}];
	}

/*	NSString *stringFromData = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];

	// Have we got everything we need?
	if ([stringFromData isEqualToString:@"EOM"]) {
		// We have, so show the data, 
//		[self.textview setText:[[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding]];

		// Cancel our subscription to the characteristic
		[peripheral setNotifyValue:NO forCharacteristic:characteristic];

		// and disconnect from the peripehral
		[self.centralManager cancelPeripheralConnection:peripheral];
	}

	// Otherwise, just add the data on to what we already have
	[self.data appendData:characteristic.value];*/

	// Log it
//	NSLog(@"Received: %@", stringFromData);
}

// The peripheral letting us know whether our subscribe/unsubscribe happened or not
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
	if (error) {
		NSLog(@"Error changing notification state: %@", error.localizedDescription);
	}

	// Exit if it's not the transfer characteristic
	if (![characteristic.UUID isEqual:[CBUUID UUIDWithString:BATTERY_POWER_STATE_UUID]]) return;

	if (characteristic.isNotifying) {
		// Notification has started
		NSLog(@"Notification began on %@", characteristic);
	} else {
		// Notification has stopped
		// so disconnect from the peripheral
		NSLog(@"Notification stopped on %@.  Disconnecting", characteristic);
		[self.centralManager cancelPeripheralConnection:peripheral];
	}
}

// Once the disconnection happens, we need to clean up our local copy of the peripheral
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
	NSLog(@"Peripheral Disconnected");
	self.discoveredPeripheral = nil;

	// We're disconnected, so start scanning again
	[self scan];
}

// Call this when things either go wrong, or you're done with the connection.
- (void)cleanup
{
	// Don't do anything if we're not connected
	if (self.discoveredPeripheral.state != CBPeripheralStateConnected) return;

	// See if we are subscribed to a characteristic on the peripheral
	if (self.discoveredPeripheral.services != nil) {
		for (CBService *service in self.discoveredPeripheral.services) {
			if (service.characteristics != nil) {
				for (CBCharacteristic *characteristic in service.characteristics) {
					if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:BATTERY_POWER_STATE_UUID]]) {
						if (characteristic.isNotifying) {
							// It is notifying, so unsubscribe
							[self.discoveredPeripheral setNotifyValue:NO forCharacteristic:characteristic];
							// And we're done.
							return;
						}
					}
				}
			}
		}
	}

	// If we've got this far, we're connected, but we're not subscribed, so we just disconnect
	[self.centralManager cancelPeripheralConnection:self.discoveredPeripheral];
}

- (void)initUserData
{
	/*NSUserDefaults **/_defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *dict = @{
		@"mail_from"	: @"mail@gmail.com",
		@"mail_to"	: @"mail@ezweb.ne.jp",
		@"mail_host"	: @"smtp.gmail.com",
		@"mail_account"	: @"mail@gmail.com",
		@"mail_pwd"	: @"pass",

		@"mail_subject"	: @"よびだし〜",
		@"mail_content"	: @"ごはん〜ごはん〜",
	};
	[_defaults registerDefaults:dict];
}

@end
