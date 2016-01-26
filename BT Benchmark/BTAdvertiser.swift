import CoreBluetooth
import Darwin

class BTAdvertiser: NSObject, CBPeripheralManagerDelegate, CBCentralManagerDelegate {
    private let peripheralLock = NSObject()
    private let centralLock = NSObject()
    
    private var peripheralManager: CBPeripheralManager?
    private var centralManager: CBCentralManager?
    
    var timer: Timer
    var whenDone: Timer -> Void
    var withPolling: Bool
    
    init(whenDone: Timer -> Void, withPolling: Bool) {
        self.timer = Timer()
        self.whenDone = whenDone
        self.withPolling = withPolling
        
        super.init()
        
        self.peripheralManager = CBPeripheralManager(
            delegate: self,
            queue: getBackgroundQueue(),
            options: [CBPeripheralManagerOptionShowPowerAlertKey: false]
        )
        
        if withPolling {
            self.centralManager = CBCentralManager(delegate: self, queue: getBackgroundQueue(), options: [CBCentralManagerOptionShowPowerAlertKey: true])
        }
    }
    
    private func lockPeripheral(action: () -> Void) {
        synchronized(self.peripheralLock) {
            action()
        }
    }
    
    private func lockCentral(action: () -> Void) {
        synchronized(self.centralLock) {
            action()
        }
    }
    
    private func terminatePeripheral() {
        if let manager = self.peripheralManager {
            manager.delegate = nil
            if manager.isAdvertising {
                manager.stopAdvertising()
            }
        }
    }
    
    private func terminateScanning() {
        if let central = self.centralManager {
            centralManager?.delegate = nil
            if central.isScanning {
                centralManager?.stopScan()
            }
        }
    }
    
    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager) {
        self.lockPeripheral {
            switch peripheral.state {
            case .PoweredOff:
                self.terminatePeripheral()
            case .PoweredOn:
                let advertisedService = CBMutableService(type: CBUUID(), primary: true)
                self.peripheralManager!.addService(advertisedService)
            case .Unauthorized:
                self.terminatePeripheral()
            case .Unsupported:
                break
            default:
                break
            }
        }
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, didAddService service: CBService, error: NSError?) {
        self.lockPeripheral {
            if self.withPolling {
                self.lockCentral {self.centralManager?.scanForPeripheralsWithServices(nil, options: nil)}
            }
            self.peripheralManager?.startAdvertising(nil)
            self.timer.start()
        }
    }
    
    func peripheralManagerDidStartAdvertising(peripheral: CBPeripheralManager, error: NSError?) {
        self.lockPeripheral {
            self.terminatePeripheral()
            self.timer.stop()
            if self.withPolling {
                self.lockCentral {self.terminateScanning()}
            }
            main {self.whenDone(self.timer)}
        }
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        self.lockCentral {
            switch central.state {
            case .PoweredOff:
                self.terminateScanning()
            case .PoweredOn:
                break
            case .Unauthorized:
                self.terminateScanning()
            case .Unsupported:
                break
            default:
                break
            }
        }
    }
}