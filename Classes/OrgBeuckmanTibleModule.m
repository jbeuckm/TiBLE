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
@property (nonatomic, strong) CBPeripheral *peripheral;

@end


@implementation OrgBeuckmanTibleModule

#pragma mark - Constants

static NSString *const kServiceUUID = @"5B2EABB7-93CB-4C6A-94D4-C6CF2F331ED5";
static NSString *const kFlexServiceUUID = @"ADABFB00-6E7D-4601-BDA2-BFFAA68956BA";

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
    NSString *uuid = (NSString*)CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, peripheral.UUID));

    NSMutableDictionary *event = [[NSMutableDictionary alloc]  init];
    
    if (peripheral.name)
        [event setObject:peripheral.name forKey:@"name"];
    if (uuid)
        [event setObject:uuid forKey:@"uuid"];
    if (peripheral.RSSI)
        [event setObject:peripheral.RSSI forKey:@"rssi"];
    
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
    if (self.peripheral != nil) {
        [self.manager cancelPeripheralConnection:self.peripheral];
    }
	
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

/*
 * Accepts an array of service UUID strings (must scan for particular services to operate in background)
 */
- (void)startScan:(NSArray *)args {

    ENSURE_UI_THREAD_1_ARG(args);
    NSLog(@"[DEBUG] startScan received args %@", args);

    NSDictionary *options = @{CBCentralManagerScanOptionAllowDuplicatesKey: @YES};
    
    if (args.count == 0) {
        NSLog(@"[INFO] TiBLE scanning for any(all) service UUIDs");
        [self.manager scanForPeripheralsWithServices:nil options:options];
    }
    else {
        NSMutableArray *uuids =[[NSMutableArray alloc] init];
        
        for (int i=0; i<args.count; i++) {
            
            NSString *uuidString = [TiUtils stringValue:[args objectAtIndex:i]];
            
            @try {
                NSLog(@"[DEBUG] scanning with uuid %@", uuidString);
                CBUUID *serviceUUID = [CBUUID UUIDWithString:uuidString];
                [uuids addObject:serviceUUID];
            }
            @catch (NSException *exception) {
                NSLog(@"[ERROR] %@", exception.reason);
            }
        }
    
        [self.manager scanForPeripheralsWithServices:uuids options:options];
    }
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
        return [self decodeState:self.manager.state];
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

    if (self.peripheral == peripheral) {
        self.peripheral = nil;
    }
    
//    [self startScan:nil];
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    
    NSLog(@"[INFO] didDiscoverPeripheral %@", peripheral.name);

    NSString *uuid = (NSString*)CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, peripheral.UUID));

    NSMutableDictionary *report = [[NSMutableDictionary alloc] init];
    if (peripheral.name)
    [report setObject:peripheral.name forKey:@"name"];
    if (uuid)
    [report setObject:uuid forKey:@"uuid"];
    if (RSSI)
    [report setObject:RSSI forKey:@"rssi"];
    
    if (advertisementData)
        [report setObject:[self summarizeAdvertisement:advertisementData] forKey:@"advertisementData"];

    
    [self fireEvent:@"discover" withObject:report];
    
    
/*
    if (self.peripheral != peripheral) {
        self.peripheral = peripheral;
    }
    
    [self stopScan:nil];
    
    [central connectPeripheral:peripheral options:nil];
*/
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    
    [self fireEvent:@"connectFail" withObject:[self eventForPeripheral:peripheral]];

    if (self.peripheral == peripheral) {
        self.peripheral = nil;
    }
    
//    [self startScan:nil];
}


-(NSDictionary *)summarizeAdvertisement:(NSDictionary*)advertisementData
{
    NSLog(@"[TRACE] advertisementData = %@", advertisementData);
    
    NSMutableDictionary *summary = [[NSMutableDictionary alloc] init];
    NSMutableArray *services = [[NSMutableArray alloc] init];

    NSArray *keys = [advertisementData allKeys];
    for (int i = 0; i < [keys count]; ++i) {
        
        id key = [keys objectAtIndex: i];
        
        NSString *keyName = (NSString *) key;
        NSObject *value = [advertisementData objectForKey: key];
        
        if ([value isKindOfClass: [NSArray class]]) {
            
            NSArray *values = (NSArray *) value;
            
            for (int j = 0; j < [values count]; ++j) {
                if ([[values objectAtIndex: j] isKindOfClass: [CBUUID class]]) {
                    
                    CBUUID *uuid = [values objectAtIndex: j];
                    
                    NSString *uuidString = [self stringFromCBUUID:uuid];
                    [services addObject:uuidString];
                    
                }
                else {
                    if ([[values objectAtIndex: j] description]) {
                        [services addObject:[[values objectAtIndex: j] description]];
                    }
                }
            }
        }
        else if ([value isKindOfClass: [NSDictionary class]]) {
            NSLog(@"skipping advertised NSDictionary %@", value);
/*
            NSDictionary *subvalues = (NSDictionary *)value;
            NSArray *subkeys = [subvalues allKeys];
            for (int i = 0; i < [subkeys count]; ++i) {
                id subkey = [keys objectAtIndex: i];
                
                NSString *subkeyName = (NSString *)subkey;
                NSObject *subvalue = [subvalues objectForKey: subkey];

                if ([[subvalues objectForKey:subkey] isKindOfClass: [CBUUID class]]) {
                    CBUUID *uuid = [subvalues objectForKey:subkey];
                    
                    NSString *uuidString = [self stringFromCBUUID:uuid];
                    [summary addObject:uuidString forKey:subkeyName];
                }
                else {
                    [summary addObject:[subvalues objectForKey:subkey] forKey:subkeyName];
                }
            }
 */
        }
        else {
            [summary addObject:[value description] forKey:keyName];
        }
    }
    
    [summary addObject:services forKey:@"services"];
    
    return summary;
}


- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    
    NSString *state = [self decodeState:central.state];

    [self fireEvent:@"state" withObject:[NSDictionary dictionaryWithObjectsAndKeys:state, @"state", nil]];
}

-(NSString *)decodeState:(NSInteger)state {
    
    NSString *result;
    
    if (state == CBCentralManagerStatePoweredOn) {
        result = @"on";
        //        [self startScan:nil];
    }
    if (state == CBCentralManagerStateUnknown) {
        result = @"unknown";
    }
    if (state == CBCentralManagerStateResetting) {
        result = @"resetting";
    }
    if (state == CBCentralManagerStateUnsupported) {
        result = @"unsupported";
    }
    if (state == CBCentralManagerStateUnauthorized) {
        result = @"unauthorized";
    }
    if (state == CBCentralManagerStatePoweredOff) {
        result = @"off";
    }
    
    return result;
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
    
    
    NSLog(@"%@", peripheral.services);
    
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


- (NSString *)stringFromCBUUID:(CBUUID *)cbuuid;
{
    NSData *data = [cbuuid data];
    
    NSUInteger bytesToConvert = [data length];
    const unsigned char *uuidBytes = [data bytes];
    NSMutableString *outputString = [NSMutableString stringWithCapacity:16];
    
    for (NSUInteger currentByteIndex = 0; currentByteIndex < bytesToConvert; currentByteIndex++)
    {
        switch (currentByteIndex)
        {
            case 3:
            case 5:
            case 7:
            case 9:[outputString appendFormat:@"%02x-", uuidBytes[currentByteIndex]]; break;
            default:[outputString appendFormat:@"%02x", uuidBytes[currentByteIndex]];
        }
        
    }
    
    return outputString;
}

@end
