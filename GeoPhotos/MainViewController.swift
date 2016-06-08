//
//  MainViewController.swift
//  GeoPhotos
//
//  Created by mcxiaoke on 16/6/7.
//  Copyright © 2016年 mcxiaoke. All rights reserved.
//

import Cocoa

class MainViewController: NSSplitViewController {
  
  @IBOutlet weak var tableView:NSTableView!
  
  let sizeFormatter = NSByteCountFormatter()
  
  var rootURL:NSURL?
  var images:[ImageItem]?

  override var nibName: String?{
    return "MainViewController"
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
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
    var stringValue:String = ""
    if tableColumn == tableView.tableColumnWithIdentifier("NameCell") {
      cellIdentifier = "NameCell"
      stringValue = image.name
    }else if tableColumn == tableView.tableColumnWithIdentifier("LatitudeCell") {
      cellIdentifier = "LatitudeCell"
      if let latitude = image.latitude {
        stringValue = ExifUtils.formatDegreeValue(latitude,latitude: true)
      }
    }else if tableColumn == tableView.tableColumnWithIdentifier("LongitudeCell") {
      cellIdentifier = "LongitudeCell"
      if let longitude = image.longitude {
        stringValue = ExifUtils.formatDegreeValue(longitude,latitude: false)
      }
    }else if tableColumn == tableView.tableColumnWithIdentifier("AltitudeCell") {
      cellIdentifier = "AltitudeCell"
      if let altitude = image.altitude {
        stringValue = String(format: "%.2fM", altitude)
      }
    }else if tableColumn == tableView.tableColumnWithIdentifier("TimestampCell") {
      cellIdentifier = "TimestampCell"
      if let dateTime = image.timestamp {
        stringValue = DateFormatter.stringFromDate(dateTime)
      }
    }else if tableColumn == tableView.tableColumnWithIdentifier("ModifiedCell") {
      cellIdentifier = "ModifiedCell"
      stringValue = DateFormatter.stringFromDate(image.modifiedAt)
    }else if tableColumn == tableView.tableColumnWithIdentifier("SizeCell") {
      cellIdentifier = "SizeCell"
      stringValue = sizeFormatter.stringFromByteCount(Int64(image.size))
    }
    guard let cell = tableView.makeViewWithIdentifier(cellIdentifier, owner: nil)
      as? NSTableCellView else { return nil }
    cell.textField?.stringValue = stringValue
    return cell
  }
}

extension MainViewController: NSTableViewDataSource {
  func numberOfRowsInTableView(tableView: NSTableView) -> Int {
    return self.images?.count ?? 0
  }
}
