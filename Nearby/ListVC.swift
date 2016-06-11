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
    @IBOutlet weak var headerStackView: UIStackView?
    
    private let foursquareClient = FoursquareClient(clientID: "PTOSOZFGBEDLCKOBLPFYWNWRWAFQXOZPEZ25T5EKEVGW4P20", clientSecret: "B4GNDA5DUJNQWGWIQQFPNL11GA1OV3CM43D5NAWCOZAERZ0H")
    private var coordinate: Coordinate?
    private let searchController = UISearchController(searchResultsController: nil)
    private var locationManager = LocationManager()
    private var venues: [Venue] = [] {
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
        definesPresentationContext = true
        headerStackView?.addSubview(searchController.searchBar)
        
        locationManager.getPermission()
        locationManager.onLocationUpdate = { coordinate in
            self.coordinate = coordinate
            self.fetchData()
        }
    }
    
    // MARK: - Table view Delegates and Datasource
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.venues.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ListCell", forIndexPath: indexPath) as! ListCell
        cell.venue = self.venues[indexPath.row]
        return cell
    }
    
    // MARK: - Fetch
    
    func fetchData() {
        if let coordinate = coordinate {
            foursquareClient.fetchResturantsFor(coordinate, category: .Food(nil)) { result in
                switch result {
                case .Success(let venues):
                    self.venues = venues
                case .Failure(let error):
                    print(error)
                }
            }
        }
    }
    
    // MARK: - Map View
    
    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {
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
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        if let coordinate = coordinate {
            foursquareClient.fetchResturantsFor(coordinate, category: .Food(nil), query: searchController.searchBar.text) { result in
                switch result {
                case .Success(let venues):
                    self.venues = venues
                case .Failure(let error):
                    print(error)
                }
            }
        }
    }
    
    @IBAction func refreshData(sender: AnyObject) {
        fetchData()
        refreshControl?.endRefreshing()
    }
}

