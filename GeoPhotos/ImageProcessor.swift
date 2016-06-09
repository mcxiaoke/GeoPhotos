//
//  ImageProcessor.swift
//  GeoPhotos
//
//  Created by mcxiaoke on 16/6/9.
//  Copyright © 2016年 mcxiaoke. All rights reserved.
//

import Cocoa
import CoreLocation

class ImageProcessor {
  
  let sizeFormatter = NSByteCountFormatter()
  let imageDirectionRef = "T"
  let imageDirection = 0
  let altitudeRef = 0
  
  var rootURL:NSURL?
  var images:[ImageItem]?
  var timestamp:NSDate?
  var coordinate:CLLocationCoordinate2D?
  var altitude: Double?
  
  func saveWithCompletionHandler(handler: (Int) -> Void){
    guard self.rootURL != nil else { handler(-1); return  }
    guard let coordinate = self.coordinate else { handler(-1); return }
    guard let images = self.images else { handler(-1); return }
    let properties:[String:AnyObject] = [
      kCGImagePropertyGPSSpeed as String : 0,
      kCGImagePropertyGPSSpeedRef as String : "K",
      kCGImagePropertyGPSAltitude as String : 0.0,
      kCGImagePropertyGPSAltitudeRef as String : 0,
      kCGImagePropertyGPSImgDirection as String : 0.0,
      kCGImagePropertyGPSImgDirectionRef as String : "T",
      kCGImagePropertyGPSLatitude as String : coordinate.latitude,
      kCGImagePropertyGPSLatitudeRef as String : coordinate.latitude > 0 ? "E" : "W",
      kCGImagePropertyGPSLongitude as String : coordinate.longitude,
      kCGImagePropertyGPSLongitudeRef as String : coordinate.longitude > 0 ? "N" : "S",
    ]
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
      var saveCount = 0
      images.forEach({ (image) in
        print("process \(image.url)")
        let date = self.timestamp ?? image.createdAt
        var gpsProperties = properties
        let dateStr = DateFormatter.stringFromDate(date)
        let dateTime = dateStr.componentsSeparatedByString(" ")
        gpsProperties[kCGImagePropertyGPSDateStamp as String] = dateTime[0]
        gpsProperties[kCGImagePropertyGPSTimeStamp as String] = dateTime[1]
        guard let imageSource = CGImageSourceCreateWithURL(image.url, nil) else { return }
        let imageType = CGImageSourceGetType(imageSource)!
//        let imageType = image.mimeType ?? ""
        let data = NSMutableData()
        guard let imageDestination = CGImageDestinationCreateWithData(data, imageType, 1, nil) else { return }
        let metaData = [kCGImagePropertyGPSDictionary as String : gpsProperties]
        CGImageDestinationAddImageFromSource(imageDestination, imageSource, 0, metaData)
        CGImageDestinationFinalize(imageDestination)
        if let _ = try? data.writeToURL(image.url, options: NSDataWritingOptions.AtomicWrite) {
          print("save image \(image.url)")
          saveCount += 1
          image.updateGPSInfo()
        }
      })
      dispatch_async(dispatch_get_main_queue()){
        handler(saveCount)
      }
    }
  }
  
  func openWithCompletionHandler(handler: (success:Bool) -> Void){
    showOpenPanel(handler)
  }
  
  private func showOpenPanel(handler: (Bool) -> Void){
    let panel = NSOpenPanel()
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = true
    panel.canCreateDirectories = false
    panel.canChooseFiles = false
    panel.beginWithCompletionHandler { (result) in
      guard result == NSFileHandlingPanelOKButton else {
        handler(false)
        return
      }
      guard let rootURL = panel.URL else {
        handler(false)
        return
      }
      self.loadImage(rootURL, handler: handler)
    }
  }
  
  func loadImage(url:NSURL, handler: (Bool) -> Void){
    print("loadImage: \(url)")
    self.rootURL = url
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
      guard let urls = ExifUtils.parseFiles(url) else { return }
      let images = ExifUtils.parseURLs(urls)
      dispatch_async(dispatch_get_main_queue()){
        self.images = images
        handler(true)
      }
    }
  }
  

}
