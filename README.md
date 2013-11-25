## Titanium Bluetooth LE 

At this point, the module can discover BLE devices.

```javascript

var ble = require("org.beuckman.tible");

ble.addEventListener("state", function(e){
        alert(e);
});

ble.addEventListener("discover", function(e){
        Ti.API.info("discovered "+e.name+" at "+e.rssi+"db");
        Ti.API.info("locally assigned uuid: "+e.uuid);
        Ti.API.info(e.services);
});
ble.addEventListener("connect", function(e){
        alert(e);
});
ble.addEventListener("connectFail", function(e){
        alert(e);
});
ble.addEventListener("disconnect", function(e){
        alert(e);
});

ble.addEventListener("services", function(e){
        alert(e);
});
ble.addEventListener("characteristics", function(e){
        alert(e);
});
ble.addEventListener("value", function(e){
        alert(e);
});

ble.startScan();

```

Please see the test app: [https://github.com/jbeuckm/TiBLE-Test-App](https://github.com/jbeuckm/TiBLE-Test-App)
