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

private let kActionCell = "ActionCell"
private let kNameCell = "NameCell"
private let kLatitudeCell = "LatitudeCell"
private let kLongitudeCell = "LongitudeCell"
private let kAltitudeCell = "AltitudeCell"
private let kTimestampCell = "TimestampCell"
private let kModifiedCell = "ModifiedCell"
private let kSizeCell = "SizeCell"

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
  var subtitle: String?
  var image:ImageItem?
  
  init(coordinate: CLLocationCoordinate2D, title:String?, subtitle:String? = nil) {
    self.coordinate = coordinate
    self.title = title
    self.subtitle = subtitle
    super.init()
  }
  
  override var description: String{
    return "Annotation(\(coordinate))"
  }
}

class MainWindowController: NSWindowController {
  
  @IBOutlet weak var view:NSView!
  @IBOutlet weak var splitView:NSSplitView!
  @IBOutlet weak var progressBar:NSProgressIndicator!
  @IBOutlet weak var tableView:NSTableView!
  @IBOutlet weak var textLatitude:NSTextField!
  @IBOutlet weak var textLongitude:NSTextField!
  @IBOutlet weak var textAltitude:NSTextField!
  @IBOutlet weak var datePicker:NSDatePicker!
  @IBOutlet weak var mapView:MKMapView!
  @IBOutlet weak var restoreButton:NSButton!
  @IBOutlet weak var saveButton:NSButton!
  @IBOutlet weak var backupCheckBox:NSButton!
  
  let processor = ImageProcessor()
  var annotation:MKAnnotation?
  var imageAnnotaion:MKAnnotation?

  override var windowNibName: String?{
    return "MainWindowController"
  }
  
  override func windowDidLoad() {
    super.windowDidLoad()
    self.window?.delegate = self
    self.datePicker.dateValue = NSDate()
    self.tableView.registerForDraggedTypes([NSFilenamesPboardType])
    self.addSortDescriptorsForTableView()
    updateUI()
  }
  
  func addSortDescriptorsForTableView(){
    if let tableColumn = self.tableView.tableColumnWithIdentifier(kNameCell) {
      tableColumn.sortDescriptorPrototype = NSSortDescriptor(key: "name", ascending: true)
    }
    if let tableColumn = self.tableView.tableColumnWithIdentifier(kLatitudeCell) {
      tableColumn.sortDescriptorPrototype = NSSortDescriptor(key: "latitude", ascending: true)
    }
    if let tableColumn = self.tableView.tableColumnWithIdentifier(kLongitudeCell) {
      tableColumn.sortDescriptorPrototype = NSSortDescriptor(key: "longitude", ascending: true)
    }
    if let tableColumn = self.tableView.tableColumnWithIdentifier(kAltitudeCell) {
      tableColumn.sortDescriptorPrototype = NSSortDescriptor(key: "altitude", ascending: true)
    }
    if let tableColumn = self.tableView.tableColumnWithIdentifier(kTimestampCell) {
      tableColumn.sortDescriptorPrototype = NSSortDescriptor(key: "timestamp", ascending: true)
    }
    if let tableColumn = self.tableView.tableColumnWithIdentifier(kModifiedCell) {
      tableColumn.sortDescriptorPrototype = NSSortDescriptor(key: "modifiedAt", ascending: true)
    }
    if let tableColumn = self.tableView.tableColumnWithIdentifier(kSizeCell) {
      tableColumn.sortDescriptorPrototype = NSSortDescriptor(key: "size", ascending: true)
    }
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
    let hasImages = self.processor.images?.count != nil
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
      if let annotation = self.imageAnnotaion {
        self.mapView.removeAnnotation(annotation)
      }
    })
    return true
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
      NSWorkspace.sharedWorkspace().openURL(image.url)
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
        let controller = ImageDetailViewController()
        controller.imageURL = image.url
        let pop = NSPopover()
        pop.behavior = .Semitransient
        pop.contentViewController = controller
        pop.showRelativeToRect(rowView.bounds, ofView: rowView, preferredEdge: NSRectEdge.MaxX)
      }
    }
  }
  
  @IBAction func performRestore(sender:AnyObject){
    showRestoreAlert()
  }
  
  func showRestoreAlert(){
    let alert = NSAlert()
    alert.alertStyle = .WarningAlertStyle
    alert.messageText = NSLocalizedString("RESTORE_ALERT_MESSAGE_TEXT", comment: "Restore Properties")
    alert.informativeText = NSLocalizedString("RESTORE_ALERT_INFORMATIVE_TEXT", comment: "Are you sure restore to backuped original files?")
    alert.addButtonWithTitle(NSLocalizedString("BUTTON_OK", comment: "OK"))
    alert.addButtonWithTitle(NSLocalizedString("BUTTON_CANCEL", comment: "Cancel"))
    alert.beginSheetModalForWindow(self.window!) { (response) in
      if response == NSAlertFirstButtonReturn {
        self.restoreProperties()
      }
    }
  }
  
  func restoreProperties(){
    self.restoreButton.enabled = false
    self.processor.restore({ (restoredCount, message) in
      print("restoreProperties \(restoredCount) \(message)")
      self.processor.reopen({ (success) in
        self.updateUI()
        self.tableView?.reloadData()
        self.showRestoreSuccessAlert(restoredCount)
      })
      }) { (image, index, total) in
        //self.updateTableViewRows(index)
    }
  }
  
  func showRestoreSuccessAlert(count:Int){
    let alert = NSAlert()
    alert.alertStyle = .InformationalAlertStyle
    alert.messageText = NSLocalizedString("RESTORE_SUCCESS_ALERT_MESSAGE_TEXT", comment: "Image Properties Restored")
    let format = NSLocalizedString("RESTORE_SUCCESS_ALERT_INFOMATIVE_TEXT", comment: "Modified images have been restored using backup files, count files affected.")
    alert.informativeText = String(format: format, count)
    alert.addButtonWithTitle(NSLocalizedString("BUTTON_OK", comment: "OK"))
    alert.beginSheetModalForWindow(self.window!) { (response) in
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
    alert.messageText = NSLocalizedString("SAVE_INVALID_ALERT_MESSAGE_TEXT", comment: "GPS Properties Invalid")
    alert.informativeText = NSLocalizedString("SAVE_INVALID_ALERT_INFORMATIVE_TEXT", comment: "GPS coordinate is empty or invalid, please check again.")
    alert.addButtonWithTitle(NSLocalizedString("BUTTON_OK", comment: "OK"))
    alert.beginSheetModalForWindow(self.window!) { (response) in
      
    }
  }
  
  func showSaveAlert(sender:AnyObject?){
    if self.textAltitude.objectValue != nil {
      self.processor.altitude = self.textAltitude.doubleValue
    }
    let backup = self.backupCheckBox.state == NSOnState
    let alert = NSAlert()
    alert.alertStyle = .InformationalAlertStyle
    alert.messageText = NSLocalizedString("SAVE_ALERT_MESSAGE_TEXT", comment: "Save GPS Properties")
    var contentText = "\n"
    if let coordinate = self.processor.coordinate {
      contentText += NSLocalizedString("LATITUDE", comment: "Latitude:") + "\t\(coordinate.latitude)\n"
      contentText += NSLocalizedString("LONGITUDE", comment: "Longitude:") + "\t\(coordinate.longitude)\n"
    }
    if let altitude = self.processor.altitude {
      contentText += NSLocalizedString("ALTITUDE", comment: "Altitude:") + "\t\(altitude)\n"
    }
    if let timestamp = self.processor.timestamp {
      contentText += NSLocalizedString("TIMESTAMP", comment: "Timestamp:") + "\t\(DateFormatter.stringFromDate(timestamp))\n"
    }
    let formatText = backup ? NSLocalizedString("SAVE_ALERT_INFORMATIVE_TEXT", comment: "") : NSLocalizedString("SAVE_ALERT_INFORMATIVE_TEXT_NO_BACKUP", comment: "")
    alert.informativeText = contentText + formatText
    alert.addButtonWithTitle(NSLocalizedString("BUTTON_OK", comment: "OK"))
    alert.addButtonWithTitle(NSLocalizedString("BUTTON_CANCEL", comment: "Cancel"))
    alert.beginSheetModalForWindow(self.window!) { (response) in
      if response == NSAlertFirstButtonReturn {
        self.saveProperties(backup)
      }
    }
  }
  
  func showSaveSuccessAlert(count:Int){
    let alert = NSAlert()
    alert.alertStyle = .WarningAlertStyle
    alert.messageText = NSLocalizedString("SAVE_SUCCESS_ALERT_MESSAGE_TEXT", comment: "GPS Properties Saved")
    let format = NSLocalizedString("SAVE_SUCCESS_ALERT_INFORMATIVE_TEXT", comment: "GPS properties have been written back to images, count files affected.")
    alert.informativeText = String(format: format, count)
    alert.addButtonWithTitle(NSLocalizedString("BUTTON_OK", comment: "OK"))
    alert.beginSheetModalForWindow(self.window!) { (response) in
      //
    }
  }
  
  func saveProperties(backup:Bool){
    print("saveProperties backup=\(backup)")
    updateUI()
    self.saveButton.enabled = false
    let progress = ProgressWindowController()
    progress.showProgressAt(self.window!, completionHandler: nil)
    self.processor.save(backup,
        completionHandler: { (count, message) in
        print("saveProperties: \(count) \(message)")
        progress.dismissProgressAt(self.window!)
        self.updateUI()
        self.tableView?.reloadData()
        self.showSaveSuccessAlert(count)
    },
      processHandler: { (image, index, total) in
        dispatch_async(dispatch_get_main_queue()){
          let titleFormat = NSLocalizedString("SAVE_PROGRESS_TITLE_FORMAT", comment: "")
          let title = String(format: titleFormat, index+1, total)
          progress.updateProgress(title, subtitle: image.name)
          self.tableView?.reloadData()
        }
//        self.updateTableViewRows(index)

    })
  }
  
  func coordinateChanged(sender:AnyObject){
    guard let latitude = self.textLatitude.objectValue as? Double,
      let longitude = self.textLongitude.objectValue as? Double else { return }
    guard latitudeRange.contains(latitude) && longitudeRange.contains(longitude) else { return }
    let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    makeAnnotationAt(coordinate, updateMapView: true)
  }
  
  @IBAction func textLatitudeChanged(sender: NSTextField) {
    coordinateChanged(sender)
  }
  
  @IBAction func textLogitudeChanged(sender: NSTextField) {
    coordinateChanged(sender)
  }
  
  
  @IBAction func textAltitudeChanged(sender: NSTextField) {
    self.processor.altitude = sender.doubleValue
  }
  
  
  @IBAction func chooseDate(sender: NSDatePicker) {
    print("chooseDate \(sender.dateValue)")
    self.processor.timestamp = sender.dateValue
  }
  
  func createAnnotation(coordinate: CLLocationCoordinate2D) -> MapPoint {
    let subtitle = String(format: "Lat:%.4f, Lon:%.4f", coordinate.latitude, coordinate.longitude)
    return MapPoint(coordinate: coordinate, title: "Point", subtitle: subtitle)
  }
  
  func makeAnnotationAt(coordinate: CLLocationCoordinate2D,
                        updateMapView update: Bool,
                        centerInMap center:Bool = false) -> MKAnnotation{
    print("makeAnnotationAt at \(coordinate.latitude),\(coordinate.longitude) update:\(update)")
    let newAnnotaion = createAnnotation(coordinate)
    if update {
      if let oldAnnotation = self.annotation {
        self.mapView.removeAnnotation(oldAnnotation)
      }
      self.mapView.addAnnotation(newAnnotaion)
    }
    if center {
      self.mapView.setCenterCoordinate(coordinate, animated: true)
    }
    self.annotation = newAnnotaion
    self.processor.coordinate = coordinate
    self.textLatitude.objectValue = coordinate.latitude
    self.textLongitude.objectValue = coordinate.longitude
    updateUI()
//    decodeCoordinate()
    return newAnnotaion
  }
  
  func makeImageAnnotation(image: ImageItem){
    guard let latitude = image.latitude,
      let longitude = image.longitude else { return }
    let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    print("makeImageAnnotation for \(image.name)")
    let newAnnotaion = createAnnotation(coordinate)
    newAnnotaion.image = image
    if let oldAnnotation = self.imageAnnotaion {
      self.mapView.removeAnnotation(oldAnnotation)
    }
    self.mapView.addAnnotation(newAnnotaion)
  }
  
  func decodeCoordinate(){
    self.processor.geocode { (placemark) in
      guard let placemark = placemark else { return }
      print("address: \(placemark.location?.altitude) \n \(placemark.country) \(placemark.administrativeArea) \(placemark.locality)  \(placemark.name)")
    }
  }
  
  override func rightMouseUp(theEvent: NSEvent) {
    guard theEvent.clickCount == 1 else { return }
    let point = self.mapView.convertPoint(theEvent.locationInWindow, fromView: nil)
    if NSPointInRect(point, self.mapView.bounds) {
      let coordinate = self.mapView.convertPoint(point, toCoordinateFromView: self.mapView)
//      print("rightMouseUp \(point.x) \(point.y) \(coordinate.latitude) \(coordinate.longitude)")
      makeAnnotationAt(coordinate, updateMapView: true)
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

extension MainWindowController:MKMapViewDelegate {
  
  func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
    guard let annotation = annotation as? MapPoint else { return nil }
    var annotationView:MKAnnotationView?
    if let image = annotation.image {
      annotationView = self.mapView.dequeueReusableAnnotationViewWithIdentifier("Image")
      if annotationView == nil {
        annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "Image")
        annotationView?.draggable = false
        annotationView?.canShowCallout = true
      }else {
        annotationView?.annotation = annotation
      }
      annotationView?.centerOffset = NSPoint(x: -50, y: -50)
      annotationView?.image = ImageHelper.thumbFromImage(image.url, height: 30.0)
    }else{
      annotationView = self.mapView.dequeueReusableAnnotationViewWithIdentifier("Pin")
      if annotationView == nil {
        annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "Pin")
        annotationView?.draggable = true
        annotationView?.canShowCallout = true
      }else {
        annotationView?.annotation = annotation
      }
    }
    return annotationView
  }
  
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
  
  func mapViewDidFinishLoadingMap(mapView: MKMapView) {
    if self.annotation == nil {
      makeAnnotationAt(mapView.centerCoordinate, updateMapView: true, centerInMap: true)
    }
  }
  
  func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
    if newState == MKAnnotationViewDragState.Ending {
      print("didChangeDragState moved to \(view.annotation?.coordinate) \(view.annotation?.title)")
      if let coordinate = view.annotation?.coordinate {
        view.annotation = makeAnnotationAt(coordinate, updateMapView: true)
      }
    }
  }
  
}

extension MainWindowController: NSTableViewDelegate {
  
  func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
    guard let image = self.processor.images?[row] else { return nil }
    var cellIdentifier = ""
    var stringValue:String = ""
    if tableColumn == tableView.tableColumnWithIdentifier(kNameCell) {
      cellIdentifier = kNameCell
      stringValue = image.name
    }else if tableColumn == tableView.tableColumnWithIdentifier(kLatitudeCell) {
      cellIdentifier = kLatitudeCell
      if let latitude = image.latitude {
//        stringValue = "\(latitude)"
        stringValue = ExifUtils.formatDegreeValue(latitude,latitude: true)
      }
    }else if tableColumn == tableView.tableColumnWithIdentifier(kLongitudeCell) {
      cellIdentifier = kLongitudeCell
      if let longitude = image.longitude {
//        stringValue = "\(longitude)"
        stringValue = ExifUtils.formatDegreeValue(longitude,latitude: false)
      }
    }else if tableColumn == tableView.tableColumnWithIdentifier(kAltitudeCell) {
      cellIdentifier = kAltitudeCell
      if let altitude = image.altitude {
        stringValue = String(format: "%.2f", altitude)
      }
    }else if tableColumn == tableView.tableColumnWithIdentifier(kTimestampCell) {
      cellIdentifier = kTimestampCell
      if let dateTime = image.timestamp {
        stringValue = DateFormatter.stringFromDate(dateTime)
      }
    }else if tableColumn == tableView.tableColumnWithIdentifier(kModifiedCell) {
      cellIdentifier = kModifiedCell
      stringValue = DateFormatter.stringFromDate(image.exifDate ?? image.modifiedAt)
    }else if tableColumn == tableView.tableColumnWithIdentifier(kSizeCell) {
      cellIdentifier = kSizeCell
      stringValue = self.processor.sizeFormatter.stringFromByteCount(Int64(image.size))
    }else if tableColumn == tableView.tableColumnWithIdentifier(kActionCell) {
      cellIdentifier = kActionCell
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
      cell.textField?.textColor = NSColor.redColor()
    } else if self.processor.restoringIndex == row{
      cell.textField?.textColor = NSColor.redColor()
    }  else {
      cell.textField?.textColor = image.modified ? NSColor.blueColor() : NSColor.blackColor()
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
  
  
  func tableViewSelectionDidChange(notification: NSNotification) {
    if let annotation = self.imageAnnotaion {
      self.mapView.removeAnnotation(annotation)
    }
    let row = self.tableView.selectedRow
    if row >= 0 {
      guard let image = self.processor.images?[row] else { return }
//      makeImageAnnotation(image)
    }
  }
  
}

extension MainWindowController: NSTableViewDataSource {
  
  func tableView(tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
    if let images = self.processor.images{
      if let sortedImages = (images as NSArray).sortedArrayUsingDescriptors(tableView.sortDescriptors) as? [ImageItem] {
        self.processor.images = sortedImages
        tableView.reloadData()
      }
    }
  }
  
  
  func numberOfRowsInTableView(tableView: NSTableView) -> Int {
    return self.processor.images?.count ?? 0
  }
}

extension MainWindowController:NSWindowDelegate {
  
  func windowDidResize(notification: NSNotification) {
  }
  
  func windowShouldClose(sender: AnyObject) -> Bool {
    return self.processor.savingIndex == nil && self.processor.restoringIndex == nil
  }
}
