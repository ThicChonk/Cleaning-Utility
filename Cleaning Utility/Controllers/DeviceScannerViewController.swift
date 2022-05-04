//
//  DeviceScannerViewController.swift
//  Cleaning Utility
//
//  Created by Aram Aprahamian on 5/2/22.
//

import Foundation
import UIKit
import CoreBluetooth

class DeviceScannerViewController: UIViewController {
    
    
    /// The peripherals that have been discovered (no duplicates and sorted by asc RSSI)
    var peripherals: [(peripheral: CBPeripheral, RSSI: Float)] = []
    
    /// The peripheral the user has selected
    var selectedPeripheral: CBPeripheral?
    
    private var timer = Timer()
    
    
    // UI
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var peripheralFoundLabel: UILabel!
    @IBOutlet weak var scanningLabel: UILabel!
    @IBOutlet weak var scanningButton: UIButton!
    
    @IBAction func scanningAction(_ sender: Any) {
        peripherals = []
        startScanning()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scanningButton.isEnabled = false
        
        //init
        serial.delegate = self
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.reloadData()
        
        if serial.centralManager.state != .poweredOn {
            title = "Bluetooth not turned on"
            return
        }
        
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startScanning()
        Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(DeviceScannerViewController.scanTimeOut), userInfo: nil, repeats: false)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func connectTimeOut() {
        // don't if we've already connected
        if let _ = serial.connectedPeripheral {
            return
        }
        
        if let _ = selectedPeripheral {
            serial.disconnect()
            selectedPeripheral = nil
        }
    }
    
    @objc func scanTimeOut() {
        // timeout has occurred, stop scanning and give the user the option to try again
        serial.stopScan()
        scanningButton.isEnabled = true
    }
    
    func connectToDevice() -> Void {
        serial.stopScan()
        scanningButton.isEnabled = true
        serial.connectToPeripheral(selectedPeripheral!)
    }
    
    func disconnectFromDevice() {
        serial.disconnect()
    }
    
    func removeArrayData() -> Void {
        serial.centralManager.cancelPeripheralConnection(selectedPeripheral!)
        peripherals.removeAll()
    }
    
    func startScanning() -> Void {
        // Remove prior data
        peripherals = []
        // Start Scanning
        serial.startScan()
        scanningLabel.text = "Scanning..."
        scanningButton.isEnabled = false
        Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(DeviceScannerViewController.scanTimeOut), userInfo: nil, repeats: false)
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
}

// MARK: - UITableViewDataSource
// The methods adopted by the object you use to manage data and provide cells for a table view.
extension DeviceScannerViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peripherals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "BlueCell") as! TableViewCell
        
        let peripheralFound = self.peripherals[indexPath.row].peripheral
        
        let rssiFound = self.peripherals[indexPath.row].RSSI
        
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
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        // the user has selected a peripheral, so stop scanning and proceed to the next view
        serial.stopScan()
        selectedPeripheral = peripherals[(indexPath as NSIndexPath).row].peripheral
        serial.connectToPeripheral(selectedPeripheral!)
        connectToDevice()
        // TODO: Timer doesn't use connecting ID
        Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(DeviceScannerViewController.connectTimeOut), userInfo: nil, repeats: false)
        
    }
}

// MARK: - BluetoothSerialDelegate
extension DeviceScannerViewController: BluetoothSerialDelegate {
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
        
        scanningButton.isEnabled = true
    }
    
    func serialDidDiscoverPeripheral(_ peripheral: CBPeripheral, RSSI: NSNumber?) {
        // check whether it is a duplicate
        for exisiting in peripherals {
            if exisiting.peripheral.identifier == peripheral.identifier { return }
        }
        
        // add to the array, next sort & reload
        let theRSSI = RSSI?.floatValue ?? 0.0
        peripherals.append((peripheral: peripheral, RSSI: theRSSI))
        print("Peripheral Discovered: \(peripheral)")
        peripherals.sort { $0.RSSI < $1.RSSI }
        tableView.reloadData()
    }
    
    func serialDidFailToConnect(_ peripheral: CBPeripheral, error: NSError?) {
        scanningButton.isEnabled = true
    }
    
    func serialIsReady(_ peripheral: CBPeripheral) {
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadStartViewController"), object: self)
        dismiss(animated: true, completion: nil)
    }
}

