//
//  DeviceScannerViewController.swift
//  Cleaning Utility
//
//  Created by Aram Aprahamian on 5/2/22.
//

import Foundation
import UIKit
import CoreBluetooth

class DeviceScannerViewController: UIViewController, BluetoothSerialDelegate {
    
    /// The peripherals that have been discovered (no duplicates and sorted by asc RSSI)
    var peripherals: [(peripheral: CBPeripheral, RSSI: Float)] = []
    
    /// The peripheral the user has selected
    var selectedPeripheral: CBPeripheral?
    
    // Data
    private var centralManager: CBCentralManager!
    private var bluefruitPeripheral: CBPeripheral!
    private var txCharacteristic: CBCharacteristic!
    private var rxCharacteristic: CBCharacteristic!
    private var peripheralArray: [CBPeripheral] = []
    private var rssiArray = [NSNumber]()
    private var timer = Timer()
    
    // UI
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var peripheralFoundLabel: UILabel!
    @IBOutlet weak var scanningLabel: UILabel!
    @IBOutlet weak var scanningButton: UIButton!
    
    @IBAction func scanningAction(_ sender: Any) {
        startScanning()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //init
        serial.delegate = self
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.reloadData()
        
        //startScanning()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        serial.disconnect()
        self.tableView.reloadData()
        //startScanning()
    }
    
    
    func connectToDevice() -> Void {
        serial.connectToPeripheral(bluefruitPeripheral)
    }
    
    func disconnectFromDevice() {
        serial.disconnect()
    }
    
    func removeArrayData() -> Void {
        serial.centralManager.cancelPeripheralConnection(bluefruitPeripheral)
        rssiArray.removeAll()
        peripheralArray.removeAll()
    }
    
    func startScanning() -> Void {
        // Remove prior data
        peripheralArray.removeAll()
        rssiArray.removeAll()
        // Start Scanning
        serial.startScan()
        scanningLabel.text = "Scanning..."
        scanningButton.isEnabled = false
        Timer.scheduledTimer(withTimeInterval: 15, repeats: false) {_ in self.stopScanning() }
    }
    
    func stopTimer() -> Void {
        // Stops Timer
        self.timer.invalidate()
    }
    
    func stopScanning() -> Void {
        scanningLabel.text = ""
        scanningButton.isEnabled = true
        serial.stopScan()
    }
    
    func delayedConnection() -> Void {
        
        //serial.connectedPeripheral = bluefruitPeripheral
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            //Once connected, move to new view controller to manager incoming and outgoing data
            
            self.dismiss(animated: true, completion: nil)
        })
    }
    
    // MARK: - BluetoothSerialDelegate
    func serialDidChangeState() {
        switch serial.centralManager.state {
        case .poweredOff:
            print("Is Powered Off.")
            
            let alertVC = UIAlertController(title: "Bluetooth Required", message: "Check your Bluetooth Settings", preferredStyle: UIAlertController.Style.alert)
            
            let action = UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: { (action: UIAlertAction) -> Void in
                self.dismiss(animated: true, completion: nil)
            })
            
            alertVC.addAction(action)
            
            self.present(alertVC, animated: true, completion: nil)
            
        case .poweredOn:
            print("Is Powered On.")
            startScanning()
        case .unsupported:
            print("Is Unsupported.")
        case .unauthorized:
            print("Is Unauthorized.")
        case .unknown:
            print("Unknown")
        case .resetting:
            print("Resetting")
        @unknown default:
            print("Error")
        }
    }
    
    func serialDidDisconnect(_ peripheral: CBPeripheral, error: NSError?) {
        print("Disconnected from: " + (peripheral.name ?? "Null"))
    }
}

// MARK: - UITableViewDataSource
// The methods adopted by the object you use to manage data and provide cells for a table view.
extension DeviceScannerViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.peripheralArray.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "BlueCell") as! TableViewCell
        
        let peripheralFound = self.peripheralArray[indexPath.row]
        
        let rssiFound = self.rssiArray[indexPath.row]
        
        if peripheralFound == nil {
            cell.peripheralLabel.text = "Unknown"
        }else {
            cell.peripheralLabel.text = peripheralFound.name
            cell.rssiLabel.text = "RSSI: \(rssiFound)"
        }
        return cell
    }
    
    
}


// MARK: - UITableViewDelegate
// Methods for managing selections, deleting and reordering cells and performing other actions in a table view.
extension DeviceScannerViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        bluefruitPeripheral = peripheralArray[indexPath.row]
        
        BlePeripheral.connectedPeripheral = bluefruitPeripheral
        
        connectToDevice()
    }
}
