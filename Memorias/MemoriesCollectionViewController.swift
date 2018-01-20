//
//  MemoriesCollectionViewController.swift
//  Memorias
//
//  Created by Luis Conde on 18/01/18.
//  Copyright © 2018 Luis Conde. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import Speech

private let reuseIdentifier = "cell"

class MemoriesCollectionViewController: UICollectionViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var memories: [URL] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        
        self.loadMemories()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.addImagePressed))

        // Register cell classes
        //self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.checkForGrantedPermissions()
    }
    
    func checkForGrantedPermissions(){
        
        
        let photosAuth: Bool = PHPhotoLibrary.authorizationStatus() == .authorized
        let recordingAuth: Bool = AVAudioSession.sharedInstance().recordPermission() == .granted
        let transcriptionAuth: Bool = SFSpeechRecognizer.authorizationStatus() == .authorized
        
        let authorized = photosAuth && recordingAuth && transcriptionAuth
        
        if !authorized {
            
            if let vc = storyboard?.instantiateViewController(withIdentifier: "ShowTerms") {
                
                navigationController?.present(vc, animated: true)
                
            }
            
        }
        
    }
   
    
    //MARK: - Mis funciones
    
    func loadMemories() {
    
    
        self.memories.removeAll()

        guard let files = try? FileManager.default.contentsOfDirectory(at: getDocumentsDirectory(), includingPropertiesForKeys: nil, options: []) else {
        
            return
        
        }
        
        
        for file in files {
        
            let fileName = file.lastPathComponent
            
            if fileName.hasSuffix(".thumb"){
                
                print(fileName)
            
                let noExtension = fileName.replacingOccurrences(of: ".thumb", with: "")
                
                if let memoryPath =  try? getDocumentsDirectory().appendingPathComponent(noExtension) {
                    
                    memories.append(memoryPath)
                
                }
            
            }
            
            
        }
        
    
    
    }
    
    
    func getDocumentsDirectory() -> URL {
    
    
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        
        let documentsDirectory = paths[0]
        
        return documentsDirectory
        
        
    }
    
    
    func addImagePressed(){
     
        let vc = UIImagePickerController()
        vc.modalPresentationStyle = .formSheet
        vc.delegate = self
        
        navigationController?.present(vc, animated: true, completion: nil)
        
        
    }
    
    
    
    //MARK: - UIImagePickerControllerDelegate
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let theImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
            self.addNewImage(image: theImage)
            self.loadMemories()
            
            dismiss(animated: true)
            
        }else{
            print("Algo salió mal en picker controller")
        }
    }
    
    
    
    func addNewImage(image: UIImage) {
    
        let memoryName = "memory-\(Date().timeIntervalSince1970)"
        
        let imageName = "\(memoryName).jpg"
        let thumbName = "\(memoryName).thumb"
        
        do {
        
            let imagePath = getDocumentsDirectory().appendingPathComponent(imageName)
            
            if let jpegData =  UIImageJPEGRepresentation(image, 80) {
            
                try jpegData.write(to: imagePath, options: [.atomicWrite])
                
            }
            
            
            if let thumbnail = resizeImage(image: image, to: 200) {
            
                let thumbPath = try getDocumentsDirectory().appendingPathComponent(thumbName)
                
                if let jpegData = UIImageJPEGRepresentation(thumbnail, 80) {
                
                    try jpegData.write(to: thumbPath, options: [.atomicWrite])
                    
                }
                
            }
            
            
        }catch{
        
            print("Ha fallado la escritura en disco")
            
        }
        
    }
    
    
    func resizeImage(image: UIImage, to width: CGFloat) -> UIImage? {
    
        let scaleFactor = width/image.size.width
        let height = image.size.height * scaleFactor
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, 0)
        image.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    
    func imageURL(for memory: URL) -> URL {
    
        return  memory.appendingPathExtension("jpg")
        
    }
    
    func thumbnailURL(for memory: URL) -> URL {
        
        return  memory.appendingPathExtension("thumb")
        
    }
    
    func audioURL(for memory: URL) -> URL {
        
        return  memory.appendingPathExtension("m4a")
        
    }
    
    func transcriptionURL(for memory: URL) -> URL {
        
        return  memory.appendingPathExtension("txt")
        
    }
    
    

   


    // MARK: - UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if section==0 {
            return 0
        }else{
            return self.memories.count
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! MemoryCell
        
        let memory = self.memories[indexPath.row]
        
        let memoryName = self.thumbnailURL(for: memory).path
        
        let image = UIImage(contentsOfFile: memoryName)
        
        cell.imageView.image = image
    
        return cell
    }

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}
