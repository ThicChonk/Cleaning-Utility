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
    var progress: Float = 0.0
    var isRunning: Bool = false
    var status: String = "Idle"
    
    var peripheralManager: CBPeripheralManager?
    var peripheral: CBPeripheral?
    var periperalTXCharacteristic: CBCharacteristic?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("View Loaded")
        startCycleButton.tintColor = .systemBlue
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
        reloadUI()
        
        //Starts the cleaning cycle
        if !serial.isReady {
            let alert = UIAlertController(title: "Not connected", message: "What am I supposed to send this to?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertAction.Style.default, handler: { action -> Void in self.dismiss(animated: true, completion: nil) }))
            present(alert, animated: true, completion: nil)
        } else if !isRunning {
            print("Serial is connected and sending message!")
            serial.sendMessageToDevice("1")
            print("Sent \"1\"")
            progress = 0.0
            isRunning = true
            status = "Starting..."
        }
        
        reloadUI()
    }
    
    @IBAction func connectButtonToggled(_ sender: UIButton) {
        reloadUI()
        if(!serial.isReady) {
            self.performSegue(withIdentifier: "goToDevices", sender: self)
        } else if isRunning {
            let alertVC = UIAlertController(title: "Cycle Running", message: "Glasses are currently in the process of cleaning", preferredStyle: UIAlertController.Style.alert)
            
            let action = UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: { (action: UIAlertAction) -> Void in self.dismiss(animated: true, completion: nil)
                
            })
            
            alertVC.addAction(action)
            
            self.present(alertVC, animated: true, completion: nil)
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
        progress = 0.0
        serial.disconnect()
        reloadUI()
    }
    
    func writeCharacteristic(incomingValue: Int8){
        var val = incomingValue
        
        let outgoingData = NSData(bytes: &val, length: MemoryLayout<Int8>.size)
        peripheral?.writeValue(outgoingData as Data, for: BlePeripheral.connectedTXChar!, type: CBCharacteristicWriteType.withResponse)
    }
    
    
    
    //MARK: BluetoothSerialDelegate
    
    func serialDidReceiveString(_ message: String) {
        reloadUI()
        // add the received text to the textView, optionally with a line break at the end
        print(message)
        
        let switchstate: Character = Array(message)[0]
        
        switch switchstate {
        case "p":
            status = "Running"
            let value = Float(message[1..<4])
            progress = value!
            
            if(progress == 1.0) {
                isRunning = false
            } else {
                isRunning = true
            }
            
            break;
        case "d":
            progress = 1.0
            isRunning = false
            print("done!")
        default:
            print("Invalid command given")
            progress = 0.0
            isRunning = false
        }
        
        reloadUI()
    }
    
    func serialDidDisconnect(_ peripheral: CBPeripheral, error: NSError?) {
        isRunning = false
        reloadUI()
    }
    
    func serialDidChangeState() {
        reloadUI()
    }
    
    //MARK: Reload UI
    
    @objc func reloadUI() {
        progressBar.progress = progress
        serial.delegate = self
        
        if(isRunning) {
            startCycleButton.tintColor = .systemGreen
        } else {
            status = "Idle"
            startCycleButton.tintColor = .systemBlue
        }
        
        if serial.isReady {
            connectionLabel.text = "Connected To: " + BlePeripheral.connectedPeripheral!.name!
            statusLabel.text = ""
            connectButton.tintColor = .systemRed
            connectButton.setTitle("Disconnect", for: .normal)
        } else if serial.centralManager.state == .poweredOn {
            startCycleButton.tintColor = .systemGray
            connectButton.tintColor = .systemBlue
            connectionLabel.text = ""
            status = "Not Connected"
            connectButton.setTitle("Connect", for: .normal)
        } else {
            startCycleButton.tintColor = .systemGray
            connectionLabel.text = ""
            connectButton.tintColor = .systemBlue
            status = "Not Connected"
            connectButton.setTitle("Connect", for: .normal)
        }
        
        statusLabel.text = status
    }
}

extension String {

    var length: Int {
        return count
    }

    subscript (i: Int) -> String {
        return self[i ..< i + 1]
    }

    func substring(fromIndex: Int) -> String {
        return self[min(fromIndex, length) ..< length]
    }

    func substring(toIndex: Int) -> String {
        return self[0 ..< max(0, toIndex)]
    }

    subscript (r: Range<Int>) -> String {
        let range = Range(uncheckedBounds: (lower: max(0, min(length, r.lowerBound)),
                                            upper: min(length, max(0, r.upperBound))))
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)
        return String(self[start ..< end])
    }
}

