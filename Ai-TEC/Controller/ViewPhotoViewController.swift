import UIKit
import MapKit
import Toast_Swift
import Kingfisher
import Starscream
import MapViewPlus
protocol HandleMapSearch {
    func dropPinZoomIn(placemark: MKPlacemark)
}
@available(iOS 10.0, *)
class ViewPhotoViewController: UIViewController{
    

    @IBOutlet weak var mapView: MapViewPlus!
    @IBOutlet weak var photoImage: UIImageView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var timestampLabel: UILabel!
    
    var nameRemote = ""
    var photoUrl: URL?
    var hasGPS: Bool = false
    var photo: Image?
    var timestampCapture: String?
    var time: String?
    var currentLocation: CLLocation?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self

        let fileName = getDocumentsDirectory().appendingPathComponent("sample.kml").path
        
        do {
            // Read file content
            let contentFromFile = try NSString(contentsOfFile: fileName, encoding: String.Encoding.utf8.rawValue)
            print(contentFromFile)
            loadKml(contentFromFile as String)
        }
        catch let error as NSError {
            print("An error took place: \(error)")
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
    
    @IBAction func showEditButton(_ sender: UIButton) {
        CheckImage.shared.checkSend = false
        CheckImage.shared.checkRoite = false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showEditAfterViewSegueId" {
            if let editVc = segue.destination as? EditViewController {
                if let photo = photo {
                    editVc.screenShotImage = photo
                    editVc.nameRemote = nameRemote
                }
                editVc.isFirstEdit = false
                if let timestampCapture = timestampCapture {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
                    editVc.timestampCapture = dateFormatter.date(from: timestampCapture)
                }
            }
        }
    }
    
    // parse data to kml and get kml on the map
    fileprivate func loadKml(_ path: String) {
        KMLDocument.parse(string: path, callback: { [unowned self] (kml) in
            self.mapView.addOverlays(kml.overlays)
            self.mapView.setup(withAnnotations: AnotationMapView.shared.annotations)
        })
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    deinit {
        print("deinit")
    }
}

extension ViewPhotoViewController: MapViewPlusDelegate {

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let overlayPolyline = overlay as? KMLOverlayPolyline {
            // return MKPolylineRenderer
            return overlayPolyline.renderer()
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    
    func mapView(_ mapView: MapViewPlus, imageFor annotation: AnnotationPlus) -> UIImage {
        switch annotation.stringImage {
        case "0":
            return UIImage(named: "btn_answer")!
        case "1":
             return UIImage(named: "btn_cancel")!
        case "2":
             return UIImage(named: "btn_edit")!
        default:
            return  UIImage(named: "basic_annotation_image")!
        }
    }
    
    func mapView(_ mapView: MapViewPlus, didAddAnnotations annotations: [AnnotationPlus]) {
        mapView.showAnnotations(annotations, animated: true)
    }
    
}

@available(iOS 10.0, *)
extension ViewPhotoViewController: WebSocketDelegate {
    func websocketDidConnect(socket: WebSocket) {
        print("")
    }
    
    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        print(error ?? "")
    }
    
    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        let userData = UserDefaults(suiteName: UserDefaults.standard.string(forKey: "yourname"))
        let message: MessageSocket = MessageSocket(message: text)
        if message.type == functionSendImageUrl {
            var photosSender = userData?.stringArray(forKey: nameRemote)
            
            if photosSender == nil {
                photosSender = []
            }
            
            if let photo = message.url {
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
    
    func websocketDidReceiveData(socket: WebSocket, data: Data) {
        print(data)
    }
}
