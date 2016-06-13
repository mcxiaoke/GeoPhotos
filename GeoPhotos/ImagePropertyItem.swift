//
//  ImagePropertyItem.swift
//  ExifViewer
//
//  Created by mcxiaoke on 16/5/27.
//  Copyright © 2016年 mcxiaoke. All rights reserved.
//

import Foundation

let imageIOBundle = NSBundle(identifier:"com.apple.ImageIO.framework")

enum PropertyValueType:Int{
  case Number
  case String
  case Array
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
      && [.Number, .String].contains(self.type)
  }
  
  var objectValue:AnyObject {
    switch self.type {
    case .Number:
      return Float(self.textValue) ?? 0
    default:
      return self.textValue
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
      self.type = .Number
    }else if rawValue is NSString {
      self.type = .String
    }else if rawValue is NSArray {
      self.type = .Array
    }else {
      self.type = .String
    }
    super.init()
  }
  
  func validateTextValue(textValuePointer: AutoreleasingUnsafeMutablePointer<String?>,
                     error outError: NSErrorPointer) -> Bool {
    print("validateTextValue \(textValuePointer.memory)")
    if self.type == .String {
      return true
    }
    guard let newValue = textValuePointer.memory else { return true }
    return self.type == .Number && Float(newValue) != nil
  }
  
  class func normalizeKey(rawKey: String, rawCat:String?) -> String {
    let key = getImageIOLocalizedString(rawKey)
    if let prefix = getCategoryPrefix(rawCat) {
      return "\(prefix) \(key)"
    }else {
      return key
    }
  }
  
  class func normalizeValue(value:AnyObject) -> String {
    let valueStr:String
    if let value = value as? NSArray {
      //  + " \(value.dynamicType)"
      valueStr = value.componentsJoinedByString(", ")
    }else {
      valueStr = "\(value)"
    }
    return valueStr
  }
  
  class func getImageIOLocalizedString(key: String) -> String
  {
    return imageIOBundle?.localizedStringForKey(key, value: key, table: "CGImageSource") ?? key
  }
  
  class func getCategoryPrefix(category: String?) -> String? {
    if let category = category {
      if let prefix = ImageCategoryPrefixKeys[category]{
        return "\(prefix) "
      }
    }
    return nil
  }
  
  class func parse(properties: Dictionary<String,AnyObject>, category:String? = nil) -> [ImagePropertyItem]{
    var items:[ImagePropertyItem] = []
    properties.forEach { (key, value) in
      if let child  = value as? Dictionary<String,AnyObject> {
        items += parse(child, category: key)
      }else {
        let newItem = ImagePropertyItem(rawKey: key, rawValue: value, rawCat: category)
        items.append(newItem)
      }
    }
    return items
  }
  
  class func getObjectValue(item:ImagePropertyItem, value:String) -> AnyObject {
    switch item.type {
    case .Number:
      return Float(value) ?? 0
    default:
      return value
    }
  }
}