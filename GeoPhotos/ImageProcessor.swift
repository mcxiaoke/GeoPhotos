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
  let sizeFormatter = ByteCountFormatter()
  
  var rootURL:URL?
  var images:[ImageItem]?
  var timestamp:Date?
  var coordinate:CLLocationCoordinate2D?
  var altitude: Double?
  var savingIndex:Int?
  var restoringIndex:Int?
  var hasBackup = false
  
  func geocode(_ completionHandler:@escaping (CLPlacemark?) -> Void) {
    guard let coordinate = self.coordinate else { return }
    let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
      print("geo code \(error)")
      completionHandler(placemarks?.first)
    }
  }
  
  func save(_ backupOriginal: Bool, completionHandler: @escaping (Int, String) -> Void, processHandler:((ImageItem, Int, Int) -> Void)? = nil){
    print("save timestamp:\(self.timestamp)")
    print("save altitude:\(self.altitude)")
    print("save coordinate:\(self.coordinate)")
    guard self.rootURL != nil else { completionHandler(-1, "rootURL is nil"); return  }
    guard let coordinate = self.coordinate else { completionHandler(-1, "coordinate is nil"); return }
    guard let images = self.images else { completionHandler(-1, "No images found"); return }
    let properties:[String:AnyObject] = [
      kCGImagePropertyGPSSpeed as String : 0 as AnyObject,
      kCGImagePropertyGPSSpeedRef as String : "K" as AnyObject,
      kCGImagePropertyGPSAltitudeRef as String : 0 as AnyObject,
      kCGImagePropertyGPSImgDirection as String : 0.0 as AnyObject,
      kCGImagePropertyGPSImgDirectionRef as String : "T" as AnyObject,
      kCGImagePropertyGPSLatitude as String : abs(coordinate.latitude) as AnyObject,
      kCGImagePropertyGPSLatitudeRef as String : (coordinate.latitude > 0 ? "N" : "S") as AnyObject,
      kCGImagePropertyGPSLongitude as String : abs(coordinate.longitude) as AnyObject,
      kCGImagePropertyGPSLongitudeRef as String : (coordinate.longitude > 0 ? "E" : "W") as AnyObject,
    ]
    
    DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async {
      let fileManager = FileManager()
      let total = images.count
      var savedCount = 0
      self.savingIndex = nil
      images.enumerated().forEach({ (index, image) in
        print("processing \(image.name) at \(index)")
        self.savingIndex = index
        processHandler?(image, index, total)
        let date = self.timestamp ?? (image.timestamp
          ?? image.exifDate ?? image.createdAt) as Date
        var gpsProperties = properties
        let dateStr = DateFormatter.string(from: date)
        let dateTime = dateStr.components(separatedBy: " ")
        gpsProperties[kCGImagePropertyGPSDateStamp as String] = dateTime[0] as AnyObject
        gpsProperties[kCGImagePropertyGPSTimeStamp as String] = dateTime[1] as AnyObject
        if let altitude = self.altitude {
          gpsProperties[kCGImagePropertyGPSAltitude as String] = altitude as AnyObject
        }
        guard let imageSource = CGImageSourceCreateWithURL(image.url as CFURL, nil) else { return }
        let imageType = CGImageSourceGetType(imageSource)!
//        let imageType = image.mimeType ?? ""
        let data = NSMutableData()
        guard let imageDestination = CGImageDestinationCreateWithData(data, imageType, 1, nil) else { return }
        let metaData = [kCGImagePropertyGPSDictionary as String : gpsProperties]
        CGImageDestinationAddImageFromSource(imageDestination, imageSource, 0, metaData as CFDictionary)
        CGImageDestinationFinalize(imageDestination)
        if backupOriginal {
          let backupURL = image.url.appendingPathExtension("bak")
          let backupName = backupURL.lastPathComponent 
          do{
            try fileManager.replaceItem(at: backupURL, withItemAt: image.url as URL,
              backupItemName: nil, options: .withoutDeletingBackupItem, resultingItemURL: nil)
            image.backuped = true
            print("backup \(backupName)")
          }catch let error as NSError {
              print("backup \(error)")
          }
        }
        if let _ = try? data.write(to: image.url as URL, options: NSData.WritingOptions.atomicWrite) {
          print("processed \(image.name)")
          savedCount += 1
          image.updateProperties()
          image.modified = true
        }
      })
      self.savingIndex = nil
      if backupOriginal {
        self.hasBackup = true
      }
      DispatchQueue.main.async{
        completionHandler(savedCount, "OK")
      }
    }
  }
  
  func restore(_ completionHandler: @escaping (Int, String) -> Void,
               processHandler:((ImageItem, Int, Int) -> Void)? = nil){
    guard self.rootURL != nil else { completionHandler(-1, "ERROR"); return }
    guard let images = self.images else { completionHandler(-1, "ERROR"); return }
    DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async {
      let total = images.count
      let fileManager = FileManager()
      var restoredCount = 0
      self.restoringIndex = nil
      images.enumerated().forEach { (index, image) in
        self.restoringIndex = index
        processHandler?(image, index, total)
        let backupURL = image.url.appendingPathExtension("bak")
        var isDirectory = ObjCBool(false)
        let fileExists = fileManager.fileExists(atPath: backupURL.path, isDirectory: &isDirectory)
        if fileExists && !isDirectory.boolValue {
          do{
            try fileManager.replaceItem(at: image.url as URL, withItemAt: backupURL,
              backupItemName: nil, options: .withoutDeletingBackupItem, resultingItemURL: nil)
            restoredCount += 1
            image.backuped = false
            image.modified = false
            print("restore \(image.name)")
          }catch let error as NSError{
            print("restore \(error)")
          }
        }
      }
      self.restoringIndex = nil
      self.hasBackup = false
      DispatchQueue.main.async{
        completionHandler(restoredCount, "OK")
      }
    }
  }
  
  func reopen(_ completionHandler: @escaping (Bool) -> Void){
    print("reopen: \(self.rootURL)")
    guard let url = self.rootURL else { completionHandler(false); return }
    self.loadImage(url, completionHandler: completionHandler)
  }
  
  func open(_ url:URL, completionHandler: @escaping (Bool) -> Void){
    print("open: \(url)")
    self.loadImage(url, completionHandler: completionHandler)
  }
  
  func loadImage(_ url:URL, completionHandler: @escaping (Bool) -> Void){
    DispatchQueue.global().async {
      guard let urls = ExifUtils.parseFiles(url) else { return }
      let images = ExifUtils.parseURLs(urls).sorted{ $0.name < $1.name }
      DispatchQueue.main.async{
        self.savingIndex = nil
        self.restoringIndex = nil
        self.hasBackup = false
        self.rootURL = url
        self.images = images
        completionHandler(true)
      }
    }
  }
  

}
