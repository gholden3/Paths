//
//  FirstViewController.swift
//  MyLocations
//
//  Created by Gina Holden on 1/25/16.
//  Copyright © 2016 Gina Holden. All rights reserved.
//

import UIKit
import CoreLocation

class VisitViewController: UITableViewController, CLLocationManagerDelegate {
    var numVisits = 2
    var visits: [VisitItem]
    var locationManager: CLLocationManager = CLLocationManager()
    var lastLocationError: NSError?
    required init?(coder aDecoder: NSCoder) {
        visits = [VisitItem]()
        
        let row0item = VisitItem()
        row0item.coordinates = "coordinates here"
        row0item.duration = "duration here"
        row0item.user = "gholden3"
        visits.append(row0item)
        
        let row1item = VisitItem()
        row1item.coordinates = "coordinates2"
        row1item.duration = "duration 2"
        row1item.user = "gholden3"
        visits.append(row1item)
        
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let authStatus = CLLocationManager.authorizationStatus()
        if authStatus == .NotDetermined {
            locationManager.requestAlwaysAuthorization()
            return
        }
        if authStatus == .Denied || authStatus == .Restricted {
            showLocationServicesDeniedAlert()
            return
        }
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        //updateLabels()
        //configureGetButton()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    func showLocationServicesDeniedAlert() {
        let alert = UIAlertController(title: "Location Services Disabled",
            message: "Please enable location services for this app in Settings.", preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        presentViewController(alert, animated: true, completion: nil)
        alert.addAction(okAction)
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("visits.count: " + "\(visits.count)")
        return visits.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("VisitItem", forIndexPath: indexPath)
        
        let visit = visits[indexPath.row]
        
        configureTextForCell(cell, withVisitItem: visit)
        //configureCheckmarkForCell(cell, withChecklistItem: item)
        
        return cell
    }
    
    func configureTextForCell(cell: UITableViewCell, withVisitItem visit: VisitItem) {
        let label = cell.viewWithTag(1000) as! UILabel
        label.text = "\(visit.user)" + " visited: " + "\(visit.coordinates)  " + "\(visit.duration)"
    }

    func sendVisitToServer(visit: VisitItem){
        let url = NSURL(string:"http://54.174.70.236:8097")
        let request = NSMutableURLRequest(URL: url!)
        let session = NSURLSession.sharedSession()
        request.HTTPMethod = "POST"
        let jsonObject: [String: AnyObject] = [
            "user:": "\(visit.user)",
            "duration": "\(visit.duration)",
            "location": "\(visit.coordinates)"
        ]
        
        let valid = NSJSONSerialization.isValidJSONObject(jsonObject)
        if(valid){
            do {
                request.HTTPBody =  try NSJSONSerialization.dataWithJSONObject(jsonObject, options: [])
                
            } catch let error as NSError {
                print("there was an error")
                print("\(error)")
                request.HTTPBody = nil
            }
        } else {
            print("not a valid json object")
        }
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            print("Response:")})
        //let task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
                //print("Response: \(response)")})
        task.resume()
    }
    
    func locationManager(manager: CLLocationManager, didVisit visit: CLVisit)
    {
        let dateComponentsFormatter = NSDateComponentsFormatter()
        dateComponentsFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyle.Full
        //println("visit: \(visit.coordinate.latitude),\(visit.coordinate.longitude)")
        numVisits++
        let newItem = VisitItem()
        newItem.coordinates = "\(visit.coordinate)"
        let date2 = visit.departureDate
        let date1 = visit.arrivalDate
        let interval = date2.timeIntervalSinceDate(date1)
        let duration = dateComponentsFormatter.stringFromTimeInterval(interval)
        newItem.duration = " \(duration)"
        newItem.user = "gholden3"
        visits.append(newItem)
        sendVisitToServer(newItem)
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) { //delegate method woo
        print("updated location")
        lastLocationError = nil
        //extract data from location object
        let newLocation = locations.last! //locations is an array of CLLocation s
        let lat:String = "\(newLocation.coordinate.latitude)"
        let long:String = "\(newLocation.coordinate.longitude)"
        //for now just put the timestamp from location into duration for visit
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .MediumStyle
        let timestamp = newLocation.timestamp
        let duration = dateFormatter.stringFromDate(timestamp)
        let newItem = VisitItem()
        newItem.coordinates = "lat: " + lat + "long: " + long
        newItem.duration = duration
        newItem.user = "gholden3"
        visits.append(newItem)
        tableView.reloadData()
        sendVisitToServer(newItem)
        
        
        //println("visit: \(visit.coordinate.latitude),\(visit.coordinate.longitude)")
        numVisits++
        // 3
        //if new reading is more accurate (smaller error)
        // or this is the first location you are recieving
        //notice the foce unwrapping!
        /*if location == nil || location!.horizontalAccuracy > newLocation.horizontalAccuracy {
        // 4
        lastLocationError = nil
        location = newLocation
        updateLabels()
        // 5
        if newLocation.horizontalAccuracy <= locationManager.desiredAccuracy { //you have enough accuracy
        print("*** We're done!")
        stopLocationManager()
        configureGetButton()
        }
        }*/
        
    }

    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("didFailWithError \(error)")
        if error.code == CLError.LocationUnknown.rawValue { //it just can't get a location rn
            return
        }
        lastLocationError = error //you got a more serious error
        locationManager.stopUpdatingLocation() //obtaining a location seems to be impossible for where the user is. stop location man
        let newItem = VisitItem()
        newItem.coordinates = "ERROR:  "
        let duration = "\(error)"
        newItem.duration = "arr: \(duration)"
        visits.append(newItem)
        //updateLabels()
        //configureGetButton()
    }

    /*
    var location: CLLocation?
    var updatingLocation = false
    
    var message = "hello" */
/*
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var tagButton: UIButton!
    @IBOutlet weak var getButton: UIButton!
    
    @IBAction func getLocation() { // called when user taps get location button
    
        if updatingLocation { //stop button was pressed
            stopLocationManager()
        } else { //get location was pressed
            location = nil
            lastLocationError = nil
            startLocationManager()
        }
        updateLabels()
        configureGetButton()
    }
    
   
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    func updateLabels() {
        //unwrap since optional
        //if we have a location
        if let location = location { //its ok for unwrapped var to have same name as optional
            latitudeLabel.text = String(format: "%.8f", location.coordinate.latitude) //8 digits behind decimal
            longitudeLabel.text = String(format: "%.8f", location.coordinate.longitude)
            //tagButton.hidden = false
            messageLabel.text = ""
        } else { //no location
            latitudeLabel.text = ""
            longitudeLabel.text = ""
            //addressLabel.text = ""
            //tagButton.hidden = true
            let statusMessage: String
            if let error = lastLocationError {
                //kCLErrorDomain is core location errors
                if error.domain == kCLErrorDomain && error.code == CLError.Denied.rawValue {
                    statusMessage = "Location Services Disabled"
                } else { //no way to get a location fix
                    statusMessage = "Error Getting Location" }
                //check if the user disabled locations on their whole device
            } else if !CLLocationManager.locationServicesEnabled() {
                statusMessage = "Location Services Disabled"
            } else if updatingLocation{
                statusMessage = "Searching..."
            } else {
                statusMessage = "Tap 'Start Sending Locations' to Start"
            }
            messageLabel.text = statusMessage
        }
    }
    
    func stopLocationManager() {
        if updatingLocation { //check if location manager was currently active
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil
            updatingLocation = false
        }
    }
    
    func startLocationManager() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.distanceFilter = kCLDistanceFilterNone
            locationManager.startUpdatingLocation()
            locationManager.allowDeferredLocationUpdatesUntilTraveled( 5, timeout: CLTimeIntervalMax)
            updatingLocation = true
        }
    }
    
    
    func configureGetButton() {
        if updatingLocation  {
            getButton.setTitle("Stop Sending Locations", forState: .Normal)
        } else {
            getButton.setTitle("Start Sending Locations", forState: .Normal)
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
   
    
    
    func locationManager(manager: CLLocationManager, didFinishDeferredUpdatesWithError error: NSError?) {
       print("did finish deferred updates with error \(error)")
    }
    
    
    */
}



