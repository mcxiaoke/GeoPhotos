//
//  NSURL+Extensions.swift
//  GeoPhotos
//
//  Created by mcxiaoke on 16/6/7.
//  Copyright © 2016年 mcxiaoke. All rights reserved.
//

import Foundation

extension NSURL {
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
      try self.getResourceValue(&value, forKey: NSURLIsDirectoryKey)
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
      try self.getResourceValue(&value, forKey: NSURLIsRegularFileKey)
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
      try self.getResourceValue(&value, forKey: NSURLIsSymbolicLinkKey)
      if let value = value as? NSNumber {
        return value == true
      }
    }catch{
      
    }
    return false
  }
}