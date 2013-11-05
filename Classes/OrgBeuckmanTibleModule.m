/**
 * Your Copyright Here
 *
 * Appcelerator Titanium is Copyright (c) 2009-2010 by Appcelerator, Inc.
 * and licensed under the Apache Public License (version 2)
 */
#import "OrgBeuckmanTibleModule.h"
#import "TiBase.h"
#import "TiHost.h"
#import "TiUtils.h"

@interface OrgBeuckmanTibleModule ()

@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, strong) CBCentralManager *manager;
//@property (nonatomic, strong) CBPeripheral *peripheral;

@property (nonatomic, strong) NSMutableDictionary *peripherals;

@end


@implementation OrgBeuckmanTibleModule

#pragma mark - Constants

static NSString *const kServiceUUID = @"5B2EABB7-93CB-4C6A-94D4-C6CF2F331ED5";
static NSString *const kCharacteristicUUID = @"D589A9D6-C7EE-44FC-8F0E-46DD631EC940";



#pragma mark Internal

// this is generated for your module, please do not change it
-(id)moduleGUID
{
	return @"ba095e33-4159-4a8a-8cd3-2b35cde1c52c";
}

// this is generated for your module, please do not change it
-(NSString*)moduleId
{
	return @"org.beuckman.tible";
}

-(NSDictionary*)eventForPeripheral:(CBPeripheral *)peripheral
{
    NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:
            peripheral.name, @"name",
            peripheral.RSSI, @"rssi",
            nil];
    
    return event;
}

#pragma mark Lifecycle

-(void)startup
{
	// this method is called when the module is first loaded
	// you *must* call the superclass
	[super startup];

    self.manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];

	NSLog(@"[INFO] %@ loaded",self);
}

-(void)shutdown:(id)sender
{
	// this method is called when the module is being unloaded
	// typically this is during shutdown. make sure you don't do too
	// much processing here or the app will be quit forceably
//    if (self.peripheral != nil) {
//        [self.manager cancelPeripheralConnection:self.peripheral];
//    }
	
	// you *must* call the superclass
	[super shutdown:sender];
}

#pragma mark Cleanup 

-(void)dealloc
{
	// release any resources that have been retained by the module
	[super dealloc];
}

#pragma mark Internal Memory Management

-(void)didReceiveMemoryWarning:(NSNotification*)notification
{
	// optionally release any resources that can be dynamically
	// reloaded once memory is available - such as caches
	[super didReceiveMemoryWarning:notification];
}

#pragma mark Listener Notifications

-(void)_listenerAdded:(NSString *)type count:(int)count
{
	if (count == 1 && [type isEqualToString:@"my_event"])
	{
		// the first (of potentially many) listener is being added 
		// for event named 'my_event'
	}
}

-(void)_listenerRemoved:(NSString *)type count:(int)count
{
	if (count == 0 && [type isEqualToString:@"my_event"])
	{
		// the last listener called for event named 'my_event' has
		// been removed, we can optionally clean up any resources
		// since no body is listening at this point for that event
	}
}

#pragma Public APIs

- (void)startScan:(id)args {

    ENSURE_UI_THREAD_1_ARG(args);
    ENSURE_SINGLE_ARG(args, NSDictionary);
    
    NSString *uuid = [TiUtils stringValue:[args objectForKey:@"uuid"]];
    
//    if (!uuid) {
        // default service uuid
        uuid = kServiceUUID;
//    }
    
    NSDictionary *options = @{CBCentralManagerScanOptionAllowDuplicatesKey: @YES};

    CBUUID *serviceUUID = [CBUUID UUIDWithString:uuid];
//    [self.manager scanForPeripheralsWithServices:@[serviceUUID] options:options];
    [self.manager scanForPeripheralsWithServices:nil options:options];
}

- (void)stopScan:(id)args {
    [self.manager stopScan];
}



-(id)example:(id)args
{
	// example method
	return @"hello world";
}

/*
 * Report the state of the BLE manager instance
 */
-(id)state
{
    if (self.manager) {
        return self.manager.state;
    }
    else {
        return nil;
    }
}

/*
-(void)setExampleProp:(id)value
{
	// example property setter
}
*/

#pragma mark - Protocol Methods - CBCentralManagerDelegate

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    
    NSLog(@"[INFO] didConnectPeripheral %@", peripheral.name);
    [self fireEvent:@"connect" withObject:[self eventForPeripheral:peripheral]];
    
    CBUUID *serviceUUID = [CBUUID UUIDWithString:kServiceUUID];
    peripheral.delegate = self;
//    [peripheral discoverServices:@[serviceUUID]];
    [peripheral discoverServices:nil];

}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    
    NSLog(@"[INFO] didDisconnectPeripheral %@", peripheral.name);
    [self fireEvent:@"disconnect" withObject:[self eventForPeripheral:peripheral]];

//    if (self.peripheral == peripheral) {
//        self.peripheral = nil;
//    }
    
    [self startScan:nil];
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    
    NSString *uuid = (NSString*)CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, peripheral.UUID));
    //(__bridge_transfer NSString*)CFUUIDCreateString(kCFAllocatorDefault, peripheral.UUID);
    
    NSMutableDictionary *report = [[NSMutableDictionary alloc] init];
    
    NSMutableArray *services = [[NSMutableArray alloc] init];

    NSArray *keys = [advertisementData allKeys];
    for (int i = 0; i < [keys count]; ++i) {
        id key = [keys objectAtIndex: i];
        NSString *keyName = (NSString *) key;
        NSObject *value = [advertisementData objectForKey: key];
        if ([value isKindOfClass: [NSArray class]]) {
            printf("   key: %s\n", [keyName cStringUsingEncoding: NSUTF8StringEncoding]);
            NSArray *values = (NSArray *) value;
            for (int j = 0; j < [values count]; ++j) {
                if ([[values objectAtIndex: j] isKindOfClass: [CBUUID class]]) {
                    CBUUID *uuid = [values objectAtIndex: j];
                    NSData *data = uuid.data;
                    printf("      uuid(%d):", j);
                    
                    NSString *str = [[[NSString alloc] initWithData:uuid.data
                                           encoding:NSUTF8StringEncoding] autorelease];

                    if (str)
                        [services addObject:str];
                    
                } else {
                    const char *valueString = [[value description] cStringUsingEncoding: NSUTF8StringEncoding];
                    printf("      value(%d): %s\n", j, valueString);
                    
                    if ([value description])
                        [services addObject:[value description]];
                }
            }
        } else {
            const char *valueString = [[value description] cStringUsingEncoding: NSUTF8StringEncoding];
            printf("   key: %s, value: %s\n", [keyName cStringUsingEncoding: NSUTF8StringEncoding], valueString);
        }
    }

    
    [report setObject:peripheral.name forKey:@"name"];
    [report setObject:uuid forKey:@"uuid"];
    [report setObject:RSSI forKey:@"rssi"];
    [report setObject:services forKey:@"services"];
    
    
    NSLog(@"[INFO] didDiscoverPeripheral %@", peripheral.name);
    [self fireEvent:@"discover" withObject:report];
     
//    if (self.peripheral != peripheral) {
//        self.peripheral = peripheral;
//    }
    
//    [self stopScan:nil];

    [central connectPeripheral:peripheral options:nil];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    
    [self fireEvent:@"connectFail" withObject:[self eventForPeripheral:peripheral]];

//    if (self.peripheral == peripheral) {
//        self.peripheral = nil;
//    }
    
    [self startScan:nil];
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    
    NSString *state;
    
    if (central.state == CBCentralManagerStatePoweredOn) {
        state = @"on";
        [self startScan:nil];
    }
    if (central.state == CBCentralManagerStateUnknown) {
        state = @"unknown";
    }
    if (central.state == CBCentralManagerStateResetting) {
        state = @"resetting";
    }
    if (central.state == CBCentralManagerStateUnsupported) {
        state = @"unsupported";
    }
    if (central.state == CBCentralManagerStateUnauthorized) {
        state = @"unauthorized";
    }
    if (central.state == CBCentralManagerStatePoweredOff) {
        state = @"off";
    }

    [self fireEvent:@"state" withObject:[NSDictionary dictionaryWithObjectsAndKeys:state, @"state", nil]];
}

#pragma mark - Protocol Methods - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    
    [self fireEvent:@"characteristics" withObject:[self eventForPeripheral:peripheral]];

    if (error != nil) {
        NSLog(@"[ERROR] Error discovering characteristic: %@", [error localizedDescription]);
        
        return;
    }
    
    CBUUID *serviceUUID = [CBUUID UUIDWithString:kServiceUUID];
    
    if ([service.UUID isEqual:serviceUUID]) {
        CBUUID *characteristicUUID = [CBUUID UUIDWithString:kCharacteristicUUID];
        
        for (CBCharacteristic *characteristic in service.characteristics) {
            
            if ([characteristic.UUID isEqual:characteristicUUID]) {
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            }
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    
    [self fireEvent:@"services" withObject:[self eventForPeripheral:peripheral]];

    if (error != nil) {
        NSLog(@"[ERROR] Error discovering service: %@", [error localizedDescription]);
        
        return;
    }
    
    for (CBService *service in peripheral.services) {
        CBUUID *serviceUUID = [CBUUID UUIDWithString:kServiceUUID];
        
        if ([service.UUID isEqual:serviceUUID]) {
            CBUUID *characteristicUUID = [CBUUID UUIDWithString:kCharacteristicUUID];
            [peripheral discoverCharacteristics:@[characteristicUUID] forService:service];
        }
        
        if ([service.UUID isEqual:[CBUUID UUIDWithString:CBUUIDGenericAccessProfileString]]) {
            [peripheral discoverCharacteristics:nil forService:service];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    [self fireEvent:@"value" withObject:[self eventForPeripheral:peripheral]];

    if (error != nil) {
        NSLog(@"[ERROR] Error updating value: %@", error.localizedDescription);
        return;
    }
}


@end
