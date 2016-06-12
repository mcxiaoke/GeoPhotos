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
  let geocoder = CLGeocoder()
  let sizeFormatter = NSByteCountFormatter()
  let imageDirectionRef = "T"
  let imageDirection = 0
  let altitudeRef = 0
  
  var rootURL:NSURL?
  var images:[ImageItem]?
  var timestamp:NSDate?
  var coordinate:CLLocationCoordinate2D?
  var altitude: Double?
  
  func geocodeWithCompletionHandler(handler:(CLPlacemark?) -> Void) {
    guard let coordinate = self.coordinate else { return }
    let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
      handler(placemarks?.first)
    }
  }
  
  func saveWithCompletionHandler(handler: (Int, String) -> Void){
    print("saveWithCompletionHandler timestamp:\(self.timestamp)")
    print("saveWithCompletionHandler altitude:\(self.altitude)")
    print("saveWithCompletionHandler coordinate:\(self.coordinate)")
    guard self.rootURL != nil else { handler(-1, "rootURL is nil"); return  }
    guard let coordinate = self.coordinate else { handler(-1, "coordinate is nil"); return }
    guard let images = self.images else { handler(-1, "No images found"); return }
    let properties:[String:AnyObject] = [
      kCGImagePropertyGPSSpeed as String : 0,
      kCGImagePropertyGPSSpeedRef as String : "K",
      kCGImagePropertyGPSAltitude as String : self.altitude ?? 0.0,
      kCGImagePropertyGPSAltitudeRef as String : 0,
      kCGImagePropertyGPSImgDirection as String : 0.0,
      kCGImagePropertyGPSImgDirectionRef as String : "T",
      kCGImagePropertyGPSLatitude as String : Double.abs(coordinate.latitude),
      kCGImagePropertyGPSLatitudeRef as String : coordinate.latitude > 0 ? "N" : "S",
      kCGImagePropertyGPSLongitude as String : Double.abs(coordinate.longitude),
      kCGImagePropertyGPSLongitudeRef as String : coordinate.longitude > 0 ? "E" : "W",
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
        handler(saveCount, "OK")
      }
    }
  }
  
  func openWithCompletionHandler(url:NSURL, handler: (success:Bool) -> Void){
    self.loadImage(url, handler: handler)
  }
  
  func loadImage(url:NSURL, handler: (Bool) -> Void){
    print("loadImage: \(url)")
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
      guard let urls = ExifUtils.parseFiles(url) else { return }
      let images = ExifUtils.parseURLs(urls).sort{ $0.name < $1.name }
      dispatch_async(dispatch_get_main_queue()){
        self.rootURL = url
        self.images = images
        handler(true)
      }
    }
  }
  

}
