//
//  Kaleidoscope.swift
//  KaleidO'Scope
//
//  Created by Charles Prutting on 1/15/23.
//

//import Foundation
import AVFoundation
import CoreImage.CIFilterBuiltins

class Kaleidoscope {
    var videoURL: NSURL?
    var playerItem = AVPlayerItem(url: URL(fileURLWithPath: Bundle.main.path(forResource: "WOW" , ofType: "MOV")!))
    var queuePlayer: AVQueuePlayer?
    var playerLayer: AVPlayerLayer?
    var playbackLooper: AVPlayerLooper?
    var asset: AVAsset!
    var height: CGFloat!
    var width: CGFloat!
    var bounds: CGRect!
    let kaleidoscope = CIFilter.kaleidoscope()
    var composition: AVVideoComposition!
    var count = 10
    var export: AVAssetExportSession?
    var timer = Timer()
    

    func createKaleidoscope() {
        
        //set kaleidoscope filter center depending on dimensions of video. Fallback center point is for video displayed on launch
        if width != nil {
            kaleidoscope.center = CGPoint(x: width/2, y: height/2)
//            if width > height {
//                kaleidoscope.center = CGPoint(x: height/2, y: width/2)
//            }else{
//                kaleidoscope.center = CGPoint(x: width/2, y: height/2)
//            }
        }else{
            kaleidoscope.center = CGPoint(x: 360.0, y: 640.0)
        }
        
        //create player and looper
        queuePlayer = AVQueuePlayer(playerItem: playerItem)
        playerLayer = AVPlayerLayer(player: queuePlayer)
        guard let playerLayer = playerLayer else {return}
        guard let queuePlayer = queuePlayer else {return}
        playbackLooper = AVPlayerLooper.init(player: queuePlayer, templateItem: playerItem)
        playerLayer.frame = bounds
        playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        //add kaleidoscope filter to each individual video frame
        asset = queuePlayer.currentItem!.asset
        composition = AVVideoComposition(asset: asset,  applyingCIFiltersWithHandler: { [self] request in
            let source = request.sourceImage.clampedToExtent()
            kaleidoscope.count = count
            kaleidoscope.angle = 180
            kaleidoscope.inputImage = source

            let output = kaleidoscope.outputImage!.cropped(to: request.sourceImage.extent)
            request.finish(with: output, context: nil)
        })
        
        //set volume to zero and begin playback
        queuePlayer.currentItem!.videoComposition = composition
        queuePlayer.volume = 0
        queuePlayer.play()
    }
    
}
