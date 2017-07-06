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
    self.tableView.dataSource = self
    self.tableView.delegate = self
    
    if properties != nil {
      self.tableView.reloadData()
    }
  }
  
}

extension TabInfoViewController: NSTableViewDataSource {
  
  func numberOfRows(in tableView: NSTableView) -> Int {
    return self.properties?.count ?? 0
  }
  
}

extension TabInfoViewController: NSTableViewDelegate {
  
  
  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    guard let item = self.properties?[row] else { return nil }
    var cellIdentifier = ""
    var stringValue = ""
    if tableView.tableColumn(withIdentifier: "KeyCell") == tableColumn {
      cellIdentifier = "KeyCell"
      stringValue = item.key2
    }else if tableView.tableColumn(withIdentifier: "ValueCell") == tableColumn {
      cellIdentifier = "ValueCell"
      stringValue = item.textValue
    }
    guard let cell = tableView.make(withIdentifier: cellIdentifier, owner: nil)
      as? NSTableCellView else { return nil }
    cell.textField?.stringValue = stringValue
    return cell
  }
  
}
