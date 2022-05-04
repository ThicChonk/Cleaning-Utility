//
//  ViewController.swift
//  Glasses Cleaner Utility
//
//  Created by Aram Aprahamian on 3/2/22.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, BluetoothSerialDelegate {
    
    //MARK: IBOutlets
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var connectionLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var startCycleButton: UIButton!
    @IBOutlet weak var connectButton: UIButton!
    
    
    //System variables
    var progress: Float = 0
    
    var peripheralManager: CBPeripheralManager?
    var peripheral: CBPeripheral?
    var periperalTXCharacteristic: CBCharacteristic?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("View Loaded")
        
        serial = BluetoothSerial(delegate: self)
        //UI
        progressBar.progress = 0;
        
        reloadUI()
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.reloadUI), name: NSNotification.Name(rawValue: "reloadStartViewController"), object: nil)
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    //MARK: IBActions
    @IBAction func toggleButtonPressed(_ sender: UIButton) {
        //Starts the cleaning cycle
        
        if !serial.isReady {
            let alert = UIAlertController(title: "Not connected", message: "What am I supposed to send this to?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertAction.Style.default, handler: { action -> Void in self.dismiss(animated: true, completion: nil) }))
            present(alert, animated: true, completion: nil)
        } else {
            print("Serial is connected and sending message!")
            serial.sendMessageToDevice("1")
            print("Sent \"1\"")
        }
        
    }
    
    @IBAction func connectButtonToggled(_ sender: UIButton) {
        reloadUI()
        
        if(!serial.isReady) {
            self.performSegue(withIdentifier: "goToDevices", sender: self)
        } else {
            disconnectPeripheral()
        }
    }
    
    func writeOutgoingValue(data: String){
        let valueString = (data as NSString).data(using: String.Encoding.utf8.rawValue)
        //change the "data" to valueString
        if let blePeripheral = BlePeripheral.connectedPeripheral {
            if let txCharacteristic = BlePeripheral.connectedTXChar {
                blePeripheral.writeValue(valueString!, for: txCharacteristic, type: CBCharacteristicWriteType.withResponse)
            }
        }
    }
    
    func disconnectPeripheral() {
        print("Disconnect for peripheral.")
    }
    
    func writeCharacteristic(incomingValue: Int8){
        var val = incomingValue
        
        let outgoingData = NSData(bytes: &val, length: MemoryLayout<Int8>.size)
        peripheral?.writeValue(outgoingData as Data, for: BlePeripheral.connectedTXChar!, type: CBCharacteristicWriteType.withResponse)
    }
    
    @objc func reloadUI() {
        progressBar.progress = progress
        serial.delegate = self
        
        if serial.isReady {
            connectionLabel.text = "Connected To: " + BlePeripheral.connectedPeripheral!.name!
            statusLabel.text = ""
            startCycleButton.tintColor = .systemBlue
            connectButton.tintColor = .systemRed
            connectButton.setTitle("Disconnect", for: .normal)
        } else if serial.centralManager.state == .poweredOn {
            startCycleButton.tintColor = .systemGray
            connectionLabel.text = ""
            statusLabel.text = "Not Connected"
            connectButton.setTitle("Connect", for: .normal)
        } else {
            startCycleButton.tintColor = .systemGray
            connectionLabel.text = ""
            statusLabel.text = "Not Connected"
            connectButton.setTitle("Connect", for: .normal)
        }
    }
    
    //MARK: BluetoothSerialDelegate
    
    func serialDidReceiveString(_ message: String) {
        reloadUI()
        // add the received text to the textView, optionally with a line break at the end
        print(message)
    }
    
    func serialDidDisconnect(_ peripheral: CBPeripheral, error: NSError?) {
        reloadUI()
    }
    
    func serialDidChangeState() {
        reloadUI()
    }
}
