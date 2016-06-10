//
//  ExifUtils.swift
//  GeoPhotos
//
//  Created by mcxiaoke on 16/6/7.
//  Copyright © 2016年 mcxiaoke. All rights reserved.
//

import Cocoa
import CoreLocation

class ExifUtils {
  
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
        images.append(image)
      }
    }
    return images
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
    item.mimeType = CGImageSourceGetType(imageSource) as String?
    // gps properties
    if let gps = properties[kCGImagePropertyGPSDictionary as String] {
      let latitude = gps[kCGImagePropertyGPSLatitude as String] as? Double
      let longitude = gps[kCGImagePropertyGPSLongitude as String] as? Double
      let altitude = gps[kCGImagePropertyGPSAltitude as String] as? Double
      let dateStr = gps[kCGImagePropertyGPSDateStamp as String] as? String
      let timeStr = gps[kCGImagePropertyGPSTimeStamp as String] as? String
      item.latitude = latitude
      item.longitude = longitude
      item.altitude = altitude
      if let dateStr = dateStr, let timeStr = timeStr {
        let timestamp = DateFormatter.dateFromString("\(dateStr) \(timeStr)")
        item.timestamp = timestamp
      }
    }
    return item
    
  }
  
  class func formatDegreeValue(degree: Double, latitude:Bool) -> String {
    var seconds = Int(degree * 3600)
    let degrees = seconds / 3600
    seconds = abs(seconds % 3600)
    let minutes = seconds / 60
    seconds %= 60
    let direction:String
    if latitude {
      direction = degrees > 0 ? "N" : "S"
    }else {
      direction = degrees > 0 ? "E" : "W"
    }
    return "\(abs(degrees))°\(minutes)'\(seconds)\" \(direction)"
  }
  
  class func formatCoordinate(coordinate:CLLocationCoordinate2D) -> String {
    var latSeconds = Int(coordinate.latitude * 3600)
    let latDegrees = latSeconds / 3600
    latSeconds = abs(latSeconds % 3600)
    let latMinutes = latSeconds / 60
    latSeconds %= 60
    var longSeconds = Int(coordinate.longitude * 3600)
    let longDegrees = longSeconds / 3600
    longSeconds = abs(longSeconds % 3600)
    let longMinutes = longSeconds / 60
    longSeconds %= 60
    return "\(abs(latDegrees))°\(latMinutes)'\(latSeconds)\"\(latDegrees >= 0 ? "N" : "S") \(abs(longDegrees))°\(longMinutes)'\(longSeconds)\"\(longDegrees >= 0 ? "E" : "W")"
  }

  
}