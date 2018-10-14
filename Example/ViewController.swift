/**
	Copyright (C) 2016 Quentin Mathe
 
	Date:  August 2016
	License:  MIT
 */

import UIKit
import MapKit
import DistancePicker

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {

	@IBOutlet var distancePicker: DistancePicker!
	@IBOutlet var mapView: MKMapView!
	var searchRadiusOverlay: MKOverlay?
	var searchRadiusActive: Bool {
		return distancePicker.selectedValue != .greatestFiniteMagnitude && isValidAuthorizationStatus(authorizationStatus)
	}
	var authorizationStatus = CLAuthorizationStatus.notDetermined
	var locationManager = CLLocationManager()
	
	// MARK: - Configuration

	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Every time the user manipulates the distance picker, an action is 
		// sent when the pan animation stops. We use this opportunity to update
		// the map rect and search radius to match the selected distance.
		distancePicker.target = self
		distancePicker.action = #selector(updateUI)

		mapView.delegate = self
		mapView.isHidden = true

		locationManager.delegate = self
		locationManager.requestWhenInUseAuthorization()
	}

	func isValidAuthorizationStatus(_ status: CLAuthorizationStatus) -> Bool {
		// For iOS 7, AuthorizedAlways corresponds to Authorized
		return status == CLAuthorizationStatus.authorizedWhenInUse || status == CLAuthorizationStatus.authorizedAlways
	}

	func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
		authorizationStatus = status

		if isValidAuthorizationStatus(status) {
			mapView.showsUserLocation = true
		}
		updateUI()
	}
	
	// MARK: - Updating UI
	
    @IBAction func updateUI() {
		updateSearchRadiusOverlay()
		updateVisibleMapRect()
	}
	
	func updateSearchRadiusOverlay() {
		if let overlay = searchRadiusOverlay {
			mapView.remove(overlay)
			searchRadiusOverlay = nil
		}

		if searchRadiusActive {
			searchRadiusOverlay = MKCircle(center: mapView.userLocation.coordinate,
			                                         radius: distancePicker.selectedValue)
			mapView.add(searchRadiusOverlay!)
		}
	}
	
	func updateVisibleMapRect() {
		if searchRadiusActive {
			let overlayInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
			let mapRect = mapView.mapRectThatFits(searchRadiusOverlay!.boundingMapRect, edgePadding: overlayInset)

			mapView.setVisibleMapRect(mapRect, animated: false)
		}
		else if isValidAuthorizationStatus(authorizationStatus) {
			mapView.setCenter(mapView.userLocation.coordinate, animated: true)
		}
		// On launch, hide the map until we know the user location, otherwise 
		// the map is briefly centered on another location.
		mapView.isHidden = false
	}
	
	// MARK: - Map View Delegate
	
	func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
		updateUI()
	}
	
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKCircle {
            
            let circle = MKCircleRenderer(overlay: overlay)

            circle.strokeColor = UIColor.red
            circle.fillColor = UIColor.red.withAlphaComponent(0.1)
            circle.lineWidth = 1

            return circle
        }
		else {
			fatalError("Unexpected overlay type")
		}
    }
}

