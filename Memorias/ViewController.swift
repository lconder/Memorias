//
//  ViewController.swift
//  Memorias
//
//  Created by Luis Conde on 18/01/18.
//  Copyright © 2018 Luis Conde. All rights reserved.
//

import UIKit
import Photos
import AVFoundation
import Speech

class ViewController: UIViewController {
    
    @IBOutlet var infoLabel: UILabel!
    

    override func viewDidLoad() {
        super.viewDidLoad()
    
    }
    
    
    @IBAction func askForPermissions(_ sender: UIButton) {
        self.askForPhotoPermissions()
    }
    
    
    func askForPhotoPermissions(){
        
        PHPhotoLibrary.requestAuthorization { [unowned self] (authStatus) in
            
            DispatchQueue.main.async {
                
                if authStatus == .authorized {
                    self.askForRecordPermissions()
                }else{
                    self.infoLabel.text = "Nos has denegado el permiso de Fotos, por favor actívalo en los ajustes de tu dispositivo"
                }
                
            }
            
        }
        
    }
    
    func askForRecordPermissions(){
        
        AVAudioSession.sharedInstance().requestRecordPermission { [unowned self] (allowed) in
            
            DispatchQueue.main.async {
                
                if allowed {
                    self.askForTranscriptionPermissions()
                }else{
                    self.infoLabel.text = "Nos has denegado el permiso de Grabación, por favor actívalo en los ajustes de tu dispositivo"
                }
                
            }
            
        }
        
    }
    
    func askForTranscriptionPermissions(){
        
        SFSpeechRecognizer.requestAuthorization { [unowned self] (authStatus) in
            
            DispatchQueue.main.async {
                
                if authStatus == .authorized {
                
                    self.authorizationComplete()
                    
                }else{
                    
                     self.infoLabel.text = "Nos has denegado el permiso de Transcripción, por favor actívalo en los ajustes de tu dispositivo"
                    
                }
                
            }
            
        }
        
    }
    
    
    func authorizationComplete() {
        dismiss(animated: true)
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }


}

