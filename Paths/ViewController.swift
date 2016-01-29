//
//  FirstViewController.swift
//  MyLocations
//
//  Created by Gina Holden on 1/25/16.
//  Copyright © 2016 Gina Holden. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    let locationManager = CLLocationManager()
    var location: CLLocation?
    var updatingLocation = false
    var lastLocationError: NSError?
    var message = "hello"

    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var tagButton: UIButton!
    @IBOutlet weak var getButton: UIButton!
    
    @IBAction func getLocation() { // called when user taps get location button
        let authStatus = CLLocationManager.authorizationStatus()
        if authStatus == .NotDetermined {
            locationManager.requestAlwaysAuthorization()
            return
        }
        if authStatus == .Denied || authStatus == .Restricted {
            showLocationServicesDeniedAlert()
            return
        }
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateLabels()
        configureGetButton()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func showLocationServicesDeniedAlert() {
        let alert = UIAlertController(title: "Location Services Disabled",
            message: "Please enable location services for this app in Settings.", preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        presentViewController(alert, animated: true, completion: nil)
        alert.addAction(okAction)
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
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("didFailWithError \(error)")
        if error.code == CLError.LocationUnknown.rawValue { //it just can't get a location rn
            return
        }
        lastLocationError = error //you got a more serious error
        stopLocationManager() //obtaining a location seems to be impossible for where the user is. stop location man
        updateLabels()
        configureGetButton()
    }
    
    
    func locationManager(manager: CLLocationManager, didFinishDeferredUpdatesWithError error: NSError?) {
       print("did finish deferred updates with error \(error)")
    }
    
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) { //delegate method woo
        let newLocation = locations.last! //locations is an array of CLLocation s
        print("didUpdateLocations \(newLocation)")
        message = "didUpdateLocations \(newLocation)"
        /*if newLocation.timestamp.timeIntervalSinceNow < -5 { //ignore if it is too old
            return
        } */
        // 2
        if newLocation.horizontalAccuracy < 0 { //invalid
            return
        }
        lastLocationError = nil
        location = newLocation
        updateLabels()
        let url = NSURL(string:"http://54.174.70.236:8097")
        let request = NSMutableURLRequest(URL: url!)
        let session = NSURLSession.sharedSession()
        request.HTTPMethod = "POST"
        //var params = [String : String]()
        //params = ["time":"\(newLocation.timestamp)", "pos":"pos:\(newLocation.coordinate)"]
       // let data : NSData = NSKeyedArchiver.archivedDataWithRootObject(params)
        
        let jsonObject: [String: AnyObject] = [
            "timestamp": "\(newLocation.timestamp)",
            "location": "\(newLocation.coordinate)"
        ]
        
        let valid = NSJSONSerialization.isValidJSONObject(jsonObject)
        if(valid){
        //let data : NSData = [{"key":"value", "key":"value"}]
        //NSJSONSerialization.dataWithJSONObject(para, options: NSJSONWritingOptions())
        do {
            request.HTTPBody =  try NSJSONSerialization.dataWithJSONObject(jsonObject, options: [])
            
        } catch let error as NSError {
            print("there was an error")
            print("\(error)")
            request.HTTPBody = nil
            } }
        else {
            print("not a valid json object")
        }
        //request.HTTPBody = NSJSONSerialization.dataWithJSONObject(params, options: nil, error:&err)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            print("Response: \(response)")})
        
        task.resume()
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
    
    
}



