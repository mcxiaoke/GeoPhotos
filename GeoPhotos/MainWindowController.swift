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
  kCGImagePropertyGPSLatitude as String: 0.0 as AnyObject,
  kCGImagePropertyGPSLongitude as String: 0.0 as AnyObject,
  kCGImagePropertyGPSAltitude as String: 0.0 as AnyObject,
  kCGImagePropertyGPSTimeStamp as String: "00:00:00" as AnyObject,
  kCGImagePropertyGPSDateStamp as String: "2016-06-06" as AnyObject,
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
    self.datePicker.dateValue = Date()
    self.tableView.register(forDraggedTypes: [NSFilenamesPboardType])
    self.addSortDescriptorsForTableView()
    updateUI()
  }
  
  func addSortDescriptorsForTableView(){
    if let tableColumn = self.tableView.tableColumn(withIdentifier: kNameCell) {
      tableColumn.sortDescriptorPrototype = NSSortDescriptor(key: "name", ascending: true)
    }
    if let tableColumn = self.tableView.tableColumn(withIdentifier: kLatitudeCell) {
      tableColumn.sortDescriptorPrototype = NSSortDescriptor(key: "latitude", ascending: true)
    }
    if let tableColumn = self.tableView.tableColumn(withIdentifier: kLongitudeCell) {
      tableColumn.sortDescriptorPrototype = NSSortDescriptor(key: "longitude", ascending: true)
    }
    if let tableColumn = self.tableView.tableColumn(withIdentifier: kAltitudeCell) {
      tableColumn.sortDescriptorPrototype = NSSortDescriptor(key: "altitude", ascending: true)
    }
    if let tableColumn = self.tableView.tableColumn(withIdentifier: kTimestampCell) {
      tableColumn.sortDescriptorPrototype = NSSortDescriptor(key: "timestamp", ascending: true)
    }
    if let tableColumn = self.tableView.tableColumn(withIdentifier: kModifiedCell) {
      tableColumn.sortDescriptorPrototype = NSSortDescriptor(key: "modifiedAt", ascending: true)
    }
    if let tableColumn = self.tableView.tableColumn(withIdentifier: kSizeCell) {
      tableColumn.sortDescriptorPrototype = NSSortDescriptor(key: "size", ascending: true)
    }
  }
  
  func updateTableViewRows(_ index:Int){
    let rowIndexes = IndexSet(integersIn: NSRange(location: max(index - 1, 0), length: 3).toRange() ?? 0..<0)
    let count = self.tableView.tableColumns.count
    let columnIndexes = IndexSet(integersIn: NSRange(location: 0, length: count).toRange() ?? 0..<0)
    DispatchQueue.main.async{
      self.tableView?.reloadData(forRowIndexes: rowIndexes, columnIndexes: columnIndexes)
      self.tableView.scrollRowToVisible(index)
    }
  }
  
  func updateUI(){
    let hasImages = self.processor.images?.count != nil
    self.saveButton.isEnabled = hasImages
      && self.processor.coordinate != nil
      && self.processor.savingIndex == nil
      && self.processor.restoringIndex == nil
    self.restoreButton.isEnabled = hasImages
      && self.processor.hasBackup
      && self.processor.savingIndex == nil
      && self.processor.restoringIndex == nil
  }
  
  func copy(_ sender:AnyObject?){
    guard self.tableView.selectedRow >= 0 else { return }
    guard let image = self.processor.images?[self.tableView.selectedRow] else { return }
    let pb = NSPasteboard.general()
    pb.clearContents()
    pb.setString(image.url.path, forType: NSPasteboardTypeString)
  }
  
  func paste(_ sender:AnyObject?){
    readFromPasteboard(NSPasteboard.general())
  }
  
  func readFromPasteboard(_ pb:NSPasteboard) -> Bool{
    let objects = pb.readObjects(
      forClasses: [URL.self as! AnyClass],options: [NSPasteboardURLReadingFileURLsOnlyKey:true]) as? [URL]
    guard let path = objects?.first?.path else { return false }
    let rootURL = URL(fileURLWithPath:path)
    self.processor.open(rootURL, completionHandler: { (success) in
      self.tableView?.reloadData()
      if let annotation = self.imageAnnotaion {
        self.mapView.removeAnnotation(annotation)
      }
    })
    return true
  }
  
  func openDocument(_ sender:AnyObject){
    showOpenPanel()
  }
  
  fileprivate func showOpenPanel(){
    let panel = NSOpenPanel()
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = true
    panel.canCreateDirectories = false
    panel.canChooseFiles = false
    panel.begin { (result) in
      guard result == NSFileHandlingPanelOKButton else {
        return
      }
      guard let rootURL = panel.url else {
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
  
  @IBAction func doubleClickRow(_ sender:AnyObject){
    if self.tableView.selectedRow >= 0 {
      guard let image = self.processor.images?[self.tableView.selectedRow] else { return }
      NSWorkspace.shared().open(image.url as URL)
    }
  }
  
  
  @IBAction func revealInFinder(_ sender:AnyObject){
    let row = self.tableView.row(for: sender as! NSView)
    if row >= 0 {
      if let image = self.processor.images?[row] {
        NSWorkspace.shared().activateFileViewerSelecting([image.url as URL])
      }
    }
  }
  
  
  @IBAction func openInPreview(_ sender:AnyObject){
    guard let rowView = sender as? NSView else { return }
    let row = self.tableView.row(for: rowView)
    if row >= 0 {
      if let image = self.processor.images?[row] {
        let controller = ImageDetailViewController()
        controller.imageURL = image.url
        let pop = NSPopover()
        pop.behavior = .semitransient
        pop.contentViewController = controller
        pop.show(relativeTo: rowView.bounds, of: rowView, preferredEdge: NSRectEdge.maxX)
      }
    }
  }
  
  @IBAction func performRestore(_ sender:AnyObject){
    showRestoreAlert()
  }
  
  func showRestoreAlert(){
    let alert = NSAlert()
    alert.alertStyle = .warning
    alert.messageText = NSLocalizedString("RESTORE_ALERT_MESSAGE_TEXT", comment: "Restore Properties")
    alert.informativeText = NSLocalizedString("RESTORE_ALERT_INFORMATIVE_TEXT", comment: "Are you sure restore to backuped original files?")
    alert.addButton(withTitle: NSLocalizedString("BUTTON_OK", comment: "OK"))
    alert.addButton(withTitle: NSLocalizedString("BUTTON_CANCEL", comment: "Cancel"))
    alert.beginSheetModal(for: self.window!, completionHandler: { (response) in
      if response == NSAlertFirstButtonReturn {
        self.restoreProperties()
      }
    }) 
  }
  
  func restoreProperties(){
    self.restoreButton.isEnabled = false
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
  
  func showRestoreSuccessAlert(_ count:Int){
    let alert = NSAlert()
    alert.alertStyle = .informational
    alert.messageText = NSLocalizedString("RESTORE_SUCCESS_ALERT_MESSAGE_TEXT", comment: "Image Properties Restored")
    let format = NSLocalizedString("RESTORE_SUCCESS_ALERT_INFOMATIVE_TEXT", comment: "Modified images have been restored using backup files, count files affected.")
    alert.informativeText = String(format: format, count)
    alert.addButton(withTitle: NSLocalizedString("BUTTON_OK", comment: "OK"))
    alert.beginSheetModal(for: self.window!, completionHandler: { (response) in
      //
    }) 
  }
  
  @IBAction func performSave(_ sender:AnyObject){
    print("performSave")
    guard self.processor.coordinate != nil else {
      showInvalidAlert()
      return
    }
    showSaveAlert(nil)
  }
  
  func showInvalidAlert(){
    let alert = NSAlert()
    alert.alertStyle = .warning
    alert.messageText = NSLocalizedString("SAVE_INVALID_ALERT_MESSAGE_TEXT", comment: "GPS Properties Invalid")
    alert.informativeText = NSLocalizedString("SAVE_INVALID_ALERT_INFORMATIVE_TEXT", comment: "GPS coordinate is empty or invalid, please check again.")
    alert.addButton(withTitle: NSLocalizedString("BUTTON_OK", comment: "OK"))
    alert.beginSheetModal(for: self.window!, completionHandler: { (response) in
      
    }) 
  }
  
  func showSaveAlert(_ sender:AnyObject?){
    if self.textAltitude.objectValue != nil {
      self.processor.altitude = self.textAltitude.doubleValue
    }
    let backup = self.backupCheckBox.state == NSOnState
    let alert = NSAlert()
    alert.alertStyle = .informational
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
      contentText += NSLocalizedString("TIMESTAMP", comment: "Timestamp:") + "\t\(DateFormatter.string(from: timestamp))\n"
    }
    let formatText = backup ? NSLocalizedString("SAVE_ALERT_INFORMATIVE_TEXT", comment: "") : NSLocalizedString("SAVE_ALERT_INFORMATIVE_TEXT_NO_BACKUP", comment: "")
    alert.informativeText = contentText + formatText
    alert.addButton(withTitle: NSLocalizedString("BUTTON_OK", comment: "OK"))
    alert.addButton(withTitle: NSLocalizedString("BUTTON_CANCEL", comment: "Cancel"))
    alert.beginSheetModal(for: self.window!, completionHandler: { (response) in
      if response == NSAlertFirstButtonReturn {
        self.saveProperties(backup)
      }
    }) 
  }
  
  func showSaveSuccessAlert(_ count:Int){
    let alert = NSAlert()
    alert.alertStyle = .warning
    alert.messageText = NSLocalizedString("SAVE_SUCCESS_ALERT_MESSAGE_TEXT", comment: "GPS Properties Saved")
    let format = NSLocalizedString("SAVE_SUCCESS_ALERT_INFORMATIVE_TEXT", comment: "GPS properties have been written back to images, count files affected.")
    alert.informativeText = String(format: format, count)
    alert.addButton(withTitle: NSLocalizedString("BUTTON_OK", comment: "OK"))
    alert.beginSheetModal(for: self.window!, completionHandler: { (response) in
      //
    }) 
  }
  
  func saveProperties(_ backup:Bool){
    print("saveProperties backup=\(backup)")
    updateUI()
    self.saveButton.isEnabled = false
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
        DispatchQueue.main.async{
          let titleFormat = NSLocalizedString("SAVE_PROGRESS_TITLE_FORMAT", comment: "")
          let title = String(format: titleFormat, index+1, total)
          progress.updateProgress(title, subtitle: image.name)
          self.tableView?.reloadData()
        }
//        self.updateTableViewRows(index)

    })
  }
  
  func coordinateChanged(_ sender:AnyObject){
    guard let latitude = self.textLatitude.objectValue as? Double,
      let longitude = self.textLongitude.objectValue as? Double else { return }
    guard latitudeRange.contains(latitude) && longitudeRange.contains(longitude) else { return }
    let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    makeAnnotationAt(coordinate, updateMapView: true)
  }
  
  @IBAction func textLatitudeChanged(_ sender: NSTextField) {
    coordinateChanged(sender)
  }
  
  @IBAction func textLogitudeChanged(_ sender: NSTextField) {
    coordinateChanged(sender)
  }
  
  
  @IBAction func textAltitudeChanged(_ sender: NSTextField) {
    self.processor.altitude = sender.doubleValue
  }
  
  
  @IBAction func chooseDate(_ sender: NSDatePicker) {
    print("chooseDate \(sender.dateValue)")
    self.processor.timestamp = sender.dateValue
  }
  
  func createAnnotation(_ coordinate: CLLocationCoordinate2D) -> MapPoint {
    let subtitle = String(format: "Lat:%.4f, Lon:%.4f", coordinate.latitude, coordinate.longitude)
    return MapPoint(coordinate: coordinate, title: "Point", subtitle: subtitle)
  }
  
  func makeAnnotationAt(_ coordinate: CLLocationCoordinate2D,
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
      self.mapView.setCenter(coordinate, animated: true)
    }
    self.annotation = newAnnotaion
    self.processor.coordinate = coordinate
    self.textLatitude.objectValue = coordinate.latitude
    self.textLongitude.objectValue = coordinate.longitude
    updateUI()
//    decodeCoordinate()
    return newAnnotaion
  }
  
  func makeImageAnnotation(_ image: ImageItem){
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
  
  override func rightMouseUp(with theEvent: NSEvent) {
    guard theEvent.clickCount == 1 else { return }
    let point = self.mapView.convert(theEvent.locationInWindow, from: nil)
    if NSPointInRect(point, self.mapView.bounds) {
      let coordinate = self.mapView.convert(point, toCoordinateFrom: self.mapView)
//      print("rightMouseUp \(point.x) \(point.y) \(coordinate.latitude) \(coordinate.longitude)")
      makeAnnotationAt(coordinate, updateMapView: true)
    }
  }
  
  func openMapForCoordinate(_ coordinate: CLLocationCoordinate2D) {
    let distance:CLLocationDistance = 10000
    let regionSpan = MKCoordinateRegionMakeWithDistance(coordinate, distance, distance)
    let options = [
      MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center),
      MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span)
    ]
    let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: nil)
    let mapItem = MKMapItem(placemark: placemark)
    mapItem.openInMaps(launchOptions: options)
    
  }
    
}

extension MainWindowController:MKMapViewDelegate {
  
  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    guard let annotation = annotation as? MapPoint else { return nil }
    var annotationView:MKAnnotationView?
    if let image = annotation.image {
      annotationView = self.mapView.dequeueReusableAnnotationView(withIdentifier: "Image")
      if annotationView == nil {
        annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "Image")
        annotationView?.isDraggable = false
        annotationView?.canShowCallout = true
      }else {
        annotationView?.annotation = annotation
      }
      annotationView?.centerOffset = NSPoint(x: -50, y: -50)
      annotationView?.image = ImageHelper.thumbFromImage(image.url, height: 30.0)
    }else{
      annotationView = self.mapView.dequeueReusableAnnotationView(withIdentifier: "Pin")
      if annotationView == nil {
        annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "Pin")
        annotationView?.isDraggable = true
        annotationView?.canShowCallout = true
      }else {
        annotationView?.annotation = annotation
      }
    }
    return annotationView
  }
  
  func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
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
  
  func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
    if self.annotation == nil {
      makeAnnotationAt(mapView.centerCoordinate, updateMapView: true, centerInMap: true)
    }
  }
  
  func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
    if newState == MKAnnotationViewDragState.ending {
      print("didChangeDragState moved to \(view.annotation?.coordinate) \(view.annotation?.title)")
      if let coordinate = view.annotation?.coordinate {
        view.annotation = makeAnnotationAt(coordinate, updateMapView: true)
      }
    }
  }
  
}

extension MainWindowController: NSTableViewDelegate {
  
  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    guard let image = self.processor.images?[row] else { return nil }
    var cellIdentifier = ""
    var stringValue:String = ""
    if tableColumn == tableView.tableColumn(withIdentifier: kNameCell) {
      cellIdentifier = kNameCell
      stringValue = image.name
    }else if tableColumn == tableView.tableColumn(withIdentifier: kLatitudeCell) {
      cellIdentifier = kLatitudeCell
      if let latitude = image.latitude {
//        stringValue = "\(latitude)"
        stringValue = ExifUtils.formatDegreeValue(latitude,latitude: true)
      }
    }else if tableColumn == tableView.tableColumn(withIdentifier: kLongitudeCell) {
      cellIdentifier = kLongitudeCell
      if let longitude = image.longitude {
//        stringValue = "\(longitude)"
        stringValue = ExifUtils.formatDegreeValue(longitude,latitude: false)
      }
    }else if tableColumn == tableView.tableColumn(withIdentifier: kAltitudeCell) {
      cellIdentifier = kAltitudeCell
      if let altitude = image.altitude {
        stringValue = String(format: "%.2f", altitude)
      }
    }else if tableColumn == tableView.tableColumn(withIdentifier: kTimestampCell) {
      cellIdentifier = kTimestampCell
      if let dateTime = image.timestamp {
        stringValue = DateFormatter.string(from: dateTime)
      }
    }else if tableColumn == tableView.tableColumn(withIdentifier: kModifiedCell) {
      cellIdentifier = kModifiedCell
      stringValue = DateFormatter.string(from: image.exifDate ?? image.modifiedAt)
    }else if tableColumn == tableView.tableColumn(withIdentifier: kSizeCell) {
      cellIdentifier = kSizeCell
      stringValue = self.processor.sizeFormatter.string(fromByteCount: Int64(image.size))
    }else if tableColumn == tableView.tableColumn(withIdentifier: kActionCell) {
      cellIdentifier = kActionCell
    }
    guard let cell = tableView.make(withIdentifier: cellIdentifier, owner: nil)
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
      cell.textField?.textColor = NSColor.red
    } else if self.processor.restoringIndex == row{
      cell.textField?.textColor = NSColor.red
    }  else {
      cell.textField?.textColor = image.modified ? NSColor.blue : NSColor.black
    }
    return cell
  }
  
  // drag and drop
  // http://stackoverflow.com/questions/4839561/nstableview-drop-app-file-whats-going-wrong
  
  func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableViewDropOperation) -> NSDragOperation {
    return NSDragOperation.copy
  }
  
  func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableViewDropOperation) -> Bool {
    print("acceptDrop row=\(row) info=\(info)")
    return readFromPasteboard(info.draggingPasteboard())
  }
  
  
  func tableViewSelectionDidChange(_ notification: Notification) {
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
  
  func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
    if let images = self.processor.images{
      if let sortedImages = (images as NSArray).sortedArray(using: tableView.sortDescriptors) as? [ImageItem] {
        self.processor.images = sortedImages
        tableView.reloadData()
      }
    }
  }
  
  
  func numberOfRows(in tableView: NSTableView) -> Int {
    return self.processor.images?.count ?? 0
  }
}

extension MainWindowController:NSWindowDelegate {
  
  func windowDidResize(_ notification: Notification) {
  }
  
  func windowShouldClose(_ sender: Any) -> Bool {
    return self.processor.savingIndex == nil && self.processor.restoringIndex == nil
  }
}
