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
  
  @IBOutlet weak var tableView:NSTableView!
  @IBOutlet weak var textLatitude:NSTextField!
  @IBOutlet weak var textLongitude:NSTextField!
  @IBOutlet weak var textAltitude:NSTextField!
  @IBOutlet weak var datePicker:NSDatePicker!
  @IBOutlet weak var mapLabel:NSTextField!
  @IBOutlet weak var mapView:MKMapView!
  @IBOutlet weak var infoButton:NSButton!
  @IBOutlet weak var applyButton:NSButton!
  
  let processor = ImageProcessor()
  var mapInitialized:Bool = false
  var annotation:MKAnnotation?

  override var nibName: String?{
    return "MainViewController"
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  func copy(sender:AnyObject?){
    guard self.tableView.selectedRow >= 0 else { return }
    guard let image = self.processor.images?[self.tableView.selectedRow] else { return }
    let pb = NSPasteboard.generalPasteboard()
    pb.clearContents()
    pb.setString(image.url.path!, forType: NSPasteboardTypeString)
  }
  
  func paste(sender:AnyObject?){
//    guard self.processor.rootURL == nil else { return }
    let pb = NSPasteboard.generalPasteboard()
    let objects = pb.readObjectsForClasses(
      [NSURL.self],options: [NSPasteboardURLReadingFileURLsOnlyKey:true]) as? [NSURL]
    guard let path = objects?.first?.path else { return }
    let rootURL = NSURL(fileURLWithPath:path)
    self.processor.openWithCompletionHandler(rootURL, handler: { (success) in
      self.tableView?.reloadData()
    })
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
      self.processor.openWithCompletionHandler(rootURL, handler: { (success) in
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
        let controller = ImagePreviewController()
        controller.url = image.url
        let pop = NSPopover()
        pop.behavior = .Semitransient
        pop.contentViewController = controller
        pop.showRelativeToRect(rowView.bounds, ofView: rowView, preferredEdge: NSRectEdge.MaxX)
//        NSWorkspace.sharedWorkspace().openURL(image.url)
      }
    }
  }
  
  @IBAction func clickInfoButton(sender:AnyObject){
    print("clickInfoButton")
  }
  
  @IBAction func clickApplyButton(sender:AnyObject){
    print("clickApplyButton")
    self.processor.altitude = self.textAltitude.doubleValue
    self.processor.saveWithCompletionHandler { (count, message) in
      print("saveWithCompletionHandler: \(count) \(message)")
      self.tableView?.reloadData()
    }
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
  
  @IBAction func addAnnotation(sender:AnyObject){
    let loc = CLLocationCoordinate2DMake(39.9994132, 116.1734272)
    let title = "Lat:\(loc.latitude) Lon:\(loc.longitude)"
    let point = MapPoint(coordinate: loc, title: title)
    self.mapView.addAnnotation(point)
    self.mapView.setCenterCoordinate(loc, animated: true)
    //    let region = MKCoordinateRegionMakeWithDistance(loc, 1000, 1000)
    //    self.mapView.setRegion(region, animated: true)
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
    self.textLatitude.stringValue = ExifUtils.formatDegreeValue(coordinate.latitude, latitude: true)
    self.textLongitude.stringValue = ExifUtils.formatDegreeValue(coordinate.longitude, latitude: false)
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
    print("rightMouseDown x=\(point.x) y=\(point.y) \(coordinate.latitude) \(coordinate.longitude)")
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
    let coordinate = userLocation.coordinate
    if !self.mapInitialized {
      self.mapInitialized = true
      self.mapView.setCenterCoordinate(coordinate, animated: true)
      //      let region = MKCoordinateRegionMakeWithDistance(coordinate, 1000, 1000)
      //      self.mapView.setRegion(region, animated: true)
    }
  }
  
  func mapView(mapView: MKMapView, didAddAnnotationViews views: [MKAnnotationView]) {
    print("didAddAnnotationViews \(views.first)")
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
        stringValue = "\(latitude)"
//        stringValue = ExifUtils.formatDegreeValue(latitude,latitude: true)
      }
    }else if tableColumn == tableView.tableColumnWithIdentifier("LongitudeCell") {
      cellIdentifier = "LongitudeCell"
      if let longitude = image.longitude {
        stringValue = "\(longitude)"
//        stringValue = ExifUtils.formatDegreeValue(longitude,latitude: false)
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
    if let button = cell.viewWithTag(1) as? NSButton {
      button.target = self
      button.action = #selector(self.openInPreview(_:))
    }
    cell.textField?.stringValue = stringValue
    return cell
  }
}

extension MainViewController: NSTableViewDataSource {
  func numberOfRowsInTableView(tableView: NSTableView) -> Int {
    return self.processor.images?.count ?? 0
  }
}
