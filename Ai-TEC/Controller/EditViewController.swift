//
//  EditViewController.swift
//  Ai-Tec
//
//  Created by vMio on 10/30/18.
//  Copyright © 2018 vMio. All rights reserved.
//

import UIKit
import DropDown
import Material
import AVFoundation
import SVProgressHUD
import Alamofire
import Toast_Swift
import GoogleMaps
import MobileCoreServices
import SocketRocket
import Starscream
class EditViewController: UIViewController {
   
    
    weak var paletteView: Palette?
    weak var canvasView: Canvas?
    var nameRemote = ""
    var colorDropDown: DropDown?
    var widthDropDown: DropDown?
    var colorSelectedView: UIView?
    var widthSelectedView: UIView?
    var screenShotImage: UIImage?
    var currentLocation: CLLocation?
    var locationManager: CLLocationManager = CLLocationManager()
    
    var timestampCapture: Date?
    var isFirstEdit: Bool = true
    @IBOutlet weak var toolbarView: UIView!
    @IBOutlet weak var colorButton: UIButton!
    @IBOutlet weak var widthButton: UIButton!
    @IBOutlet weak var eraerButton: UIButton!
    @IBOutlet weak var sendImageButton: UIButton!
    @IBOutlet weak var photoImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        setupCanvas()
        setupPalette()
        setupToolDrawView()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        
        SocketGlobal.shared.socket?.delegate = self
    }
    
 
    fileprivate func setupPalette() {
        let paletteView = Palette()
        paletteView.setup()
        self.view.addSubview(paletteView)
        self.paletteView = paletteView
        let paletteHeight = paletteView.paletteHeight()
        paletteView.frame = CGRect(x: 0, y: 96, width: self.view.frame.width, height: paletteHeight)
        
    }
    
    // gán ảnh cho view
    
    fileprivate func setupCanvas() {
        let sizeView = self.view.frame.size
        let width = min(sizeView.width, sizeView.height)
        let heidht = max(sizeView.width, sizeView.height)
        
        let canvasView = Canvas(backgroundImage: screenShotImage)
        print(screenShotImage?.size ?? "")
        canvasView.frame = CGRect(x: 0, y: 96, width: width, height: heidht - 172)
        canvasView.delegate = self
        canvasView.clipsToBounds = true
        
        self.view.addSubview(canvasView)
        self.canvasView = canvasView
    }
    
    
    // thanh màu
    
    fileprivate func setupToolDrawView() {
        var width = min(UIScreen.main.bounds.height, UIScreen.main.bounds.width)
        width = (width - 6*16 - 38*2)/2
        colorSelectedView = UIView()
        colorButton.addSubview(colorSelectedView!)
        colorSelectedView?.frame = CGRect(x: 3, y: 3, width: width - 36, height: 38)
        colorSelectedView?.backgroundColor = .red
        colorButton.layer.borderWidth = 1
        colorButton.layer.borderColor = UIColor.black.cgColor
        
        let colorLine = UIView()
        colorButton.addSubview(colorLine)
        colorLine.frame = CGRect(x: width - 30, y: 0, width: 1, height: 44)
        colorLine.backgroundColor = UIColor.black
        let colorGesture = UITapGestureRecognizer(target: self, action: #selector(showColorPicker))
        colorSelectedView?.addGestureRecognizer(colorGesture)
        let colorClearImageView = UIImageView(image: UIImage(named: "icon_eraser"))
        colorButton.addSubview(colorClearImageView)
        colorClearImageView.frame = (colorSelectedView?.frame)!
        colorClearImageView.contentMode = .scaleAspectFill
        colorClearImageView.clipsToBounds = true
        colorButton.bringSubview(toFront: colorSelectedView!)
        
        
        widthSelectedView = UIView()
        widthButton.addSubview(widthSelectedView!)
        widthSelectedView?.frame = CGRect(x: 3, y: 17, width: width - 36, height: 10)
        widthSelectedView?.backgroundColor = .black
        widthButton.layer.borderWidth = 1
        widthButton.layer.borderColor = UIColor.black.cgColor
        let widthLine = UIView()
        widthButton.addSubview(widthLine)
        widthLine.frame = CGRect(x: width - 30, y: 0, width: 1, height: 44)
        widthLine.backgroundColor = UIColor.black
        let widthGesture = UITapGestureRecognizer(target: self, action: #selector(showWidthPicker))
        widthSelectedView?.addGestureRecognizer(widthGesture)
        
        let colors = [UIColor.init(red: 252/255.0, green: 13/255.0, blue: 36/255.0, alpha: 1.0),
                      UIColor.init(red: 254/255.0, green: 230/255.0, blue: 97/255.0, alpha: 1.0),
                      UIColor.init(red: 39/255.0, green: 244/255.0, blue: 86/255.0, alpha: 1.0),
                      UIColor.init(red: 88/255.0, green: 161/255.0, blue: 237/255.0, alpha: 1.0),
                      UIColor.init(red: 136/255.0, green: 15/255.0, blue: 125/255.0, alpha: 1.0),
                      UIColor.init(red: 252/255.0, green: 50/255.0, blue: 128/255.0, alpha: 1.0)
        ]
        if let color = colors.first {
            self.brush()?.color = color
            colorSelectedView?.backgroundColor = color
        }
        
        colorDropDown = DropDown()
        colorDropDown?.anchorView = colorButton
        colorDropDown?.dataSource = ["", "", "", "", "", ""]
        colorDropDown?.selectionAction = { [weak self] (index: Int, item: String) in
            self?.brush()?.color = colors[index]
            self?.changeBrushColor(color: colors[index])
        }
        colorDropDown?.cellNib = UINib(nibName: "BrushCell", bundle: nil)
        colorDropDown?.customCellConfiguration = { (index: Index, item: String, cell: DropDownCell) in
            guard let cell = cell as? BrushCell else {
                return
            }
            cell.setBrush(color: colors[index], width: 80)
        }
        colorDropDown?.bottomOffset = CGPoint(x: 0, y: colorButton.frame.size.height)
        if let colorButton = colorButton {
            colorButton.addTarget(self, action: #selector(showColorPicker), for: .touchUpInside)
        }
        widthDropDown = DropDown()
        widthDropDown?.anchorView = widthButton
        widthDropDown?.dataSource = ["", "", "", "", "", ""]
        widthDropDown?.bottomOffset = CGPoint(x: 0, y: widthButton.frame.size.height)
        widthDropDown?.selectionAction = { [weak self] (index: Int, item: String) in
            self?.brush()?.width = CGFloat((index+1)*(2+index))
            self?.changeBrushWidth(brushWidth: CGFloat((index+1)*(2+index)))
        }
        widthDropDown?.cellNib = UINib(nibName: "BrushCell", bundle: nil)
        widthDropDown?.customCellConfiguration = { (index: Index, item: String, cell: DropDownCell) in
            guard let cell = cell as? BrushCell else {
                return
            }
            cell.setBrush(color: .black, width: Float((index+1)*(2+index)))
        }
        if let widthButton = widthButton {
            widthButton.addTarget(self, action: #selector(showWidthPicker), for: .touchUpInside)
        }
        self.brush()?.width = 20
        changeBrushWidth(brushWidth: 20)
        
        self.view.bringSubview(toFront: toolbarView)
        
    }
    
    @objc fileprivate func showColorPicker() {
        colorDropDown?.show()
    }
    
    @objc fileprivate func showWidthPicker() {
        widthDropDown?.show()
    }
    
    @objc func changeBrushColor(color: UIColor) {
        colorSelectedView?.backgroundColor = color
    }
    
    @objc func changeBrushWidth(brushWidth: CGFloat) {
        var width = min(Screen.height, Screen.width)
        width = (width - 6*16 - 38*2)/2
        widthSelectedView?.frame = CGRect(x: 3, y: 22 - brushWidth/4, width: width - 36, height: brushWidth/2)
    }
    
    @IBAction func eraserButtonTouched(_ sender: Any) {
        self.brush()?.color = .clear
        changeBrushColor(color: .clear)
    }
    
    @IBAction func resetButtonTouched(_ sender: Any) {
        self.canvasView?.clear()
        
    }
    @IBAction func backButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    @IBAction func undoButton(_ sender: Any) {
        self.canvasView?.undo()
    }
    @IBAction func sendImage(_ sender: Any) {
        self.canvasView?.save()
        
        
        
    }
    
    
    // convert string to dictionary
    func convertToDictionary(from text: String) throws -> [String: String]? {
        guard let data = text.data(using: .utf8) else { return [:] }
        let anyResult: Any = try JSONSerialization.jsonObject(with: data, options: [])
        return anyResult as? [String: String]
    } 
    //convert dictionary to string
    func convertString(from dict:[String:String]) -> String {
        let jsonData = try! JSONSerialization.data(withJSONObject: dict, options: JSONSerialization.WritingOptions.prettyPrinted)
        let jsonString = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)! as String
        return jsonString
    }
    


    
 

    
}
extension EditViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = manager.location
    }
    
}
extension EditViewController: CanvasDelegate {
    func brush() -> Brush? {
        return self.paletteView?.currentBrush()
    }
    
    func canvas(_ canvas: Canvas, didSaveDrawing drawing: Drawing, mergedImage image: UIImage?) {
        SVProgressHUD.show()
        guard let data = UIImageJPEGRepresentation(screenShotImage!, 0.9) else {
            return
        }
        
        Alamofire.upload(multipartFormData: { (form) in
            form.append(data, withName: "data", fileName: "file.jpg", mimeType: "image/jpeg")
        }, to: apiSendImage, encodingCompletion: { result in
            switch result {
            case .success(let upload, _, _):
                upload.responseString { response in
                    print(response.result.value ?? "")
                    SVProgressHUD.dismiss()
                }
            case .failure(let encodingError):
                print(encodingError)
            }
        })
        let oldEXIF = getEXIFFromImage(image: data)
        var attached = data
        if isFirstEdit {
            if let gpsDict = currentLocation?.getGPSDictionary() {
                let newEXIF = addInfoToEXIF(old: oldEXIF, gps: gpsDict, dateCapture: self.timestampCapture)
                attached = attachEXIFToImage(image: attached as NSData, EXIF: newEXIF) as Data
                print("newEXIF: \(newEXIF)")
            } else {
                SVProgressHUD.showError(withStatus: "Can't send image. Please check GPS")
                return
            }
        } else {
            let newEXIF = addInfoToEXIF(old: oldEXIF, gps: nil, dateCapture: timestampCapture)
            attached = attachEXIFToImage(image: attached as NSData, EXIF: newEXIF) as Data
            print("newEXIF: \(newEXIF)")
        }
        
        let dict = ["type" : "sendFile" , "receive" : nameRemote , "url" : "data/file.jpg"]
        SocketGlobal.shared.socket?.write(string: convertString(from: dict))
        print(dict)
        
       
        
    }

}




extension EditViewController {
  public func getEXIFFromImage(image: Data) -> NSDictionary {
    if let imageSourceRef = CGImageSourceCreateWithData(image as CFData, nil),
      let currentProperties = CGImageSourceCopyPropertiesAtIndex(imageSourceRef, 0, nil) {
      let mutableDict = NSMutableDictionary(dictionary: currentProperties)
      return mutableDict
    }
    return NSDictionary()
  }

  public func attachEXIFToImage(image: NSData, EXIF: NSDictionary) -> NSData {
    if let imageDataProvider = CGDataProvider(data: image),
      let imageRef = CGImage(jpegDataProviderSource: imageDataProvider,
                             decode: nil, shouldInterpolate: true,
                             intent: CGColorRenderingIntent.defaultIntent),
      let newImageData = CFDataCreateMutable(nil, 0),
      let type = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType,
                                                       "image/jpg" as CFString, kUTTypeImage),
      let destination = CGImageDestinationCreateWithData(newImageData,
                                                         type.takeRetainedValue(), 1, nil) {
      CGImageDestinationAddImage(destination, imageRef, EXIF as CFDictionary)
      CGImageDestinationFinalize(destination)
      return newImageData as NSData
    }

    return NSData()
  }
    public func addInfoToEXIF(old: NSDictionary, gps: NSDictionary?, dateCapture: Date?) -> NSDictionary {
        if let gps = gps {
            old.setValue(gps, forKey: kCGImagePropertyGPSDictionary as String)
        }
        
        if let exifData = old.value(forKey: kCGImagePropertyExifDictionary as String) as? NSDictionary,
            let timestampCapture = dateCapture {
            let dfExif = DateFormatter()
            dfExif.locale = Locale(identifier: "en_POSIX_US")
            dfExif.timeZone = TimeZone.current
            dfExif.dateFormat = "yyyy:MM:dd HH:mm:ss"
            
            exifData.setValue(dfExif.string(from: timestampCapture),
                              forKey: kCGImagePropertyExifDateTimeOriginal as String)
            exifData.setValue(dfExif.string(from: timestampCapture),
                              forKey: kCGImagePropertyExifDateTimeDigitized as String)
            
            old.setValue(exifData, forKey: kCGImagePropertyExifDictionary as String)
        }
        
        if let exifData = old.value(forKey: kCGImagePropertyTIFFDictionary as String) as? NSDictionary,
            let timestampCapture = dateCapture {
            let dfExif = DateFormatter()
            dfExif.locale = Locale(identifier: "en_POSIX_US")
            dfExif.timeZone = TimeZone.current
            dfExif.dateFormat = "yyyy:MM:dd HH:mm:ss"
            
            exifData.setValue(dfExif.string(from: timestampCapture),
                              forKey: kCGImagePropertyTIFFDateTime as String)
            
            old.setValue(exifData, forKey: kCGImagePropertyTIFFDictionary as String)
        }
        
        return old
    }
}



extension EditViewController: WebSocketDelegate {
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
                if message.url != nil {
                    let url = "\(urlHostHttp)data/file.jpg"
                    photosSender?.append(url)
                    userData?.set(photosSender, forKey: nameRemote)
                }
                
                let alert = UIAlertController(title: "お知らせ",
                                              message: "画像を受信しました。確認しますか？\n後でギャラリーにて確認する事も出来ます。",
                                              preferredStyle: .alert)
                let openAction = UIAlertAction(title: "開く", style: .default, handler: { (_) in
                    //                        self.performSegue(withIdentifier: "showAlbumSegueId", sender: self)
                  
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