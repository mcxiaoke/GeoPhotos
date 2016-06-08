//
//  NSDateFormatter+Extensions.swift
//  GeoPhotos
//
//  Created by mcxiaoke on 16/6/8.
//  Copyright © 2016年 mcxiaoke. All rights reserved.
//

import Cocoa

extension NSDateFormatter {
  convenience init(dateFormat: String) {
    self.init()
    self.dateFormat = dateFormat
  }
}
