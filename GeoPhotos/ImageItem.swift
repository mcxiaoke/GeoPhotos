//
//  ImageItem.swift
//  GeoPhotos
//
//  Created by mcxiaoke on 16/6/7.
//  Copyright © 2016年 mcxiaoke. All rights reserved.
//

import Foundation

class ImageItem:NSObject {
  let url:NSURL
  let type:String
  let name:String
  let size:UInt64
  let dimension:NSSize
  let createdAt:NSDate
  
  var modifiedAt: NSDate
  
  var latitude:Double?
  var longitude:Double?
  var altitude:Double?
  var timestamp:NSDate?
  
  init(url:NSURL, type:String, name:String,
       size:UInt64, dimension:NSSize,
       createdAt:NSDate, modifiedAt:NSDate){
    self.url = url
    self.type = type
    self.name = name
    self.size = size
    self.dimension = dimension
    self.createdAt = createdAt
    self.modifiedAt = modifiedAt
  }
  
  override var description: String{
    return "ImageItem(name=\(name), type=\(type), size=\(size), url=\(url))"
  }
  
  
}
