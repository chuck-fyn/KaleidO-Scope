//
//  ViewController.swift
//  KaleidO'Scope
//
//  Created by Charles Prutting on 10/19/20.
//

//import Foundation
import UIKit
import AVFoundation

class ViewController: UIViewController, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var videoSelectorButton: UIButton!
    @IBOutlet weak var shareProgressBar: UIProgressView!
    
    //create instances of ImagePickerController, Kaleidoscope, and Timer
    var imagePickerController = UIImagePickerController()
    var kaleid = Kaleidoscope()
    var timer = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //configure Kaleidoscope and add observer for didBecomeActive
        configureKaleidoscope()
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    @objc func didBecomeActive() {
        //Resumes kaleidoscope loop when app is re-opened from non-closed state
        kaleid.queuePlayer?.play()
    }
   
    func configureKaleidoscope() {
        //Re-set screen attributes, create Kaleidoscope, add Kaleidoscope to screen
        slider.value = Float(kaleid.count)
        shareProgressBar.isHidden = true
        kaleid.bounds = videoView.bounds
        kaleid.createKaleidoscope()
        videoView.layer.addSublayer(kaleid.playerLayer!)
    }
    
    @IBAction func sliderChangeValue(_ sender: Any) {
        //send slider value to Kaleidoscope opbject
        kaleid.count = Int(slider.value)
    }
    
    @IBAction func videoSelector(_ sender: UIButton) {
        //Set imagepickercontoller attributes and open
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.delegate = self
        imagePickerController.mediaTypes = ["public.movie"]
        imagePickerController.videoQuality = .typeHigh
        imagePickerController.videoExportPreset = AVAssetExportPresetPassthrough
        present(imagePickerController, animated: true, completion: nil)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        //Dismiss ImagePickerController and send video URL and dimensions to Kaleidoscope object
        picker.dismiss(animated: true, completion: nil)
        
        // Pass video URL and dimensions to kaleidoscope
        guard let mediaURL = info[UIImagePickerController.InfoKey.mediaURL] as? URL else { return }
        kaleid.playerItem = AVPlayerItem(url: mediaURL)
        let sizeAsset = AVAsset(url: mediaURL)
        kaleid.height = sizeAsset.tracks(withMediaType: .video)[0].naturalSize.height
        kaleid.width = sizeAsset.tracks(withMediaType: .video)[0].naturalSize.width
                
        // Reset share progress bat and re-create Kaleidoscope
        shareProgressBar.progress = 0.1
        configureKaleidoscope()
    }
    
    @IBAction func shareButtonPressed(_ sender: Any) {
        //Disable all on screen buttons and prepare video export
        shareButton.isEnabled = false
        videoSelectorButton.isEnabled = false
        shareProgressBar.isHidden = false
        shareProgressBar.progress = 0.1
        prepareExport()
    }
    func prepareExport(){
        //set directory path and file name for saved export, then remove any video that was previously occupying the spot
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let savedoutputURL = documentsDirectory.appendingPathComponent("Filterd.mov")
        try? FileManager.default.removeItem(at: savedoutputURL)
            
        //create export session and begin asynchronously
        let export = AVAssetExportSession(asset: kaleid.asset, presetName: AVAssetExportPresetHighestQuality)
        export!.outputFileType = AVFileType.mov
        export!.outputURL = savedoutputURL
        export!.videoComposition = kaleid.composition
        export!.shouldOptimizeForNetworkUse = false
        export?.exportAsynchronously(completionHandler: { [self] in
            if export!.status.rawValue == 4 {
                //If export fails print error
                print("Export failed -> Reason: \(String(describing: export?.error!.localizedDescription)))")
                print(export?.error! as Any)
            } else {
                //If export succeeds, display activityController with the exported video attached
                let activityItems: [Any] = [savedoutputURL]
                let activityController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
                DispatchQueue.main.async {
                    self.present(activityController, animated: true)
                }
            }
            DispatchQueue.main.async {
                //Regardless if export is successful or not, reset screen buttons and export timer when finished
                self.shareButton.isEnabled = true
                self.videoSelectorButton.isEnabled = true
                self.shareProgressBar.progress = 0
                self.shareProgressBar.isHidden = true
                self.timer.invalidate()
                self.timer = Timer()
            }
        })
        //Starts timer for export to update searchProgressBar with export progress
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [self] timer in
            shareProgressBar.progress = export!.progress
        }
    }

}

