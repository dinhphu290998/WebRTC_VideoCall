//
//  EditViewController.swift
//  Apprtc
//
//  Created by Hoang Tuan Anh on 12/30/17.
//  Copyright © 2017 Dhilip. All rights reserved.
//

import UIKit
import DropDown
import AVFoundation
import MobileCoreServices
import Material
import Alamofire
import SocketRocket
import Toast_Swift
import CoreLocation
import SVProgressHUD

class EditViewController: SocketViewController {
  weak var canvasView: Canvas?
  weak var paletteView: Palette?

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
  @IBOutlet weak var eraserButton: UIButton!
  @IBOutlet weak var sendImageButton: UIButton!

  // MARK: - LIFE CYCLE
  override func viewDidLoad() {
    super.viewDidLoad()
    self.initialize()
//    socket?.delegate = self
    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyBest
    locationManager.requestAlwaysAuthorization()
    locationManager.startUpdatingLocation()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }

  // MARK: - INITIALIZE
  fileprivate func initialize() {
    self.setupCanvas()
    self.setupPalette()
    self.setupToolDrawView()
  }

  fileprivate func setupPalette() {
    let paletteView = Palette()
    paletteView.setup()
    self.view.addSubview(paletteView)
    self.paletteView = paletteView
    let paletteHeight = paletteView.paletteHeight()
    paletteView.frame = CGRect(x: 0, y: 36, width: self.view.frame.width, height: paletteHeight)
  }

  fileprivate func setupToolDrawView() {
    var width = min(Screen.height, Screen.width)
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

    let colors = [Color.init(red: 252/255.0, green: 13/255.0, blue: 36/255.0, alpha: 1.0),
                  Color.init(red: 254/255.0, green: 230/255.0, blue: 97/255.0, alpha: 1.0),
                  Color.init(red: 39/255.0, green: 244/255.0, blue: 86/255.0, alpha: 1.0),
                  Color.init(red: 88/255.0, green: 161/255.0, blue: 237/255.0, alpha: 1.0),
                  Color.init(red: 136/255.0, green: 15/255.0, blue: 125/255.0, alpha: 1.0),
                  Color.init(red: 252/255.0, green: 50/255.0, blue: 128/255.0, alpha: 1.0)
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

  @objc func changeBrushColor(color: UIColor) {
    colorSelectedView?.backgroundColor = color
  }

  @objc func changeBrushWidth(brushWidth: CGFloat) {
    var width = min(Screen.height, Screen.width)
    width = (width - 6*16 - 38*2)/2
    widthSelectedView?.frame = CGRect(x: 3, y: 22 - brushWidth/4, width: width - 36, height: brushWidth/2)
  }

  // MARK: - USER EVENTS
  @IBAction func eraserButtonTouched(_ sender: Any) {
    self.brush()?.color = .clear
    changeBrushColor(color: .clear)
  }

  @IBAction func resetButtonTouched(_ sender: Any) {
    self.canvasView?.clear()
  }

  @IBAction func undoButtonTouched(_ sender: Any) {
    self.canvasView?.undo()
  }

  @IBAction func backButtonTouched(_ sender: Any) {
    //        if let keyWindow = UIApplication.shared.keyWindow,
    //            let navigationController = keyWindow.rootViewController as? UINavigationController {
    //            navigationController.popViewController(animated: true)
    //        }

    dismiss(animated: true, completion: nil)
  }

  @IBAction func sendImageButtonTouched(_ sender: Any) {
    canvasView?.save()
  }

  @objc fileprivate func showColorPicker() {
    colorDropDown?.show()
  }

  @objc fileprivate func showWidthPicker() {
    widthDropDown?.show()
  }

  fileprivate func setupCanvas() {
    let sizeView = self.view.bounds.size
    let width = min(sizeView.width, sizeView.height)
    let height = max(sizeView.width, sizeView.height)

    let canvasView = Canvas(backgroundImage: screenShotImage)
    print(screenShotImage?.size ?? "")
    canvasView.frame = CGRect(x: 0, y: 96, width: width, height: height-172)
    canvasView.delegate = self
    canvasView.clipsToBounds = true

    self.view.addSubview(canvasView)
    self.canvasView = canvasView
  }

  func image(_ image: UIImage, didFinishSavingWithError: NSError?, contextInfo: UnsafeRawPointer) {
    if didFinishSavingWithError != nil {
      print("Saving failed")
    } else {
      print("Saved successfuly")
    }
  }
}

extension EditViewController: CLLocationManagerDelegate {
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    currentLocation = manager.location
  }
}

// MARK: - CanvasDelegate
extension EditViewController: CanvasDelegate {
  func brush() -> Brush? {
    return self.paletteView?.currentBrush()
  }

  func canvas(_ canvas: Canvas, didSaveDrawing drawing: Drawing, mergedImage image: UIImage?) {
    SVProgressHUD.show()
    if let jpegData = image?.asJPEGData(1),
      let callingInfo = callingInfo,
      let imageNameFile = getImageNameFile(callingInfo: callingInfo) {
      let oldEXIF = self.getEXIFFromImage(image: jpegData)
      var attached = jpegData
      if isFirstEdit {
        if let gpsDict = currentLocation?.getGPSDictionary() {
          let newEXIF = addInfoToEXIF(old: oldEXIF, gps: gpsDict, dateCapture: self.timestampCapture)
          attached = attachEXIFToImage(image: jpegData as NSData, EXIF: newEXIF) as Data
          print("newEXIF: \(newEXIF)")
        } else {
          SVProgressHUD.showError(withStatus: "Can't send image. Please check GPS.")
          return
        }
      } else {
        let newEXIF = addInfoToEXIF(old: oldEXIF, gps: nil, dateCapture: self.timestampCapture)
        attached = attachEXIFToImage(image: jpegData as NSData, EXIF: newEXIF) as Data
        print("newEXIF: \(newEXIF)")
      }
      Alamofire.upload(multipartFormData: { (multipartFormData) in
        multipartFormData.append(attached, withName: "data", fileName: imageNameFile, mimeType: "image/jpeg")
      }, to: apiSendImage, encodingCompletion: { (result) in
        switch result {
        case .success(let upload, _, _):
          DispatchQueue.main.async {
            SVProgressHUD.dismiss()
          }
          upload.responseJSON(completionHandler: { (response) in
            response.result.ifSuccess {
              if let value = response.value,
                let JSON = value as? NSDictionary {
                print(JSON)
                if let status = JSON["status"] as? String,
                  status == "success" {
                  var receiveRegId: String
                  if callingInfo.isHost {
                    receiveRegId = callingInfo.receive.regId
                  } else {
                    receiveRegId = callingInfo.host.regId
                  }
                  self.socket?.sendImage(regId: receiveRegId, image: imageNameFile,
                                         completion: { (_, message) in
                                          self.view.makeToast(message)
                                          if message == "success" {
                                            self.dismiss(animated: true, completion: nil)
                                          }
                  })
                }
              }
              self.isFirstEdit = false
            }
          })
        case .failure(let error):
          print("error:\(error)")
          DispatchQueue.main.async {
            SVProgressHUD.dismiss()
            SVProgressHUD.showError(withStatus: "Can't send image")
          }
        }
      })
    } else {
      SVProgressHUD.dismiss()
      SVProgressHUD.showError(withStatus: "Can't send image")
    }
  }

  func getImageNameFile(callingInfo: CallingInfo) -> String? {
    if let timestampCapture = timestampCapture?.fileNameFromeDate {
      var imageNameFile: String
      if callingInfo.isHost {
        imageNameFile = "\(callingInfo.receive.name)_\(timestampCapture)"
      } else {
        imageNameFile = "\(callingInfo.host.name)_\(timestampCapture)"
      }

      if isFirstEdit {
        imageNameFile = "\(imageNameFile).jpg"
      } else {
        imageNameFile = "\(imageNameFile)_\(Date().fileNameFromeDate).jpg"
      }

      return imageNameFile
    } else {
      return nil
    }
  }
}

extension EditViewController {
  override func webSocket(_ webSocket: SRWebSocket!, didReceiveMessage message: Any!) {
    super.webSocket(webSocket, didReceiveMessage: message)
  }
}
