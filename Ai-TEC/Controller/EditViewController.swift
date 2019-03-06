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
import MobileCoreServices
import SocketRocket
import Starscream
import CoreLocation
import Zip
import MapViewPlus
class EditViewController: UIViewController {
    weak var paletteView: Palette?
    weak var canvasView: Canvas?
    var nameRemote = ""
    var colorDropDown: DropDown?
    var widthDropDown: DropDown?
    var colorSelectedView: UIView?
    var widthSelectedView: UIView?
    var screenShotImage: UIImage?
    var times: String?
    var timestampCapture: Date?
    
    var drawLines = Double()
    var isFirstEdit: Bool = true
    
    var currentLocation: CLLocation?
    var locationManager: CLLocationManager = CLLocationManager()
     let kml = KML.shared
    @IBOutlet weak var toolbarView: UIView!
    @IBOutlet weak var colorButton: UIButton!
    @IBOutlet weak var widthButton: UIButton!
    @IBOutlet weak var eraerButton: UIButton!
    @IBOutlet weak var sendImageButton: UIButton!
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var dismisButton: UIButton!
    @IBOutlet weak var sendButton: UIButton!
    
    fileprivate var gridWidthMultiple: CGFloat {
        return 5
    }
    
    fileprivate var gridWidth: CGFloat
    {
        return view.bounds.width/CGFloat(gridWidthMultiple)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sendImageButton.layer.cornerRadius = 6
        undoButton.layer.cornerRadius = 6
        dismisButton.layer.cornerRadius = 6
        
        // Get the current location of the user
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        
        setupCanvas()
        setupPalette()
        setupToolDrawView()
        
        if CheckImage.shared.check == true {
            canvasView?.strokeImage(rotate: drawLines)
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
    
    // After the user clicks the capture button the image will be assigned to the view to draw at the edit
    fileprivate func setupCanvas() {
        let sizeView = self.view.frame.size
        let width = min(sizeView.width, sizeView.height)
        let heidht = max(sizeView.width, sizeView.height)
        
        let canvasView = Canvas(backgroundImage: screenShotImage)
            print(screenShotImage?.size ?? "")
        
            canvasView.frame = CGRect(x: 0, y: 115, width: width, height: heidht - 210)
            canvasView.delegate = self
            canvasView.clipsToBounds = true
        
            self.view.addSubview(canvasView)
            self.canvasView = canvasView
    }
    
    // width of colors and different colors
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
            colorClearImageView.frame = (colorSelectedView?.frame)!
            colorClearImageView.contentMode = .scaleAspectFill
            colorClearImageView.clipsToBounds = true
            colorButton.bringSubview(toFront: colorSelectedView!)
            colorButton.addSubview(colorClearImageView)
        
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
                      UIColor.init(red: 252/255.0, green: 50/255.0, blue: 128/255.0, alpha: 1.0)]
        
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
    
    // events
    // xoá
    @IBAction func eraserButtonTouched(_ sender: Any) {
        self.brush()?.color = .clear
        changeBrushColor(color: .clear)
    }
    
    //.. xoá tất cả
    @IBAction func resetButtonTouched(_ sender: Any) {
        self.canvasView?.clear()
    }
    
    @IBAction func backButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    // xoá từng cái
    @IBAction func undoButton(_ sender: Any) {
        self.canvasView?.undo()
    }
    
    // gửi và lưu ảnh
    @IBAction func sendImage(_ sender: Any) {
        self.canvasView?.save()
        dismiss(animated: true, completion: nil)
    }
    // convert string to dictionary
    func convertToDictionary(from text: String) throws -> [String: Any]? {
        guard let data = text.data(using: .utf8) else { return [:] }
        let anyResult: Any = try JSONSerialization.jsonObject(with: data, options: [])
        return anyResult as? [String: Any]
    }
    
    //convert dictionarySS to string
    func convertString(from dict:[String:String]) -> String {
        let jsonData = try! JSONSerialization.data(withJSONObject: dict, options: JSONSerialization.WritingOptions.prettyPrinted)
        let jsonString = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)! as String
        return jsonString
    }
    //convert dictionarySA to string
    func convertStringSA(from dict:[String:Any]) -> String {
        let jsonData = try! JSONSerialization.data(withJSONObject: dict, options: JSONSerialization.WritingOptions.prettyPrinted)
        let jsonString = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)! as String
        return jsonString
    }
}

extension EditViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = manager.location
    }
}

// save and upload image to server
extension EditViewController: CanvasDelegate {
    
    func brush() -> Brush? {
        return self.paletteView?.currentBrush()
    }
    
    func canvas(_ canvas: Canvas, didSaveDrawing drawing: Drawing, mergedImage image: UIImage?) {
        SVProgressHUD.show(withStatus: "sending....")
        if CheckImage.shared.checkSend == false {
            currentLocation = locationManager.location
            AnotationMapView.shared.annotations.append(AnnotationPlus.init(viewModel: DefaultCalloutViewModel(title: "Send File"), coordinate: CLLocationCoordinate2DMake(currentLocation!.coordinate.latitude, currentLocation!.coordinate.longitude), stringImage: "2"))
            kml.sendImage()
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmss"
        let myString = formatter.string(from: Date())
        let yourDate = formatter.date(from: myString)
        let myStrongafd = formatter.string(from: yourDate!)
        times = myStrongafd
        
        //creat file kml zip
        let fileName = getDocumentsDirectory().appendingPathComponent("sample.kml")
        do {
            let _ = try Zip.quickZipFiles([fileName], fileName: "kml")
        } catch  {
            print("error")
        }
        
        // convert file kml zip to bytes
        let fileNameZip = getDocumentsDirectory().appendingPathComponent("kml.zip")
        var byteZip = [UInt8]()
        if let dataZip = NSData(contentsOf: fileNameZip) {
            var bufferZip = [UInt8](repeating: 0, count: dataZip.length)
            dataZip.getBytes(&bufferZip, length: dataZip.length)
            byteZip = bufferZip
        }
        
        
        if let data = image?.asJPEGData(1),
            let imageNameFile = getImageNameFile(nameRemote: nameRemote) {
            
            // add image to bytes
            let bytesImage = [UInt8](data)
            
            //bytesImage and kml
            let bytesImageKml = NSMutableData()
            bytesImageKml.append(bytesImage, length: bytesImage.count)
            bytesImageKml.append(byteZip, length: byteZip.count)
            // save bytes to local
            let fileNameBytes = getDocumentsDirectory().appendingPathComponent("ImageKml.jpg")
            bytesImageKml.write(to: fileNameBytes, atomically: true)

            // upload image to server
            Alamofire.upload(multipartFormData: { (form) in
                form.append(fileNameBytes, withName: "data", fileName: "\(imageNameFile)", mimeType: "image/jpeg")
            }, to: apiSendImage, encodingCompletion: { result in
                switch result {
                case .success(let upload, _, _):
                    upload.responseString { response in
                        print(response.result.value ?? "")
                        if let valueString = response.result.value {
                            let value = try! self.convertToDictionary(from: valueString)
                            guard let urlImage = value!["image"] as? String else{return}
                            //send pictures to the same caller
                            let dict = ["type" : "sendFile" , "receive" : self.nameRemote , "url" : "\(urlImage)"]
                            SocketGlobal.shared.socket?.write(string: self.convertString(from: dict))
                            print(dict)
                        }
                        SVProgressHUD.dismiss()
                    }
                case .failure(let encodingError):
                    print(encodingError)
                    DispatchQueue.main.async {
                        SVProgressHUD.dismiss()
                        SVProgressHUD.showError(withStatus: "Can't send image")
                    }
                }
            })
            
            
        }
    }
}

extension EditViewController: WebSocketDelegate {
    func websocketDidConnect(socket: WebSocket) {
        print("--- Message EditViewcontroller ---")
    }
    
    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        print(error ?? "")
    }
    
    // Receive a message after the sender has sent
    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
            let userData = UserDefaults(suiteName: UserDefaults.standard.string(forKey: "yourname"))
            let message: MessageSocket = MessageSocket(message: text)
            if message.type == functionSendImageUrl {
                var photosSender = userData?.stringArray(forKey: nameRemote)
                
                if photosSender == nil {
                    photosSender = []
                }
                
                if let photo = message.url {
                    let url = photo
                    print("--------\(url)---------")
                    photosSender?.append(url)
                    userData?.set(photosSender, forKey: nameRemote)
                }
                
                //after the other party receives a notice
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

extension EditViewController {
    func getImageNameFile(nameRemote: String) -> String? {
        if let timestamCapture = timestampCapture?.fileNameFromeDate {
            var imageNameFile: String
            imageNameFile = "\(nameRemote)_\(timestamCapture).jpg"
            
            if isFirstEdit {
                imageNameFile = "\(imageNameFile)"
            } else {
                imageNameFile = "\(imageNameFile)_\(Date().fileNameFromeDate)"
            }
            return imageNameFile
        } else {
            return nil
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}


