//
//  MainViewController.swift
//  GeoPhotos
//
//  Created by mcxiaoke on 16/6/7.
//  Copyright © 2016年 mcxiaoke. All rights reserved.
//

import Cocoa

class MainViewController: NSViewController {
  
  @IBOutlet weak var tableView:NSTableView!
  
  
  var rootURL:NSURL?
  var images:[ImageItem]?

  override var nibName: String?{
    return "MainViewController"
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    print("viewDidLoad")
  }
  
  func openDocument(sender:AnyObject){
    showOpenPanel()
  }
  
  func showOpenPanel(){
    let panel = NSOpenPanel()
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = true
    panel.canCreateDirectories = false
    panel.canChooseFiles = false
    panel.beginWithCompletionHandler { (result) in
      guard result == NSFileHandlingPanelOKButton else { return }
      guard let rootURL = panel.URL else { return }
      self.loadImageItems(rootURL)
    }
  }

  
  func loadImageItems(url:NSURL){
    print("loadImageItems: \(url)")
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
      guard let urls = ExifUtils.parseFiles(url) else { return }
      let images = ExifUtils.parseURLs(urls)
      dispatch_async(dispatch_get_main_queue()){
        self.rootURL = url
        self.images = images
        self.tableView?.reloadData()
      }
    }
  }
    
}

extension MainViewController: NSTableViewDelegate {
  
  func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
    guard let image = self.images?[row] else { return nil }
    var cellIdentifier = ""
    var objectValue:AnyObject?
    if tableColumn == tableView.tableColumnWithIdentifier("NameCell") {
      cellIdentifier = "NameCell"
      objectValue = image.name
    }else if tableColumn == tableView.tableColumnWithIdentifier("LatitudeCell") {
      cellIdentifier = "LatitudeCell"
      objectValue = image.latitude
    }else if tableColumn == tableView.tableColumnWithIdentifier("LongitudeCell") {
      cellIdentifier = "LongitudeCell"
      objectValue = image.longitude
    }else if tableColumn == tableView.tableColumnWithIdentifier("TimestampCell") {
      cellIdentifier = "TimestampCell"
      objectValue = image.timestamp
    }else if tableColumn == tableView.tableColumnWithIdentifier("ModifiedCell") {
      cellIdentifier = "ModifiedCell"
      objectValue = image.modifiedAt
    }else if tableColumn == tableView.tableColumnWithIdentifier("SizeCell") {
      cellIdentifier = "SizeCell"
      objectValue = NSNumber(unsignedLongLong:image.size)
    }
    guard let cell = tableView.makeViewWithIdentifier(cellIdentifier, owner: nil)
      as? NSTableCellView else { return nil }
    cell.textField?.objectValue = objectValue
    return cell
  }
}

extension MainViewController: NSTableViewDataSource {
  func numberOfRowsInTableView(tableView: NSTableView) -> Int {
    return self.images?.count ?? 0
  }
}
