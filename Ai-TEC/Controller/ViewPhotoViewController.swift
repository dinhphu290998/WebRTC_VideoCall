//
//  ViewPhotoViewController.swift
//  Ai-Tec
//
//  Created by vMio on 10/31/18.
//  Copyright © 2018 vMio. All rights reserved.
//

import UIKit
import MapKit
import GoogleMaps
import Toast_Swift
import Kingfisher
import Starscream
import Alamofire
protocol HandleMapSearch {
    func dropPinZoomIn(placemark: MKPlacemark)
}
class ViewPhotoViewController: UIViewController, GMSMapViewDelegate{

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photoImage: UIImageView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var timestampLabel: UILabel!
    
    let noLocation = CLLocationCoordinate2D()
    var locationManager = CLLocationManager()
    var reconMapview: GMSMapView?
    var selectedPin: MKPlacemark? = nil
    
    var nameRemote = ""
    var photoUrl: URL?
    var hasGPS: Bool = false
    var photo: Image?
    var timestampCapture: String?
    var time: String?
    override func viewDidLoad() {
        super.viewDidLoad()
     
        mapView.delegate = self
        mapView.showsUserLocation = true
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        
        DispatchQueue.main.async {
            self.locationManager.startUpdatingLocation()
        }
     
        if let url = photoUrl {
            timestampCapture = url.timestampCaptured
            ImageDownloader.default.downloadImage(with: url, retrieveImageTask: nil, options: [], progressBlock: nil, completionHandler: { (image, _, _, data) in
                self.photo = image
                self.photoImage.image = image
            })
            timestampLabel.text = url.timestampCaptured
        } else {
            photoImage.image = nil
            timestampLabel.text = ""
            hasGPS = false
        }
        mapView.isHidden = segmentedControl.selectedSegmentIndex == 0
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        SocketGlobal.shared.socket?.delegate = self
    }
    
    @objc func getDirections() {
        if let selectedPin = selectedPin {
            let mapItem = MKMapItem(placemark: selectedPin)
            let lauchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
            mapItem.openInMaps(launchOptions: lauchOptions)
        }
    }
    @IBAction func backButtonTouched(_ sender: Any) {
        self.performSegue(withIdentifier: "unwindToVideochatSegueId", sender: self)
    }
    
    @IBAction func segmentedControlChanged(_ sender: Any) {
        if segmentedControl.selectedSegmentIndex == 0 {
            mapView.isHidden = true
            if !hasGPS {
                self.view.makeToast("Can't get GPS data")
            }
         } else {
            mapView.isHidden = false
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showEditAfterViewSegueId" {
            if let editVc = segue.destination as? EditViewController {
                if let photo = photo {
                    editVc.screenShotImage = photo
                    editVc.nameRemote = nameRemote
                }
                editVc.isFirstEdit = false
            }
        }
    }
    
    deinit {
        print("deinit ViewPhotoViewController -------------------------------:)")
    }

}
extension ViewPhotoViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.requestLocation()
        }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last
        let center = CLLocationCoordinate2D(latitude: location!.coordinate.latitude, longitude: location!.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
        mapView.setRegion(region, animated: true)
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("error: \(error)")
    }
    
}
extension ViewPhotoViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        let reuseID = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID) as? MKPinAnnotationView
        pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
        pinView?.pinTintColor = UIColor.red
        pinView?.canShowCallout = true
        let smallSquare = CGSize(width: 30, height: 30)
        let button = UIButton(frame: CGRect(origin: CGPoint.zero, size: smallSquare))
        button.addTarget(self, action: #selector(getDirections), for: .touchUpInside)
        pinView?.leftCalloutAccessoryView = button
        return pinView
    }
}
extension ViewPhotoViewController: HandleMapSearch {
    func dropPinZoomIn(placemark: MKPlacemark) {
        selectedPin = placemark
        // clear existing pins
        mapView.removeAnnotations(mapView.annotations)
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        annotation.title = placemark.name
        if let city = placemark.locality,
            let state = placemark.administrativeArea {
            annotation.subtitle = "\(city) \(state)"
        }
        mapView.addAnnotation(annotation)
        let span = MKCoordinateSpanMake(0.05, 0.05)
        let region = MKCoordinateRegionMake(placemark.coordinate, span)
        mapView.setRegion(region, animated: true)
    }
}

extension ViewPhotoViewController: WebSocketDelegate {
    func websocketDidConnect(socket: WebSocket) {
        print("")
    }
    
    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        print(error ?? "")
    }
    
    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        if let messageString: String = text {
            print(messageString)
            let userData = UserDefaults(suiteName: UserDefaults.standard.string(forKey: "yourname"))
            let message: MessageSocket = MessageSocket(message: messageString)
            if message.type == functionSendImageUrl {
                var photosSender = userData?.stringArray(forKey: nameRemote)
                if photosSender == nil {
                    photosSender = []
                }
                if let photo = message.url  {
                    let url = "\(urlHostHttp)data/\(photo)"
                    photosSender?.append(url)
                    userData?.set(photosSender, forKey: nameRemote)
                }
                
                let alert = UIAlertController(title: "お知らせ",
                                              message: "画像を受信しました。確認しますか？\n後でギャラリーにて確認する事も出来ます。",
                                              preferredStyle: .alert)
                let openAction = UIAlertAction(title: "開く", style: .default, handler: { (_) in
                    
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    if let vc = storyboard.instantiateViewController(withIdentifier: "AlbumViewControllerId")
                        as? AlbumViewController {
                        vc.nameRemote = self.nameRemote
                        self.present(vc, animated: true, completion: nil)
                    }
                })
                
                let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel, handler: nil)
                alert.addAction(openAction)
                alert.addAction(cancelAction)
                present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func websocketDidReceiveData(socket: WebSocket, data: Data) {
        print(data)
    }
}
