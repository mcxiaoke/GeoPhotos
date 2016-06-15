//
//  DecimalOnlyNumberFormatter.swift
//  GeoPhotos
//
//  Created by mcxiaoke on 16/6/9.
//  Copyright © 2016年 mcxiaoke. All rights reserved.
//

import Cocoa


class DecimalOnlyNumberFormatter: NSNumberFormatter {
  
  override func awakeFromNib() {
    super.awakeFromNib()
    self.setUp()
  }
  
  private func setUp(){
    self.allowsFloats = true
    self.numberStyle = NSNumberFormatterStyle.DecimalStyle
    self.maximumFractionDigits = 8
  }
  
  override func isPartialStringValid(partialStringPtr: AutoreleasingUnsafeMutablePointer<NSString?>, proposedSelectedRange proposedSelRangePtr: NSRangePointer, originalString origString: String, originalSelectedRange origSelRange: NSRange, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>) -> Bool {
    guard let partialString = partialStringPtr.memory as? String else { return true }
    return !partialString.isEmpty && Double(partialString) != nil
  }

}
