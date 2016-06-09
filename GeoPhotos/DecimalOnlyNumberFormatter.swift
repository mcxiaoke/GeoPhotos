//
//  DecimalOnlyNumberFormatter.swift
//  GeoPhotos
//
//  Created by mcxiaoke on 16/6/9.
//  Copyright © 2016年 mcxiaoke. All rights reserved.
//

import Cocoa


class DecimalOnlyNumberFormatter: NSNumberFormatter {
  
  let latitudeRange  = -180.0...180.0
  let longitudeRange = -90.0...90.0
  
  override func awakeFromNib() {
    super.awakeFromNib()
    self.setUp()
  }
  
  private func setUp(){
    self.allowsFloats = true
    self.numberStyle = NSNumberFormatterStyle.DecimalStyle
    self.maximumFractionDigits = 10
  }
  
  override func isPartialStringValid(partialStringPtr: AutoreleasingUnsafeMutablePointer<NSString?>, proposedSelectedRange proposedSelRangePtr: NSRangePointer, originalString origString: String, originalSelectedRange origSelRange: NSRange, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>) -> Bool {
    guard let partialString = partialStringPtr.memory as? String else { return true }
    if partialString.isEmpty { return true }
    if let value = Double(partialString) {
      return true
//      return latitudeRange.contains(value)
    }else {
      return false
    }
  }

}
