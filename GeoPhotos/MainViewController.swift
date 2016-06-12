//
//  MainViewController.swift
//  GeoPhotos
//
//  Created by mcxiaoke on 16/6/7.
//  Copyright © 2016年 mcxiaoke. All rights reserved.
//

import Cocoa
import CoreLocation
import MapKit

let GPSEditablePropertyDictionary:[String:AnyObject] = [
  kCGImagePropertyGPSLatitude as String: 0.0,
  kCGImagePropertyGPSLongitude as String: 0.0,
  kCGImagePropertyGPSAltitude as String: 0.0,
  kCGImagePropertyGPSTimeStamp as String: "00:00:00",
  kCGImagePropertyGPSDateStamp as String: "2016-06-06",
]

class MapPoint: NSObject,MKAnnotation {
  var coordinate: CLLocationCoordinate2D
  var title: String?
  
  init(coordinate: CLLocationCoordinate2D, title:String?) {
    self.coordinate = coordinate
    self.title = title
    super.init()
  }
}

class MainViewController: NSSplitViewController {
  
  @IBOutlet weak var progressBar:NSProgressIndicator!
  @IBOutlet weak var tableView:NSTableView!
  @IBOutlet weak var textLatitude:NSTextField!
  @IBOutlet weak var textLongitude:NSTextField!
  @IBOutlet weak var textAltitude:NSTextField!
  @IBOutlet weak var datePicker:NSDatePicker!
  @IBOutlet weak var mapView:MKMapView!
  @IBOutlet weak var restoreButton:NSButton!
  @IBOutlet weak var saveButton:NSButton!
  
  let processor = ImageProcessor()
  var annotation:MKAnnotation?

  override var nibName: String?{
    return "MainViewController"
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    updateUI()
    self.tableView.registerForDraggedTypes([NSFilenamesPboardType])
  }
  
  func updateTableViewRows(index:Int){
    let rowIndexes = NSIndexSet(indexesInRange: NSRange(location: max(index - 1, 0), length: 3))
    let count = self.tableView.tableColumns.count
    let columnIndexes = NSIndexSet(indexesInRange: NSRange(location: 0, length: count))
    dispatch_async(dispatch_get_main_queue()){
      self.tableView?.reloadDataForRowIndexes(rowIndexes, columnIndexes: columnIndexes)
      self.tableView.scrollRowToVisible(index)
    }
  }
  
  func updateUI(){
    let hasImages = self.processor.images?.count ?? 0 >= 0
    self.saveButton.enabled = hasImages
      && self.processor.coordinate != nil
      && self.processor.savingIndex == nil
      && self.processor.restoringIndex == nil
    self.restoreButton.enabled = hasImages
      && self.processor.hasBackup
      && self.processor.savingIndex == nil
      && self.processor.restoringIndex == nil
  }
  
  func copy(sender:AnyObject?){
    guard self.tableView.selectedRow >= 0 else { return }
    guard let image = self.processor.images?[self.tableView.selectedRow] else { return }
    let pb = NSPasteboard.generalPasteboard()
    pb.clearContents()
    pb.setString(image.url.path!, forType: NSPasteboardTypeString)
  }
  
  func paste(sender:AnyObject?){
    readFromPasteboard(NSPasteboard.generalPasteboard())
  }
  
  func readFromPasteboard(pb:NSPasteboard) -> Bool{
    let objects = pb.readObjectsForClasses(
      [NSURL.self],options: [NSPasteboardURLReadingFileURLsOnlyKey:true]) as? [NSURL]
    guard let path = objects?.first?.path else { return false }
    let rootURL = NSURL(fileURLWithPath:path)
    self.processor.open(rootURL, completionHandler: { (success) in
      self.tableView?.reloadData()
    })
    return true
  }
  
  override func selectAll(sender: AnyObject?) {
    print("do select all")
  }
  
  func openDocument(sender:AnyObject){
    showOpenPanel()
  }
  
  private func showOpenPanel(){
    let panel = NSOpenPanel()
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = true
    panel.canCreateDirectories = false
    panel.canChooseFiles = false
    panel.beginWithCompletionHandler { (result) in
      guard result == NSFileHandlingPanelOKButton else {
        return
      }
      guard let rootURL = panel.URL else {
        return
      }
//      self.progressBar.hidden = false
      self.processor.open(rootURL, completionHandler: { (success) in
//        self.progressBar.hidden = true
        self.updateUI()
        self.tableView?.reloadData()
      })
    }
  }
  
  @IBAction func doubleClickRow(sender:AnyObject){
    if self.tableView.selectedRow >= 0 {
      guard let image = self.processor.images?[self.tableView.selectedRow] else { return }
      NSWorkspace.sharedWorkspace().selectFile(image.url.path, inFileViewerRootedAtPath: "")
    }
  }
  
  
  @IBAction func revealInFinder(sender:AnyObject){
    let row = self.tableView.rowForView(sender as! NSView)
    if row >= 0 {
      if let image = self.processor.images?[row] {
        NSWorkspace.sharedWorkspace().activateFileViewerSelectingURLs([image.url])
      }
    }
  }
  
  
  @IBAction func openInPreview(sender:AnyObject){
    guard let rowView = sender as? NSView else { return }
    let row = self.tableView.rowForView(rowView)
    if row >= 0 {
      if let image = self.processor.images?[row] {
          let viewController = DetailTabViewController()
          viewController.imageURL = image.url
          self.presentViewController(viewController, asPopoverRelativeToRect: rowView.bounds, ofView: rowView, preferredEdge: NSRectEdge.MaxX, behavior: NSPopoverBehavior.Semitransient)
        
//        let controller = ImagePreviewController()
//        controller.url = image.url
//        let pop = NSPopover()
//        pop.behavior = .Semitransient
//        pop.contentViewController = controller
//        pop.showRelativeToRect(rowView.bounds, ofView: rowView, preferredEdge: NSRectEdge.MaxX)
      }
    }
  }
  
  @IBAction func performRestore(sender:AnyObject){
    print("performRestore")
    restoreProperties()
  }
  
  func restoreProperties(){
    self.processor.restore({ (restoredCount, message) in
      print("restoreProperties \(restoredCount) \(message)")
      self.processor.reopen({ (success) in
        self.updateUI()
        self.tableView?.reloadData()
        self.showRestoreSuccessAlert(restoredCount)
      })
      }) { (image, index, total) in
        self.updateTableViewRows(index)
    }
  }
  
  func showRestoreSuccessAlert(count:Int){
    let alert = NSAlert()
    alert.alertStyle = .InformationalAlertStyle
    alert.messageText = "Images Restored"
    alert.informativeText = "Modified images have been restored using backup files, \(count) files affected."
    alert.addButtonWithTitle("OK")
    alert.beginSheetModalForWindow(self.view.window!) { (response) in
      //
    }
  }
  
  @IBAction func performSave(sender:AnyObject){
    print("performSave")
    guard self.processor.coordinate != nil else {
      showInvalidAlert()
      return
    }
    showSaveAlert(nil)
  }
  
  func showInvalidAlert(){
    let alert = NSAlert()
    alert.alertStyle = .WarningAlertStyle
    alert.messageText = "GPS Properties Invalid"
    alert.informativeText = "GPS coordinate is empty or invalid, please check again."
    alert.addButtonWithTitle("OK")
    alert.beginSheetModalForWindow(self.view.window!) { (response) in
      
    }
  }
  
  func showSaveAlert(sender:AnyObject?){
    let alert = NSAlert()
    alert.alertStyle = .InformationalAlertStyle
    alert.messageText = "Save GPS Properties"
    var contentText = "GPS properties below will be written back to images, Please check:\n"
    if let coordinate = self.processor.coordinate {
      contentText += "Latitude:\(coordinate.latitude)\n"
      contentText += "Longitude:\(coordinate.longitude)\n"
    }
    if let altitude = self.processor.altitude {
      contentText += "Altitude:\(altitude)\n"
    }
    if let timestamp = self.processor.timestamp {
      contentText += "Timestamp:\(DateFormatter.stringFromDate(timestamp))\n"
    }
    alert.informativeText = "\nThese properties will override existing properties, orignal files will be backuped, would you confirm and continue?"
    alert.addButtonWithTitle("OK")
    alert.addButtonWithTitle("Cancel")
    alert.beginSheetModalForWindow(self.view.window!) { (response) in
      if response == NSAlertFirstButtonReturn {
        self.saveProperties()
      }
    }
  }
  
  func showSaveSuccessAlert(count:Int){
    let alert = NSAlert()
    alert.alertStyle = .WarningAlertStyle
    alert.messageText = "GPS Properties Saved"
    alert.informativeText = "GPS properties have been written back to images, \(count) files affected."
    alert.addButtonWithTitle("OK")
    alert.beginSheetModalForWindow(self.view.window!) { (response) in
      //
    }
  }
  
  func saveProperties(){
    updateUI()
    self.processor.altitude = self.textAltitude.doubleValue
    self.processor.save(true,
        completionHandler: { (count, message) in
        print("saveProperties: \(count) \(message)")
        self.updateUI()
        self.tableView?.reloadData()
        self.showSaveSuccessAlert(count)
    },
      processHandler: { (image, index, total) in
        self.updateTableViewRows(index)
    })
  }
  
  @IBAction func textLatitudeChanged(sender: NSTextField) {
    print("textLatitudeChanged")
  }
  
  @IBAction func textLogitudeChanged(sender: NSTextField) {
    print("textLogitudeChanged")
  }
  
  
  @IBAction func textAltitudeChanged(sender: NSTextField) {
    print("textAltitudeChanged")
    self.processor.altitude = sender.doubleValue
  }
  
  
  @IBAction func chooseDate(sender: NSDatePicker) {
    print("chooseDate \(sender.dateValue)")
    self.processor.timestamp = sender.dateValue
  }
  
  func makeAnnotationAt(coordinate: CLLocationCoordinate2D){
    let title = "Lat:\(coordinate.latitude) Lon:\(coordinate.longitude)"
    let newAnnotaion = MapPoint(coordinate: coordinate, title: title)
    self.mapView.addAnnotation(newAnnotaion)
    self.mapView.setCenterCoordinate(coordinate, animated: true)
    if let oldAnnotation = self.annotation {
      self.mapView.removeAnnotation(oldAnnotation)
    }
    self.annotation = newAnnotaion
    self.processor.coordinate = coordinate
    self.textLatitude.stringValue = "\(coordinate.latitude)"
    self.textLongitude.stringValue = "\(coordinate.longitude)"
    updateUI()
//    self.processor.geocodeWithCompletionHandler { (placemark) in
//      let address = placemark?.name ?? ""
////      let annotation = MapPoint(coordinate: self.annotation!.coordinate, title: address)
////      self.mapView.addAnnotation(annotation)
//      self.mapLabel.stringValue = address
//      print("address: \(address)")
//    }
  }
  
//  override func mouseDown(theEvent: NSEvent) {
//    let point = self.view.convertPoint(theEvent.locationInWindow, fromView: nil)
//    let coordinate = self.mapView.convertPoint(point, toCoordinateFromView: self.view)
//    print("mouseDown \(point.x) \(point.y) \(coordinate.latitude) \(coordinate.longitude)")
//  }
  
  override func rightMouseDown(theEvent: NSEvent) {
    // must use self.view, not self.mapView, or not working, don't known why
    let point = self.view.convertPoint(theEvent.locationInWindow, fromView: nil)
    let coordinate = self.mapView.convertPoint(point, toCoordinateFromView: self.view)
//    print("rightMouseDown x=\(point.x) y=\(point.y) \(coordinate.latitude) \(coordinate.longitude)")
    if theEvent.clickCount == 1 {
      makeAnnotationAt(coordinate)
      //      openMapForPlace(coordinate)
    }
  }
  
  func openMapForCoordinate(coordinate: CLLocationCoordinate2D) {
    let distance:CLLocationDistance = 10000
    let regionSpan = MKCoordinateRegionMakeWithDistance(coordinate, distance, distance)
    let options = [
      MKLaunchOptionsMapCenterKey: NSValue(MKCoordinate: regionSpan.center),
      MKLaunchOptionsMapSpanKey: NSValue(MKCoordinateSpan: regionSpan.span)
    ]
    let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: nil)
    let mapItem = MKMapItem(placemark: placemark)
    mapItem.openInMapsWithLaunchOptions(options)
    
  }
    
}

extension MainViewController:MKMapViewDelegate {
  
//  func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
//    guard annotation is MapPoint else { return nil }
//    var annotationView = self.mapView.dequeueReusableAnnotationViewWithIdentifier("Pin")
//    if annotationView == nil {
//      annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "Pin")
//      annotationView?.draggable = true
//      annotationView?.canShowCallout = true
//    }else {
//      annotationView?.annotation = annotation
//    }
//    return annotationView
//  }
  
  func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {
//    print("didUpdateUserLocation \(userLocation.location)")
    //    CLLocationCoordinate2D loc = userLocation.coordinate    //放大地图到自身的经纬度位置。
    //    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(loc, 250, 250);
    //    [self.mapView setRegion:region animated:YES];
//    let coordinate = userLocation.coordinate
//    if !self.mapInitialized {
//      self.mapInitialized = true
//      self.mapView.setCenterCoordinate(coordinate, animated: true)
//      //      let region = MKCoordinateRegionMakeWithDistance(coordinate, 1000, 1000)
//      //      self.mapView.setRegion(region, animated: true)
//    }
  }
  
  func mapView(mapView: MKMapView, didAddAnnotationViews views: [MKAnnotationView]) {
//    print("didAddAnnotationViews \(views.first)")
  }
  
}

extension MainViewController: NSTableViewDelegate {
  
  func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
    guard let image = self.processor.images?[row] else { return nil }
    var cellIdentifier = ""
    var stringValue:String = ""
    if tableColumn == tableView.tableColumnWithIdentifier("NameCell") {
      cellIdentifier = "NameCell"
      stringValue = image.name
    }else if tableColumn == tableView.tableColumnWithIdentifier("LatitudeCell") {
      cellIdentifier = "LatitudeCell"
      if let latitude = image.latitude {
//        stringValue = "\(latitude)"
        stringValue = ExifUtils.formatDegreeValue(latitude,latitude: true)
      }
    }else if tableColumn == tableView.tableColumnWithIdentifier("LongitudeCell") {
      cellIdentifier = "LongitudeCell"
      if let longitude = image.longitude {
//        stringValue = "\(longitude)"
        stringValue = ExifUtils.formatDegreeValue(longitude,latitude: false)
      }
    }else if tableColumn == tableView.tableColumnWithIdentifier("AltitudeCell") {
      cellIdentifier = "AltitudeCell"
      if let altitude = image.altitude {
        stringValue = String(format: "%.2f", altitude)
      }
    }else if tableColumn == tableView.tableColumnWithIdentifier("TimestampCell") {
      cellIdentifier = "TimestampCell"
      if let dateTime = image.timestamp {
        stringValue = DateFormatter.stringFromDate(dateTime)
      }
    }else if tableColumn == tableView.tableColumnWithIdentifier("ModifiedCell") {
      cellIdentifier = "ModifiedCell"
      stringValue = DateFormatter.stringFromDate(image.exifDate ?? image.modifiedAt)
    }else if tableColumn == tableView.tableColumnWithIdentifier("SizeCell") {
      cellIdentifier = "SizeCell"
      stringValue = self.processor.sizeFormatter.stringFromByteCount(Int64(image.size))
    }else if tableColumn == tableView.tableColumnWithIdentifier("ActionCell") {
      cellIdentifier = "ActionCell"
    }
    guard let cell = tableView.makeViewWithIdentifier(cellIdentifier, owner: nil)
      as? NSTableCellView else { return nil }
    if let button = cell.viewWithTag(0) as? NSButton {
      button.target = self
      button.action = #selector(self.revealInFinder(_:))
    }
    if let button = cell.viewWithTag(0) as? NSButton {
      button.target = self
      button.action = #selector(self.revealInFinder(_:))
    }
    if let button = cell.viewWithTag(1) as? NSButton {
      button.target = self
      button.action = #selector(self.openInPreview(_:))
    }
    cell.textField?.stringValue = stringValue
    
    if self.processor.savingIndex == row {
      cell.textField?.textColor = NSColor.blueColor()
    } else if self.processor.restoringIndex == row{
      cell.textField?.textColor = NSColor.redColor()
    }  else {
      cell.textField?.textColor = nil
    }
    return cell
  }
  
  // drag and drop
  // http://stackoverflow.com/questions/4839561/nstableview-drop-app-file-whats-going-wrong
  
  func tableView(tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableViewDropOperation) -> NSDragOperation {
    return NSDragOperation.Copy
  }
  
  func tableView(tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableViewDropOperation) -> Bool {
    print("acceptDrop row=\(row) info=\(info)")
    return readFromPasteboard(info.draggingPasteboard())
  }
}

extension MainViewController: NSTableViewDataSource {
  func numberOfRowsInTableView(tableView: NSTableView) -> Int {
    return self.processor.images?.count ?? 0
  }
}
