//
//  ViewController.swift
//  Nearby
//
//  Created by Muhammad Moaz on 10/06/2016.
//  Copyright © 2016 Muhammad Moaz. All rights reserved.
//

import UIKit
import MapKit

class ListVC: UITableViewController, MKMapViewDelegate, UISearchResultsUpdating  {
    
    @IBOutlet weak var mapView: MKMapView?
    @IBOutlet weak var searchBarView: UIView?
    
    fileprivate let foursquareClient = FoursquareClient(clientID: "PTOSOZFGBEDLCKOBLPFYWNWRWAFQXOZPEZ25T5EKEVGW4P20", clientSecret: "B4GNDA5DUJNQWGWIQQFPNL11GA1OV3CM43D5NAWCOZAERZ0H")
    fileprivate var coordinate: Coordinate?
    fileprivate let searchController = UISearchController(searchResultsController: nil)
    fileprivate var locationManager = LocationManager()
    fileprivate var venues: [Venue] = [] {
        didSet {
            tableView.reloadData()
            addMapAnnotations()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        searchController.searchResultsUpdater = self
        searchController.hidesNavigationBarDuringPresentation = true
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "search nearby restaurants"
        definesPresentationContext = true
        searchBarView?.addSubview(searchController.searchBar)
        
        locationManager.getPermission()
        locationManager.onLocationUpdate = { coordinate in
            self.coordinate = coordinate
            self.fetchData()
        }
    }
    
    // MARK: - Table view Delegates and Datasource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.venues.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ListCell", for: indexPath) as! ListCell
        cell.venue = self.venues[(indexPath as NSIndexPath).row]
        return cell
    }
    
    // MARK: - Fetch
    
    func fetchData() {
        if let coordinate = coordinate {
            foursquareClient.fetchResturantsFor(coordinate, category: .food(nil)) { result in
                switch result {
                case .success(let venues):
                    self.venues = venues
                case .failure(let error):
                    print(error)
                }
            }
        }
    }
    
    // MARK: - Map View
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        var region = MKCoordinateRegion()
        region.center = mapView.userLocation.coordinate
        region.span.latitudeDelta = 0.01
        region.span.longitudeDelta = 0.01
        
        mapView.setRegion(region, animated: true)
    }
    
    func addMapAnnotations() {
        removeMapAnnotations()
        
        if venues.count > 0 {
            let annotations: [MKPointAnnotation] = venues.map { venue in
                let point = MKPointAnnotation()
                
                if let coordinate = venue.location?.coordinate {
                    point.coordinate = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
                    point.title = venue.name
                }
                
                return point
            }
            
            mapView?.addAnnotations(annotations)
        }
    }
    
    func removeMapAnnotations() {
        if mapView?.annotations.count != 0 {
            for annotation in mapView!.annotations {
                mapView?.removeAnnotation(annotation)
            }
        }
    }
    
    // MARK: - Search
    func updateSearchResults(for searchController: UISearchController) {
        if let coordinate = coordinate {
            foursquareClient.fetchResturantsFor(coordinate, category: .food(nil), query: searchController.searchBar.text) { result in
                switch result {
                case .success(let venues):
                    self.venues = venues
                case .failure(let error):
                    print(error)
                }
            }
        }
    }
    
    @IBAction func refreshData(_ sender: AnyObject) {
        fetchData()
        refreshControl?.endRefreshing()
    }
}

