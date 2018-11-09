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



class EditViewController: UIViewController {
   
    
    weak var paletteView: Palette?
    weak var canvasView: Canvas?
    var nameRemote = ""
    var colorDropDown: DropDown?
    var widthDropDown: DropDown?
    var colorSelectedView: UIView?
    var widthSelectedView: UIView?
    var screenShotImage: UIImage?

    
    var timestampCapture: Date?
    var isFirstEdit: Bool = true
    @IBOutlet weak var toolbarView: UIView!
    @IBOutlet weak var colorButton: UIButton!
    @IBOutlet weak var widthButton: UIButton!
    @IBOutlet weak var eraerButton: UIButton!
    @IBOutlet weak var sendImageButton: UIButton!
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var dismisButton: UIButton!
    @IBOutlet weak var sendButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()

        setupCanvas()
        setupPalette()
        setupToolDrawView()
        
        
        
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
        navigationController?.popViewController(animated: true)
    }
    
    // xoá từng cái
    
    @IBAction func undoButton(_ sender: Any) {
        self.canvasView?.undo()
    }
    
    // gửi và lưu ảnh
    
    @IBAction func sendImage(_ sender: Any) {
        toolbarView.isHidden = true
        colorButton.isHidden = true
        widthButton.isHidden = true
        eraerButton.isHidden = true
        sendImageButton.isHidden = true
        undoButton.isHidden = true
        dismisButton.isHidden = true
        sendButton.isHidden = true
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
    
    func captureScreen() -> UIImage {
        var window: UIWindow? = UIApplication.shared.keyWindow
        window = UIApplication.shared.windows[0] as? UIWindow
        UIGraphicsBeginImageContextWithOptions(window!.frame.size, window!.isOpaque, 0.0)
        window!.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}

// save and upload image

extension EditViewController: CanvasDelegate {
    func brush() -> Brush? {
        return self.paletteView?.currentBrush()
    }
    
    func canvas(_ canvas: Canvas, didSaveDrawing drawing: Drawing, mergedImage image: UIImage?) {
        SVProgressHUD.show()
   
        
        guard let layer = UIApplication.shared.keyWindow?.layer else { return }
        UIGraphicsBeginImageContextWithOptions(layer.frame.size, true, 0)
        guard let context = UIGraphicsGetCurrentContext() else { return }
        layer.render(in: context)
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else { return }
        UIGraphicsEndImageContext()
        guard let data = UIImageJPEGRepresentation(image, 0.9) else {
            return
        }
      
        toolbarView.isHidden = true
        colorButton.isHidden = true
        widthButton.isHidden = true
        eraerButton.isHidden = true
        sendImageButton.isHidden = true
        undoButton.isHidden = true
        dismisButton.isHidden = true
        sendButton.isHidden = true
        toolbarView.isHidden = false
        colorButton.isHidden = false
        widthButton.isHidden = false
        eraerButton.isHidden = false
        sendImageButton.isHidden = false
        undoButton.isHidden = false
        dismisButton.isHidden = false
        sendButton.isHidden = false
      
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
        let dict = ["type" : "sendFile" , "receive" : nameRemote , "url" : "data/file.jpg"]
        SocketGlobal.shared.socket?.write(string: convertString(from: dict))
        print(dict)
    
    }

}



extension EditViewController: WebSocketDelegate {
    func websocketDidConnect(socket: WebSocket) {
        print("--- Message EditViewcontroller ---")
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
                    print("--------\(url)---------")
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
