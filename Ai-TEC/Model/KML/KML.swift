import UIKit
import AEXML
import CoreLocation
@available(iOS 10.0, *)
class KML {
    static let shared: KML = KML()
    var currentLocation: CLLocation?
    var locationManager: CLLocationManager = CLLocationManager()
    var timer = Timer()
    
    static let soapRequest = AEXMLDocument()
    static let kml = KML.soapRequest.addChild(name: "kml", attributes: [" xmlns" : "http://www.opengis.net/kml/2.2"])
    static let document = KML.kml.addChild(name: "Document")
    
    @discardableResult
    func soap() -> String {
        currentLocation = locationManager.location
        KML.document.addChild(name: "name", value: "pathName")
        KML.document.addChild(name: "description", value: "description")
        let style1 = KML.document.addChild(name: "Style", attributes: ["id" : "poligon"])
        let lineStyle = style1.addChild(name: "LineStyle")
            lineStyle.addChild(name: "color", value: "7f00fff")
            lineStyle.addChild(name: "width", value: "4")
        let polyStyle = style1.addChild(name: "PolyStyle")
            polyStyle.addChild(name: "color", value: "7f00ff00")
        let placemark1 = KML.document.addChild(name: "Placemark")
                placemark1.addChild(name: "name", value: "Ai-Tec")
                placemark1.addChild(name: "description", value: "mô tả")
                placemark1.addChild(name: "styleUrl", value: "#poligon")
        let lineString = placemark1.addChild(name: "LineString")
            lineString.addChild(name: "extrude", value: "1")
            lineString.addChild(name: "tessellate", value: "1")
            lineString.addChild(name: "altitudeMode", value: "absolute")
        let coordinates = lineString.addChild(name: "coordinates", value:  "")
        let schema = KML.document.addChild(name: "Schema", attributes: [ "name" : "HeadType", "id" : "HeadTypeId" ])
        let simpleField1 = schema.addChild(name: "SimpleField", attributes: [ "type" : "string" , "name" : "CallType" ])
            simpleField1.addChild(name: "displayName", value: "&lt;![CDATA[&lt;b&gt;Call Type&lt;/b&gt;]]&gt;")
        let simpleField2 = schema.addChild(name: "SimpleField",attributes: [ "type" : "string" , "name" : "TimeStamp" ])
            simpleField2.addChild(name: "displayName", value: "&lt;![CDATA[&lt;b&gt;Partner&lt;/b&gt;]]&gt;")
        let simpleField3 = schema.addChild(name: "SimpleField", attributes: [ "type" : "string", "name" : "" ])
            simpleField3.addChild(name: "displayName", value: "&lt;![CDATA[&lt;b&gt;TimeStamp&lt;/b&gt;]]&gt;")
        let style2 = KML.document.addChild(name: "Style", attributes: ["id" : "startCall"])
        let iconStyle1 = style2.addChild(name: "IconStyle")
            iconStyle1.addChild(name: "color", value: "ff00ff00")
            iconStyle1.addChild(name: "colorMode", value: "random")
            iconStyle1.addChild(name: "scale", value: "1.1")
        let icon1 = iconStyle1.addChild(name: "Icon")
            icon1.addChild(name: "href", value: "https://png.pngtree.com/svg/20170818    allow_call_435496.png")
        let style3 = KML.document.addChild(name: "Style", attributes: ["id" : "endCall"])
        let iconStyle2 = style3.addChild(name: "IconStyle")
            iconStyle2.addChild(name: "color", value: "ff00ff00")
            iconStyle2.addChild(name: "colorMode", value: "random")
            iconStyle2.addChild(name: "scale", value: "1.1")
        let icon2 = iconStyle2.addChild(name: "Icon")
            icon2.addChild(name: "href", value: "http://endat.org/wp-content/uploads/2017/09/phone-icon-red.png")
        let style4 = KML.document.addChild(name: "Style", attributes: ["id" : "sendImage"])
        let iconStyle3 = style4.addChild(name: "IconStyle")
            iconStyle3.addChild(name: "color", value: "ff00ff00")
            iconStyle3.addChild(name: "colorMode", value: "random")
            iconStyle3.addChild(name: "scale", value: "1.1")
        let icon3 = iconStyle3.addChild(name: "Icon")
            icon3.addChild(name: "href", value: "https://www.svgimages.com/svg-image/s5/send-file-256x256.png")
        
        //apend local user
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if CLLocationManager.locationServicesEnabled() {
                switch CLLocationManager.authorizationStatus() {
                case .notDetermined, .restricted, .denied:
                    print("local chưa bật")
                case .authorizedWhenInUse , .authorizedAlways:
                    self.currentLocation = self.locationManager.location
                    if self.currentLocation?.coordinate != nil {
                        coordinates.value?.append("\(self.currentLocation!.coordinate.longitude),\(self.currentLocation!.coordinate.latitude),0 \n")
                    }
                }
            }
        }
        
        let fileName = getDocumentsDirectory().appendingPathComponent("sample.kml")
        do {
            try KML.soapRequest.xml.write(to: fileName, atomically: true, encoding: String.Encoding.utf8)
        } catch  {
            print("error")
        }
        
        return KML.soapRequest.xml
    }
    
    @discardableResult
    func startCall() -> AEXMLElement {
        //        check vị trí khi start call rồi add vào kml
        currentLocation = locationManager.location
        let placemark = KML.document.addChild(name: "Placemark")
            placemark.addChild(name: "name", value: "Start Call")
            placemark.addChild(name: "styleUrl", value: "#startCall")
        let extendedData = placemark.addChild(name: "ExtendedData")
        let schemaData = extendedData.addChild(name: "SchemaData", attributes: ["schemaUrl" : "#HeadTypeId"])
            schemaData.addChild(name: "SimpleData", value: "PeerToPeer", attributes: ["name" : "CallType"])
            schemaData.addChild(name: "SimpleData", value: "vtest1", attributes: ["name" : "Partner"])
            schemaData.addChild(name: "SimpleData", value: "vtest1", attributes: [ "name" : "TimeStamp"])
        let point = placemark.addChild(name: "Point")
        if currentLocation?.coordinate != nil {
            point.addChild(name: "coordinates", value: "\(self.currentLocation!.coordinate.longitude),\(self.currentLocation!.coordinate.latitude),0")
            
        } else {
            //                    print("local chưa bật")
        }
        return placemark
    }
    
    @discardableResult
    func endCall() -> AEXMLElement {
        
        // check vị trí khi end call rồi add vào kml
        currentLocation = locationManager.location
        let placemark = KML.document.addChild(name: "Placemark")
            placemark.addChild(name: "name", value: "End Call")
            placemark.addChild(name: "styleUrl", value: "#endCall")
        let extendedData = placemark.addChild(name: "ExtendedData")
        let schemaData = extendedData.addChild(name: "SchemaData",attributes: ["schemaUrl" : "#HeadTypeId"])
            schemaData.addChild(name: "SimpleData", value: "PeerToPeer", attributes: ["name" : "CallType"])
            schemaData.addChild(name: "SimpleData", value: "vtest1", attributes: ["name": "Partner"])
            schemaData.addChild(name: "SimpleData", value: "TimeStamp", attributes: ["name" : "TimeStamp"])
        let point = placemark.addChild(name: "Point")
        if currentLocation?.coordinate != nil {
            point.addChild(name: "coordinates", value: "\(self.currentLocation!.coordinate.longitude),\(self.currentLocation!.coordinate.latitude),0")
            
        } else {
            //            print("local chưa bật")
        }
        
        // save kml vào document
        let fileName = getDocumentsDirectory().appendingPathComponent("sample.kml")
        do {
            try KML.soapRequest.xml.write(to: fileName, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print("Failed save")
        }
        return placemark
    }
    
    @discardableResult
    func sendImage() -> AEXMLElement {
        
        // check vị trí khi người dùng chụp ảnh rồi add vào kml
        currentLocation = locationManager.location
        let placemark = KML.document.addChild(name: "Placemark")
            placemark.addChild(name: "name", value: "Send Image")
            placemark.addChild(name: "styleUrl", value: "#sendImage")
        let extendedData = placemark.addChild(name: "ExtendedData")
        let schemaData = extendedData.addChild(name: "SchemaData",attributes: ["schemaUrl" : "#HeadTypeId"])
            schemaData.addChild(name: "SimpleData", value: "PeerToPeer", attributes: ["name" : "CallType"])
            schemaData.addChild(name: "SimpleData", value: "vtest1", attributes: ["name": "Partner"])
            schemaData.addChild(name: "SimpleData", value: "TimeStamp", attributes: ["name" : "TimeStamp"])
        let point = placemark.addChild(name: "Point")
        if currentLocation?.coordinate != nil {
            point.addChild(name: "coordinates", value: "\(self.currentLocation!.coordinate.longitude),\(self.currentLocation!.coordinate.latitude),0")
            
        } else {
            //            print("local chưa bật")
        }
        
        // save kml vào document
        let fileName = getDocumentsDirectory().appendingPathComponent("sample.kml")
        do {
            try KML.soapRequest.xml.write(to: fileName, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print("Failed save")
        }
        
        return placemark
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}
