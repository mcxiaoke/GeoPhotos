//
//  NSURL+Extensions.swift
//  GeoPhotos
//
//  Created by mcxiaoke on 16/6/7.
//  Copyright © 2016年 mcxiaoke. All rights reserved.
//

import Foundation

extension URL {
  //  func isDirectory2() -> Bool {
  //    var isDirectory: ObjCBool = false
  //    if let path = self.path {
  //      let success = NSFileManager.defaultManager().fileExistsAtPath(path, isDirectory: &isDirectory)
  //      return success && isDirectory
  //    }
  //    return false
  //  }
  
  func isTypeDirectory() -> Bool {
    do{
      var value: AnyObject?
      try (self as NSURL).getResourceValue(&value, forKey: URLResourceKey.isDirectoryKey)
      if let value = value as? NSNumber {
        return value.boolValue
      }
    }catch{
      
    }
    return false
  }
  
  func isTypeRegularFile() -> Bool {
    do{
      var value: AnyObject?
      try (self as NSURL).getResourceValue(&value, forKey: URLResourceKey.isRegularFileKey)
      if let value = value as? NSNumber {
        return value.boolValue
      }
    }catch{
      
    }
    return false
  }
  
  func isTypeSymbolicLink() -> Bool {
    do{
      var value: AnyObject?
      try (self as NSURL).getResourceValue(&value, forKey: URLResourceKey.isSymbolicLinkKey)
      if let value = value as? NSNumber {
        return value == true
      }
    }catch{
      
    }
    return false
  }
}
