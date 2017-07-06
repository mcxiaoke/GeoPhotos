//
//  ImagePropertyItem.swift
//  ExifViewer
//
//  Created by mcxiaoke on 16/5/27.
//  Copyright © 2016年 mcxiaoke. All rights reserved.
//

import Foundation

let imageIOBundle = Bundle(identifier:"com.apple.ImageIO.framework")

enum PropertyValueType:Int{
  case number
  case string
  case array
}

class ImagePropertyItem : NSObject {
  var key:String
  var key2:String
  var textValue:String
  let cat:String?
  let rawKey:String
  let rawValue:AnyObject
  let rawCat:String?
  let type:PropertyValueType
  
  var editable:Bool {
    return AllEditablePropertyKeys.contains(self.rawKey)
      && [.number, .string].contains(self.type)
  }
  
  var objectValue:AnyObject {
    switch self.type {
    case .number:
      return Float(self.textValue) as AnyObject ?? 0 as AnyObject
    default:
      return self.textValue as AnyObject
    }
  }
  
  override var description: String {
    return "(\(rawKey) = \(rawValue) - (\(textValue))  \(rawCat ?? "")) [\(type)]"
  }
  
  init(rawKey:String, rawValue:AnyObject, rawCat:String?){
    self.rawKey = rawKey
    self.rawValue = rawValue
    self.rawCat = rawCat
    self.key = ImagePropertyItem.normalizeKey(rawKey, rawCat: rawCat)
    self.key2 = ImagePropertyItem.getImageIOLocalizedString(rawKey)
    self.textValue = ImagePropertyItem.normalizeValue(rawValue)
    if let rawCat = rawCat {
      self.cat = ImagePropertyItem.getImageIOLocalizedString(rawCat)
    }else{
      self.cat = nil
    }
    if rawValue is NSNumber {
      self.type = .number
    }else if rawValue is NSString {
      self.type = .string
    }else if rawValue is NSArray {
      self.type = .array
    }else {
      self.type = .string
    }
    super.init()
  }
  
  func validateTextValue(_ textValuePointer: AutoreleasingUnsafeMutablePointer<String?>,
                     error outError: NSErrorPointer) -> Bool {
    print("validateTextValue \(textValuePointer.pointee)")
    if self.type == .string {
      return true
    }
    guard let newValue = textValuePointer.pointee else { return true }
    return self.type == .number && Float(newValue) != nil
  }
  
  class func normalizeKey(_ rawKey: String, rawCat:String?) -> String {
    let key = getImageIOLocalizedString(rawKey)
    if let prefix = getCategoryPrefix(rawCat) {
      return "\(prefix) \(key)"
    }else {
      return key
    }
  }
  
  class func normalizeValue(_ value:AnyObject) -> String {
    let valueStr:String
    if let value = value as? NSArray {
      //  + " \(value.dynamicType)"
      valueStr = value.componentsJoined(by: ", ")
    }else {
      valueStr = "\(value)"
    }
    return valueStr
  }
  
  class func getImageIOLocalizedString(_ key: String) -> String
  {
    return imageIOBundle?.localizedString(forKey: key, value: key, table: "CGImageSource") ?? key
  }
  
  class func getCategoryPrefix(_ category: String?) -> String? {
    if let category = category {
      if let prefix = ImageCategoryPrefixKeys[category]{
        return "\(prefix) "
      }
    }
    return nil
  }
  
  class func parse(_ properties: Dictionary<String,AnyObject>, category:String? = nil) -> [ImagePropertyItem]{
    var items:[ImagePropertyItem] = []
    var subItems:[ImagePropertyItem] = []
    properties.forEach { (key, value) in
      if let child  = value as? Dictionary<String,AnyObject> {
        subItems += parse(child, category: key)
      }else {
        let newItem = ImagePropertyItem(rawKey: key, rawValue: value, rawCat: category)
        items.append(newItem)
      }
    }
    return items.sorted { $0.key < $1.key } + subItems.sorted{ $0.key < $1.key }
  }
  
  class func getObjectValue(_ item:ImagePropertyItem, value:String) -> AnyObject {
    switch item.type {
    case .number:
      return Float(value) as AnyObject ?? 0 as AnyObject
    default:
      return value as AnyObject
    }
  }
}
