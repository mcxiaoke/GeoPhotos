//
//  ImageItem.swift
//  GeoPhotos
//
//  Created by mcxiaoke on 16/6/7.
//  Copyright © 2016年 mcxiaoke. All rights reserved.
//

import Foundation

class ImageItem:NSObject {
  let url:URL
  let type:String
  let name:String
  let size:UInt64
  let dimension:NSSize
  let createdAt:Date
  
  var modifiedAt: Date
  var mimeType: String?
  var latitude:Double?
  var longitude:Double?
  var altitude:Double?
  var timestamp:Date?
  var exifDate:Date?
  
  var modified = false
  var backuped = false
  
  init(url:URL, type:String, name:String,
       size:UInt64, dimension:NSSize,
       createdAt:Date, modifiedAt:Date){
    self.url = url
    self.type = type
    self.name = name
    self.size = size
    self.dimension = dimension
    self.createdAt = createdAt
    self.modifiedAt = modifiedAt
  }
  
  override var description: String{
    return "ImageItem(name=\(name), latitude=\(latitude), longitude=\(longitude), timestamp=\(timestamp))"
  }
  
  func updateProperties(_ properties:NSDictionary) -> Bool {
    if let exif = properties[kCGImagePropertyExifDictionary as String] as! NSDictionary!{
      if let exifDateStr = exif[kCGImagePropertyExifDateTimeDigitized as String] as? String {
        self.exifDate = DateFormatter.date(from: exifDateStr)
      }
    }
    // gps properties
    if let gps = properties[kCGImagePropertyGPSDictionary as String]  as! NSDictionary!{
      let latitudeRef = gps[kCGImagePropertyGPSLatitudeRef as String] as! String
      let latitude = gps[kCGImagePropertyGPSLatitude as String] as? Double
      let longitudeRef = gps[kCGImagePropertyGPSLongitudeRef as String] as! String
      let longitude = gps[kCGImagePropertyGPSLongitude as String] as? Double
      let altitude = gps[kCGImagePropertyGPSAltitude as String] as? Double
      let dateStr = gps[kCGImagePropertyGPSDateStamp as String] as? String
      let timeStr = gps[kCGImagePropertyGPSTimeStamp as String] as? String
      self.latitude = latitudeRef == "N" ? latitude! : -latitude!
      self.longitude = longitudeRef == "E" ? longitude! : -longitude!
      self.altitude = altitude
      if let dateStr = dateStr, let timeStr = timeStr {
        let timestamp = DateFormatter.date(from: "\(dateStr) \(timeStr)")
        self.timestamp = timestamp
      }
      return true
    }
    return false
  }
  
  func updateProperties() -> Bool {
    guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil)
      else { return false }
    guard let propertiesValue = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil)
      else { return false }
    guard let properties = propertiesValue as? NSDictionary else { return false }
    return updateProperties(properties)
  }
  
}
