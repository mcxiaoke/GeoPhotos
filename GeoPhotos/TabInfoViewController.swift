//
//  TabInfoViewController.swift
//  ExifViewer
//
//  Created by mcxiaoke on 16/6/1.
//  Copyright © 2016年 mcxiaoke. All rights reserved.
//

import Cocoa

class TabInfoViewController: NSViewController {
  
  override var nibName: String?{
    return "TabInfoViewController"
  }

  var properties: [ImagePropertyItem]? {
    didSet {
      self.tableView?.reloadData()
    }
  }
  
  @IBOutlet weak var tableView:NSTableView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.tableView.setDataSource(self)
    self.tableView.setDelegate(self)
    
    if properties != nil {
      self.tableView.reloadData()
    }
  }
  
}

extension TabInfoViewController: NSTableViewDataSource {
  
  func numberOfRowsInTableView(tableView: NSTableView) -> Int {
    return self.properties?.count ?? 0
  }
  
}

extension TabInfoViewController: NSTableViewDelegate {
  
  
  func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
    guard let item = self.properties?[row] else { return nil }
    var cellIdentifier = ""
    var stringValue = ""
    if tableView.tableColumnWithIdentifier("KeyCell") == tableColumn {
      cellIdentifier = "KeyCell"
      stringValue = item.key2
    }else if tableView.tableColumnWithIdentifier("ValueCell") == tableColumn {
      cellIdentifier = "ValueCell"
      stringValue = item.textValue
    }
    guard let cell = tableView.makeViewWithIdentifier(cellIdentifier, owner: nil)
      as? NSTableCellView else { return nil }
    cell.textField?.stringValue = stringValue
    return cell
  }
  
}
