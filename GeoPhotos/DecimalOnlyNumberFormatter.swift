//
//  DecimalOnlyNumberFormatter.swift
//  GeoPhotos
//
//  Created by mcxiaoke on 16/6/9.
//  Copyright © 2016年 mcxiaoke. All rights reserved.
//

import Cocoa


class DecimalOnlyNumberFormatter: NumberFormatter {
  
  override func awakeFromNib() {
    super.awakeFromNib()
    self.setUp()
  }
  
  fileprivate func setUp(){
    self.allowsFloats = true
    self.numberStyle = NumberFormatter.Style.decimal
    self.maximumFractionDigits = 8
  }
    
    override func isPartialStringValid(_ partialStringPtr: AutoreleasingUnsafeMutablePointer<NSString>, proposedSelectedRange proposedSelRangePtr: NSRangePointer?, originalString origString: String, originalSelectedRange origSelRange: NSRange, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
            guard let partialString = partialStringPtr.pointee as? String else { return true }
            return !partialString.isEmpty && Double(partialString) != nil
    }

}
