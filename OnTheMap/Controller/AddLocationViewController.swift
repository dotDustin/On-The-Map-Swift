//
//  AddLocationViewController.swift
//  OnTheMap
//
//  Created by Dustin Mahone on 12/3/19.
//  Copyright © 2019 Dustin. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class AddLocationViewController: UIViewController, MKMapViewDelegate, UITextFieldDelegate {

    //MARK: - Outlets
    @IBOutlet weak var locationTextField: UITextField!
    @IBOutlet weak var webTextField: UITextField!
    @IBOutlet weak var findLocationButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var finishStackView: UIStackView!
    @IBOutlet weak var alertTextView: UITextView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    //MARK: - Variables and Constants
    lazy var geocoder = CLGeocoder()
    var latitude: Double = 21.0
    var longitude: Double = -37.1
    var mediaURL: String = ""
    
    //MARK: - Lifecycle methods
    override func viewWillAppear(_ animated: Bool) {
        webTextField.delegate = self
        
        alertView(false, message: "")
        needsValidInput(true)
    }
    
    //MARK: - Methods
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.webTextField.text = "http://"
    }
    
    func needsValidInput(_ needsValidInput: Bool) {
        locationTextField.isHidden = !needsValidInput
        webTextField.isHidden = !needsValidInput
        findLocationButton.isHidden = !needsValidInput
        mapView.isHidden = needsValidInput
        finishStackView.isHidden = needsValidInput
    }
    
    func alertView(_ alertToShow: Bool, message: String) {
        alertTextView.isHidden = !alertToShow
        activityIndicator.isHidden = !alertToShow
        if alertToShow == true {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
    }
    
    func showPin() {
        var annotations = [MKPointAnnotation]()
        let annotation = MKPointAnnotation()
        let coordinate = CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
        annotation.coordinate = coordinate
        annotation.title = self.webTextField.text
        annotations.append(annotation)
        
        DispatchQueue.main.async {
            self.mapView.addAnnotations(annotations)
            self.mapView.centerCoordinate = coordinate
            self.mapView.showAnnotations(self.mapView.annotations, animated: true)
        }
    }
    
    func validateUrl() {
        if webTextField.text != "" {
            self.mediaURL = webTextField.text!
            needsValidInput(false)
            showPin()
        } else {
            alertView(true, message: "        Please enter a URL")
        }
    }
        
    func postStudentLocation(mediaURL: String, latitude: Double, longitude: Double, completion: @escaping ([StudentLocation], Error?) -> Void) {
        
        alertView(true, message: "        Uploading Data")
        var request = URLRequest(url: OTMClient.Endpoints.studentLocation.url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = "{\"uniqueKey\": \"1234\", \"firstName\": \"Lois\", \"lastName\": \"Pewterschmidt\",\"mapString\": \"Providence, RI\", \"mediaURL\": \"\(mediaURL)\",\"latitude\": \(latitude), \"longitude\": \(longitude)}".data(using: .utf8)
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
          if error != nil {
            DispatchQueue.main.async {
                self.alertView(true, message: error as! String)
            }
          } else {
            DispatchQueue.main.async {
                self.alertView(false, message: "")
                self.dismiss(animated: true, completion: nil)
                }
            }
        }
        task.resume()
    }
    
    private func processResponse(withPlacemarks placemarks: [CLPlacemark]?, error: Error?) {
        // Based on Forward Geocoding tutorial on cocoacasts.com by Bart Jacobs
        alertView(false, message: "")
        if error != nil {
            alertView(true, message: "        Unable to Find Location")

        } else {
            var location: CLLocation?

            if let placemarks = placemarks, placemarks.count > 0 {
                location = placemarks.first?.location
            }

            if let location = location {
                let coordinate = location.coordinate
                self.latitude = coordinate.latitude
                self.longitude = coordinate.longitude
                validateUrl()
            } else {
                alertTextView.text = "        No Matching Location Found"
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            
            let reuseId = "pin"
            
            var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView

            if pinView == nil {
                pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
                pinView!.canShowCallout = true
                pinView!.pinTintColor = .orange
                pinView!.rightCalloutAccessoryView = UIButton(type: .roundedRect)
            }
            else {
                pinView!.annotation = annotation
            }
            return pinView
        }
    
    //MARK: - Actions
    @IBAction func cancelButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func findLocationButtonPressed(_ sender: Any) {
        guard let address = locationTextField.text else { return }
        
        geocoder.geocodeAddressString(address) { (placemarks, error) in
            self.processResponse(withPlacemarks: placemarks, error: error)
        }
    }
    
    @IBAction func finishButtonPressed(_ sender: Any) {
        postStudentLocation(mediaURL: mediaURL, latitude: latitude, longitude: longitude) { (newStudent, error) in
            DataModel.students = newStudent
        }
    }
    
}

