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

import CoreSpotlight
import MobileCoreServices

private let reuseIdentifier = "cell"

class MemoriesCollectionViewController: UICollectionViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, AVAudioRecorderDelegate, UISearchBarDelegate {
    
    var memories: [URL] = []
    var filteredMemories: [URL] = []
    
    var currentMemory: URL!
    
    var audioPlayer: AVAudioPlayer?
    var audioRecorder: AVAudioRecorder?
    
    var recordingURL: URL!
    
    var searchQuery: CSSearchQuery?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        self.loadMemories()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.addImagePressed))

        self.recordingURL =  getDocumentsDirectory().appendingPathComponent("memory-recording.m4a")

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
    
    
    func showAlert(title: String) {
        
        let alert = UIAlertController(title: title, message: "", preferredStyle: .actionSheet)
        
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        
        alert.addAction(action)
        
        self.present(alert, animated: true, completion: nil)
        
    }
    
    
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
        filteredMemories = memories
        collectionView?.reloadSections(IndexSet(integer:1))
    
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
            
                let thumbPath =  getDocumentsDirectory().appendingPathComponent(thumbName)
                
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
    
    
    //MARK: - UISearchBar
    
    
    func filterMemories(text: String){
        
        guard text.characters.count>0 else {
            self.filteredMemories = self.memories
            collectionView?.reloadSections(IndexSet(integer:1))
            return
        }
        
        var allItems: [CSSearchableItem] = []
        
        searchQuery?.cancel()
        
        let queryString = "contentDescription == \"*\(text)*\"c"
        
        self.searchQuery = CSSearchQuery(queryString: queryString, attributes: nil)
        
        self.searchQuery?.foundItemsHandler = { items in
            
            allItems.append(contentsOf: items)
            
        }
        
        self.searchQuery?.completionHandler = { error in
            
            DispatchQueue.main.async { [unowned self] in
                
                self.activateFilters(matches: allItems)
                
            }
            
        }
        
        self.searchQuery?.start()
        
    }
    
    
    func activateFilters(matches: [CSSearchableItem]){
        
        self.filteredMemories = matches.map({ item in
            
            let uniqueID = item.uniqueIdentifier
            let url = URL(fileURLWithPath: uniqueID)
            return url
        })
        
        collectionView?.reloadSections(IndexSet(integer: 1))
        
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        self.filterMemories(text: searchText)
        
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        
        searchBar.resignFirstResponder()
        
    }
    
    
    func indexMemory(memory: URL, text: String){
    
        let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeText as String)
        
        attributeSet.title = "Recuerdo de Memorias"
        attributeSet.contentDescription = text
        attributeSet.thumbnailURL = thumbnailURL(for: memory)
        
        let item = CSSearchableItem(uniqueIdentifier: memory.path, domainIdentifier: "com.lcondeer", attributeSet: attributeSet)
        
        
        item.expirationDate = Date.distantFuture
        
        CSSearchableIndex.default().indexSearchableItems([item]) { (error) in
            
            if let error=error {
                print("Ha habido un error \(error)")
            }else{
                print("Hemos podido indexar el texto \(text)")
            }
            
        }
    
    }

   


    // MARK: - UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if section==0 {
            return 0
        }else{
            //return self.memories.count
            return self.filteredMemories.count
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! MemoryCell
        
        //let memory = self.memories[indexPath.row]
        let memory = self.filteredMemories[indexPath.row]
        
        let memoryName = self.thumbnailURL(for: memory).path
        
        let image = UIImage(contentsOfFile: memoryName)
        
        cell.imageView.image = image
        
        
        if cell.gestureRecognizers == nil {
            
            let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.memoryLongPressed))
            
            recognizer.minimumPressDuration = 0.3
            
            cell.addGestureRecognizer(recognizer)
            
        }
    
        return cell
    }
    
    
    func memoryLongPressed(sender: UILongPressGestureRecognizer){
        
        if sender.state == .began {
            
            let cell = sender.view as! MemoryCell
            
            if let index = collectionView?.indexPath(for: cell){
            
                //self.currentMemory = self.memories[index.row]
                self.currentMemory = self.filteredMemories[index.row]
                
                self.startRecordingMemory()
                
            }
            
            
        }
        
        if sender.state == .ended {
            
            self.finishRecordingMemory(success: true)
            
        }
        
    }
    
    
    func startRecordingMemory() {
        
        audioPlayer?.stop()
        
        collectionView?.backgroundColor = UIColor.red
        
        let recordingSession = AVAudioSession.sharedInstance()
        
        do {
            
            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord, with: .defaultToSpeaker)
            try recordingSession.setActive(true)
            
            let recordingSettings = [ AVFormatIDKey             : Int(kAudioFormatMPEG4AAC),
                                      AVSampleRateKey           : 44100,
                                      AVNumberOfChannelsKey     : 2,
                                      AVEncoderAudioQualityKey  : AVAudioQuality.high.rawValue
                                    ]
            
            
            audioRecorder = try AVAudioRecorder(url: recordingURL, settings: recordingSettings)
            
            audioRecorder?.delegate = self
            
            audioRecorder?.record()
            
            
        } catch let error{
            print(error)
            self.finishRecordingMemory(success: false)
        }
    }
    
    
    func finishRecordingMemory(success: Bool){
        
        collectionView?.backgroundColor = UIColor(red: 226/255, green: 1, blue: 1, alpha: 1.0)
        
        audioRecorder?.stop()
        
        
        
        if success {
            
            do {
                
                let memoryAudioUrl =  self.currentMemory.appendingPathExtension("m4a")
                
                let fileManager = FileManager.default
                
                if fileManager.fileExists(atPath: memoryAudioUrl.path) {
                    try fileManager.removeItem(at: memoryAudioUrl)
                }
                
                try fileManager.moveItem(at: recordingURL, to: memoryAudioUrl)
                
                self.transcribeAudioToText(memory: self.currentMemory)
                
            } catch let error {
                print("Ha habido un error finishRecordingMemory \(error)")
            }
            
        }else{
            print("No se ha podido completar con éxito la grabación")
        }
    }
    
    
    func transcribeAudioToText(memory: URL){
        
        let audio = audioURL(for: memory)
        
        let transcription = transcriptionURL(for: memory)
        
        let recognizer = SFSpeechRecognizer()
        let request = SFSpeechURLRecognitionRequest(url: audio)
        
        recognizer?.recognitionTask(with: request, resultHandler: { [unowned self] (result, error) in
            
            guard let result = result else {
                print("Ha habido un error transcribeAudioToText \(error)")
                return
            }
            
            if result.isFinal {
            
                let text = result.bestTranscription.formattedString
                
                do {
                    
                    try text.write(to: transcription, atomically: true, encoding: String.Encoding.utf8)
                    self.indexMemory(memory: memory, text: text)
                    
                }catch{
                    print("Ha habido un error")
                }
            }
            
        })
        
    }


    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "header", for: indexPath)
        
        return header
        
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        if section==0 {
            return CGSize(width: 0, height: 50)
        }else{
            return CGSize.zero
        }
        
    }
    

    // MARK: UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        //let memory = self.memories[indexPath.row]
        let memory = self.filteredMemories[indexPath.row]
        
        let fileManager = FileManager.default
        
        do {
            let audioName = audioURL(for: memory)
            
            let transcriptionName = transcriptionURL(for: memory)
            
            if fileManager.fileExists(atPath: audioName.path) {
            
                self.audioPlayer = try AVAudioPlayer(contentsOf: audioName)
                self.audioPlayer?.play()
            
            }
            
            
            if fileManager.fileExists(atPath: transcriptionName.path){
            
                let contents = try String(contentsOf: transcriptionName)
                self.showAlert(title: contents)
                
            }
            
        }catch{
            print("Error al cargar el audio")
        }
        
    }

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
