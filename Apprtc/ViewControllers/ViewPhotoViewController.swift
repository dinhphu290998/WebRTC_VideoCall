//
//  ViewPhotoViewController.swift
//  Apprtc
//
//  Created by vmio69 on 2/2/18.
//  Copyright © 2018 Dhilip. All rights reserved.
//

import UIKit
import GoogleMaps
import Toast_Swift
import SocketRocket
import Kingfisher

class ViewPhotoViewController: SocketViewController {

  @IBOutlet weak var mapView: GMSMapView!
  @IBOutlet weak var photoImageView: UIImageView!
  @IBOutlet weak var segmentedControl: UISegmentedControl!
  @IBOutlet weak var timestampLabel: UILabel!

  var photoUrl: URL?
  var hasGPS: Bool = false
  var photo: Image?
  var timestampCapture: String?

  override func viewDidLoad() {
    super.viewDidLoad()

    if let url = photoUrl {
      timestampCapture = url.timestampCaptured
      ImageDownloader.default.downloadImage(with: url, retrieveImageTask: nil, options: [], progressBlock: nil,
                                            completionHandler: { (image, _, _, data) in
        self.photo = image
        self.photoImageView.image = image

        if  let data = data,
          let exif = self.getEXIFFromImage(image: data) as? [String: Any],
          let gps = exif["{GPS}"] as? NSDictionary,
          let longitudeRef = gps["LongitudeRef"] as? String,
          let latitudeRef = gps["LatitudeRef"] as? String,
          let longitude = gps["Longitude"] as? Double,
          let latitude = gps["Latitude"] as? Double {
          let coordinate = CLLocationCoordinate2D(latitude: latitudeRef == "N" ? latitude : -latitude,
                                                  longitude: longitudeRef == "E" ? longitude : -longitude)
          let marker = GMSMarker()

          let camera = GMSCameraPosition.camera(withLatitude: latitude, longitude: longitude, zoom: 15)

          self.mapView.camera = camera
          marker.position = coordinate
          marker.map = self.mapView
          self.hasGPS = true
        } else {
          self.hasGPS = false
        }
      })
      timestampLabel.text = url.timestampCaptured
    } else {
      photoImageView.image = nil
      timestampLabel.text = ""
      hasGPS = false
    }
    mapView.isHidden = segmentedControl.selectedSegmentIndex == 0
//    socket?.delegate = self
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  @IBAction func backButtonTouched(_ sender: Any) {
    dismiss(animated: true, completion: nil)
  }

  @IBAction func segmentedControlChanged(_ sender: Any) {
    if segmentedControl.selectedSegmentIndex == 0 {
      mapView.isHidden = true
    } else {
      mapView.isHidden = false
      if !hasGPS {
        self.view.makeToast("Can't get GPS data")
      }
    }
  }

  override var prefersStatusBarHidden: Bool {
    return true
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "showEditAfterViewSegueId" {
      let editVc = segue.destination as? EditViewController
      if  let photo = photo {
        editVc?.screenShotImage = photo
      }
      editVc?.callingInfo = callingInfo
      editVc?.isFirstEdit = false

      if let timestampCapture = timestampCapture {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
        editVc?.timestampCapture = dateFormatter.date(from: timestampCapture)
      }
    }
  }

}

extension ViewPhotoViewController {
  override func webSocket(_ webSocket: SRWebSocket!, didReceiveMessage message: Any!) {
    super.webSocket(webSocket, didReceiveMessage: message)
  }
}
