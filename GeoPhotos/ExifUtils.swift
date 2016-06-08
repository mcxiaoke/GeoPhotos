//
//  ExifUtils.swift
//  GeoPhotos
//
//  Created by mcxiaoke on 16/6/7.
//  Copyright © 2016年 mcxiaoke. All rights reserved.
//

import Foundation

class ExifUtils {
  
  
  private static var dateFormatter:NSDateFormatter {
    let formatter =  NSDateFormatter()
    formatter.locale = NSLocale(localeIdentifier:"en_US")
    formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
    return formatter
  }
  
  class func diagnose(reason:String) -> Bool {
    print("guard return at \(#line) for \(reason)")
    return true
  }
  
  class func parseFiles(url:NSURL) -> [NSURL]? {
    let fm = NSFileManager.defaultManager()
    var fileUrls:[NSURL]?
    do {
      let directoryContents = try
        fm.contentsOfDirectoryAtURL(url,includingPropertiesForKeys: nil, options: [.SkipsHiddenFiles, .SkipsSubdirectoryDescendants])
      fileUrls = directoryContents.filter({ (url) -> Bool in
        return url.isTypeRegularFile() && ImageExtensions.contains(url.pathExtension?.lowercaseString ?? "")
      })
    } catch let error as NSError {
      print(error.localizedDescription)
    }
    return fileUrls
  }
  
  class func parseURLs(urls:[NSURL]) -> [ImageItem]{
    var images:[ImageItem] = []
    urls.forEach { (url) in
      if let image = parseURL(url) {
        print(image)
        images.append(image)
      }
    }
    return images
  }
  
  class func parseProperties(url:NSURL) {
    guard let imageSource = CGImageSourceCreateWithURL(url, nil) else { return }
    let value = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil)
    let a = value as? Dictionary<String,AnyObject>
    let b = value as? Dictionary<NSError,AnyObject>
    let c = value as? Dictionary<NSObject,AnyObject>
    print("a=\(a) b=\(b) c=\(c)")
  }

  class func parseURL(url:NSURL) -> ImageItem? {
    guard let path = url.path else { return nil }
    guard let name = url.lastPathComponent else { return nil }
    guard let attrs = try? NSFileManager.defaultManager().attributesOfItemAtPath(path) else { return nil }
    // file attrs
    guard let type = attrs[NSFileType] as? String else { return nil }
    guard let sizeNumber = attrs[NSFileSize] as? NSNumber else { return nil }
    let size = sizeNumber.unsignedLongLongValue
    guard let createdAt = attrs[NSFileCreationDate] as? NSDate else { return nil }
    guard let modifiedAt = attrs[NSFileModificationDate] as? NSDate else { return nil }
    // image properties
    guard let imageSource = CGImageSourceCreateWithURL(url, nil) else { return nil }
    guard let propertiesValue = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) else { return nil }
    guard let properties = propertiesValue as? NSDictionary else { return nil }
    guard let width = properties[kCGImagePropertyPixelWidth as String] as? Int else { return nil }
    guard let height = properties[kCGImagePropertyPixelHeight as String] as? Int else { return nil }
    let dimension = NSSize(width:width,height: height)
    
    let item = ImageItem(url: url,
                         type: type,
                         name: name,
                         size: size,
                         dimension: dimension,
                         createdAt: createdAt,
                         modifiedAt: modifiedAt)
    
    // gps properties
    if let gps = properties[kCGImagePropertyGPSDictionary as String] {
      let latitude = gps[kCGImagePropertyGPSLatitude as String] as? Double
      let longitude = gps[kCGImagePropertyGPSLongitude as String] as? Double
      let altitude = gps[kCGImagePropertyGPSAltitude as String] as? Double
      let dateStr = gps[kCGImagePropertyGPSDateStamp as String] as? String
      let timeStr = gps[kCGImagePropertyGPSTimeStamp as String] as? String
      let timestamp = dateFormatter.dateFromString("\(dateStr!) \(timeStr!)")
      item.latitude = latitude
      item.longitude = longitude
      item.altitude = altitude
      item.timestamp = timestamp
    }
    return item
    
  }

  
}