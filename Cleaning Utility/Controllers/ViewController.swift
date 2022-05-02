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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("View Loaded")
        
        //init serial
        serial = BluetoothSerial(delegate: self)
        
        //UI
        progressBar.progress = 0;
        
        
    }
    
    //MARK: IBActions
    @IBAction func toggleButtonPressed(_ sender: UIButton) {
        //Starts the cleaning cycle
        
        if(serial.isReady) {
            print("Serial is connected and sending message!")
            serial.sendMessageToDevice("1")
            print("Sent \"1\"")
        } else {
            print("Serial is not connected... cannot send message!")
        }
        
    }
    
    @IBAction func connectButtonToggled(_ sender: UIButton) {
        if serial.isReady != true {
            //Opens the scanner screen
            self.performSegue(withIdentifier: "goToDevices", sender: self)
        } else {
            serial.disconnect()
            reloadUI()
        }
    }
    
    
    //MARK: BluetoothSerialDelegate
    func serialDidChangeState() {
        reloadUI()
        if(serial.centralManager.state != .poweredOn) {
            connectionLabel.text = ""
            statusLabel.text = "Status: Bluetooth turned off"
        }
        
        switch serial.centralManager.state {
        case .unknown:
            print("unknown")
        case .resetting:
            print("resetting")
        case .unsupported:
            print("unsupported")
        case .unauthorized:
            print("unauthorized")
        case .poweredOff:
            print("powered off")
        case .poweredOn:
            print("powered on")
        }
    }
    
    func serialDidDisconnect(_ peripheral: CBPeripheral, error: NSError?) {
        reloadUI()
        connectionLabel.text = ""
        statusLabel.text = "Status: Disconnected"
    }
    
    func serialDidReceiveString(_ message: String) {
        reloadUI()
        print(message)
    }
    
    
    func reloadUI() {
        serial.delegate = self
        
        progressBar.progress = progress
        
        if serial.isReady {
            connectionLabel.text = "Connected To: " + serial.connectedPeripheral!.name!
            connectButton.setTitle("Disconnect", for: .normal)
        } else if serial.centralManager.state == .poweredOn {
            connectionLabel.text = ""
            statusLabel.text = "Not Connected"
            connectButton.setTitle("Connect", for: .normal)
        } else {
            connectionLabel.text = ""
            statusLabel.text = "Not Connected"
            connectButton.setTitle("Connect", for: .normal)
        }
        
        if serial.isReady {
            startCycleButton.tintColor = .systemBlue
        } else {
            startCycleButton.tintColor = .systemGray
        }
    }
}
