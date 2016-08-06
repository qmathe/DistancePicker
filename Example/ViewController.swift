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
		return distancePicker.selectedValue != DBL_MAX && isValidAuthorizationStatus(authorizationStatus)
	}
	var authorizationStatus = CLAuthorizationStatus.NotDetermined
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
		mapView.hidden = true

		locationManager.delegate = self
		locationManager.requestWhenInUseAuthorization()
	}

	func isValidAuthorizationStatus(status: CLAuthorizationStatus) -> Bool {
		// For iOS 7, AuthorizedAlways corresponds to Authorized
		return status == CLAuthorizationStatus.AuthorizedWhenInUse || status == CLAuthorizationStatus.AuthorizedAlways
	}

	func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
		authorizationStatus = status

		if isValidAuthorizationStatus(status) {
			mapView.showsUserLocation = true
		}
		updateUI()
	}
	
	// MARK: - Updating UI
	
	func updateUI() {
		updateSearchRadiusOverlay()
		updateVisibleMapRect()
	}
	
	func updateSearchRadiusOverlay() {
		if let overlay = searchRadiusOverlay {
			mapView.removeOverlay(overlay)
			searchRadiusOverlay = nil
		}

		if searchRadiusActive {
			searchRadiusOverlay = MKCircle(centerCoordinate: mapView.userLocation.coordinate,
			                                         radius: distancePicker.selectedValue)
			mapView.addOverlay(searchRadiusOverlay!)
		}
	}
	
	func updateVisibleMapRect() {
		if searchRadiusActive {
			let overlayInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
			let mapRect = mapView.mapRectThatFits(searchRadiusOverlay!.boundingMapRect, edgePadding: overlayInset)

			mapView.setVisibleMapRect(mapRect, animated: false)
		}
		else if isValidAuthorizationStatus(authorizationStatus) {
			mapView.setCenterCoordinate(mapView.userLocation.coordinate, animated: true)
		}
		// On launch, hide the map until we know the user location, otherwise 
		// the map is briefly centered on another location.
		mapView.hidden = false
	}
	
	// MARK: - Map View Delegate
	
	func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {
		updateUI()
	}
	
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKCircle {
            let circle = MKCircleRenderer(overlay: overlay)

            circle.strokeColor = UIColor.redColor()
            circle.fillColor = UIColor.redColor().colorWithAlphaComponent(0.1)
            circle.lineWidth = 1

            return circle
        }
		else {
			fatalError("Unexpected overlay type")
		}
    }
}

