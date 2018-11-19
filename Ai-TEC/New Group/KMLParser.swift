//
//  KMLParser.swift
//  Ai-Tec
//
//  Created by vMio on 11/14/18.
//  Copyright © 2018 vMio. All rights reserved.
//

import UIKit
import MapKit

extension CLLocationCoordinate2D {
    static func strToCoords(_ str: String) -> [CLLocationCoordinate2D] {
        var coords: [CLLocationCoordinate2D] = []
        coords.reserveCapacity(10)
        
        let tuples = str.components(separatedBy: CharacterSet.whitespacesAndNewlines)
        for tuple in tuples {
            
            var lat: Double = 0.0, lon: Double = 0.0
            let scanner = Scanner(string: tuple)
            scanner.charactersToBeSkipped = CharacterSet(charactersIn: ",")
            let success = scanner.scanDouble(&lon)
            if success {
                let c = CLLocationCoordinate2DMake(lat, lon)
                if CLLocationCoordinate2DIsValid(c) {
                    coords.append(c)
                }
            }
        }
        
        return coords
    }
}


class KMLParser: NSObject, XMLParserDelegate {
    private var _styles: [String: KMLStyle] = [:]
    private var _placemarks: [KMLPlacemark] = []
    
    private var _placemark: KMLPlacemark?
    private var _style: KMLStyle?
    
    private var _xmlParser: XMLParser!
    
    
    // After parsing has completed, this method loops over all placemarks that have
    // been parsed and looks up their corresponding KMLStyle objects according to
    // the placemark's styleUrl property and the global KMLStyle object's identifier.
    
    func  assignStyles() {
        for placemark in _placemarks {
            if placemark.style == nil, let styleUrl = placemark.styleUrl {
                if styleUrl.hasPrefix("#") {
                    let styleID = String(styleUrl.dropFirst(1))
                    let style = _styles[styleID]
                    placemark.style = style
                }
            }
        }
    }
    
    init(url: URL) {
        _xmlParser = XMLParser(contentsOf: url)
        super.init()
        
        _xmlParser.delegate = self
    }
    
    func parseKML() {
        _xmlParser.parse()
        self.assignStyles()
    }
    
    var overlays: [MKOverlay] {
        return _placemarks.compactMap{$0.overlay}
    }
    
    var points: [MKAnnotation] {
        return _placemarks.compactMap{$0.point}
    }
    
    func viewForAnnotation(_ point: MKAnnotation) -> MKAnnotationView? {
        for placemark in _placemarks {
            if placemark.point === point {
                return placemark.annotationView
            }
        }
        return nil
    }
    
    func rendererForOverlay(_ overlay: MKOverlay) -> MKOverlayRenderer? {
        for placemark in _placemarks {
            if placemark.overlay === overlay  {
                return placemark.overlayPathRenderer
            }
        }
        return nil
    }
    
    //MARK: NSXMLParserDelegate
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        let ident = attributeDict["id"]
        
        let style = _placemark?.style ?? _style
        
        // Style and sub-elements
        switch elementName {
        case ELTYPE("Style"):
            if let placemark = _placemark {
                placemark.beginStyleWithIdentifier(ident)
            } else if let identifier = ident {
                _style = KMLStyle(identifier: identifier)
            }
        case ELTYPE("PolyStyle"):
            style?.beginPolyStyle()
        case ELTYPE("LineStyle"):
            style?.beginLineStyle()
        case ELTYPE("color"):
            style?.beginColor()
        case ELTYPE("width"):
            style?.beginWidth()
        case ELTYPE("fill"):
            style?.beginFill()
        case ELTYPE("outline"):
            style?.beginOutline()
        // Placemark and sub-elements
        case ELTYPE("Placemark"):
            _placemark = KMLPlacemark(identifier: ident)
        case ELTYPE("Name"):
            _placemark?.beginName()
        case ELTYPE("Description"):
            _placemark?.beginDescription()
        case ELTYPE("styleUrl"):
            _placemark?.beginStyleUrl()
        case ELTYPE("Polygon"), ELTYPE("Point"), ELTYPE("LineString"):
            _placemark?.beginGeometryOfType(elementName, withIdentifier: ident)
        // Geometry sub-elements
        case ELTYPE("coordinates"):
            _placemark?.geometry?.beginCoordinates()
        // Polygon sub-elements
        case ELTYPE("outerBoundaryIs"):
            _placemark?.polygon?.beginOuterBoundary()
        case ELTYPE("innerBoundaryIs"):
            _placemark?.polygon?.beginInnerBoundary()
        case ELTYPE("LinearRing"):
            _placemark?.polygon?.beginLinearRing()
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        let style = _placemark?.style ?? _style
        
        // Style and sub-elements
        switch elementName {
        case ELTYPE("Style"):
            if let placemark = _placemark {
                placemark.endStyle()
            } else if _style != nil {
                _styles[_style!.identifier!] = _style
                _style = nil
            }
        case ELTYPE("PolyStyle"):
            style?.endPolyStyle()
        case ELTYPE("LineStyle"):
            style?.endLineStyle()
        case ELTYPE("color"):
            style?.endColor()
        case ELTYPE("width"):
            style?.endWidth()
        case ELTYPE("fill"):
            style?.endFill()
        case ELTYPE("outline"):
            style?.endOutline()
        // Placemark and sub-elements
        case ELTYPE("Placemark"):
            if let placemark = _placemark {
                _placemarks.append(placemark)
                _placemark = nil
            }
        case ELTYPE("Name"):
            _placemark?.endName()
        case ELTYPE("Description"):
            _placemark?.endDescription()
        case ELTYPE("styleUrl"):
            _placemark?.endStyleUrl()
        case ELTYPE("Polygon"), ELTYPE("Point"), ELTYPE("LineString"):
            _placemark?.endGeometry()
        // Geometry sub-elements
        case ELTYPE("coordinates"):
            _placemark?.geometry?.endCoordinates()
        // Polygon sub-elements
        case ELTYPE("outerBoundaryIs"):
            _placemark?.polygon?.endOuterBoundary()
        case ELTYPE("innerBoundaryIs"):
            _placemark?.polygon?.endInnerBoundary()
        case ELTYPE("LinearRing"):
            _placemark?.polygon?.endLinearRing()
        default:
            break
        }
        
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let element = _placemark ?? _style
        element?.addString(string)
    }
}

struct ELTYPE {
    var typeName: String
    init(_ typeName: String) {
        self.typeName = typeName
    }
}

func ~= (lhs: ELTYPE, rhs: String) -> Bool {
    return rhs.caseInsensitiveCompare(lhs.typeName) == .orderedSame
}

class KMLElement: NSObject {
    let identifier: String?
    fileprivate var accum: String = ""
    
    init(identifier ident: String?) {
        self.identifier = ident
        super.init()
    }
    
    var canAddString: Bool {
        return false
    }
    
    func addString(_ str: String) {
        if self.canAddString {
            accum += str
        }
    }
    
    func clearString() {
        accum = ""
    }
}

class KMLStyle: KMLElement {
    private var strokeColor: UIColor?
    private var strokeWidth: CGFloat = 0.0
    private var fillColor: UIColor?
    
    private var fill: Bool = false
    private var stroke: Bool = false
    
    private struct Flags: OptionSet {
        var rawValue: Int32
        init(rawValue: Int32) {self.rawValue = rawValue}
        static let inLineStyle = Flags(rawValue: 1<<0)
        static let inPolyStyle = Flags(rawValue: 1<<1)
        
        static let inColor = Flags(rawValue: 1<<2)
        static let inWidth = Flags(rawValue: 1<<3)
        static let inFill = Flags(rawValue: 1<<4)
        static let inOutline = Flags(rawValue: 1<<5)
    }
    private var flags: Flags = Flags(rawValue: 0)
    
    override var canAddString: Bool {
        return flags.intersection([.inColor, .inWidth, .inFill, .inOutline]) != []
    }
    
    func beginLineStyle() {
        flags.insert(.inLineStyle)
    }
    
    func endLineStyle() {
        flags.remove(.inLineStyle)
    }
    
    func beginPolyStyle() {
        flags.insert(.inPolyStyle)
    }
    
    func endPolyStyle() {
        flags.remove(.inPolyStyle)
    }
    
    func beginColor() {
        flags.insert(.inColor)
    }
    
    func endColor() {
        flags.remove(.inColor)
        
        if flags.contains(.inLineStyle) {
            strokeColor = UIColor(KMLString: accum)
        } else if flags.contains(.inPolyStyle) {
            fillColor = UIColor(KMLString: accum)
        }
        
        self.clearString()
    }
    
    func beginWidth() {
        flags.insert(.inWidth)
    }
    
    func endWidth() {
        flags.remove(.inWidth)
        strokeWidth = CGFloat(Double(accum) ?? 0.0)
        self.clearString()
    }
    
    func beginFill() {
        flags.insert(.inFill)
    }
    
    func endFill() {
        flags.remove(.inFill)
        fill = (accum as NSString).boolValue
        self.clearString()
    }
    
    func beginOutline() {
        flags.insert(.inOutline)
    }
    
    func endOutline() {
        stroke = (accum as NSString).boolValue
        self.clearString()
    }
    
    func applyToOverlayPathRenderer(_ renderer: MKOverlayPathRenderer) {
        renderer.strokeColor = strokeColor
        renderer.fillColor = fillColor
        renderer.lineWidth = strokeWidth
    }
    
}

class KMLGeometry: KMLElement {
    fileprivate struct Flags: OptionSet {
        var rawValue: Int32
        init(rawValue: Int32) {
            self.rawValue = rawValue
        }
        
        static let inCoords = Flags(rawValue: 1<<0)
    }
    fileprivate var flags: Flags = Flags(rawValue: 0)
    
    override var canAddString: Bool {
        return flags.contains(.inCoords)
    }
    
    func beginCoordinates() {
        flags.insert(.inCoords)
    }
    
    func endCoordinates() {
        flags.remove(.inCoords)
    }
    
    var mapkitShape: MKShape? {
        return nil
    }
    
    func createOverlayPathRenderer(_ shape: MKShape) -> MKOverlayPathRenderer? {
        return nil
    }
}

class KMLPoint: KMLGeometry {
    var point: CLLocationCoordinate2D = CLLocationCoordinate2D()
    
    override func endCoordinates() {
        flags.remove(.inCoords)
        
        let points = CLLocationCoordinate2D.strToCoords(accum)
        if points.count == 1 {
            point = points[0]
        }
        
        self.clearString()
    }
    
    override var mapkitShape: MKShape? {
        // KMLPoint corresponds to MKPointAnnotation
        let annotation = MKPointAnnotation()
        annotation.coordinate = point
        return annotation
    }
    
    // KMLPoint does not override MKOverlayPathRenderer: because there is no such
    // thing as an overlay view for a point.  They use MKAnnotationViews which
    // are vended by the KMLPlacemark class.
    
}

// A KMLPolygon element corresponds to an MKPolygon and MKPolygonView
class KMLPolygon: KMLGeometry {
    private var outerRing: String = ""
    private var innerRings: [String] = []
    
    private struct PolyFlags: OptionSet {
        var rawValue: Int32
        init(rawValue: Int32) {self.rawValue = rawValue}
        
        static let inOuterBoundary = PolyFlags(rawValue: 1<<0)
        static let inInnerBoundary = PolyFlags(rawValue: 1<<1)
        static let inLinearRing = PolyFlags(rawValue: 1<<2)
    }
    private var polyFlags: PolyFlags = PolyFlags(rawValue: 0)
    
    
    override var canAddString: Bool {
        return polyFlags.contains(.inLinearRing) && flags.contains(.inCoords)
    }
    
    func beginOuterBoundary() {
        polyFlags.insert(.inOuterBoundary)
    }
    
    func endOuterBoundary() {
        polyFlags.remove(.inOuterBoundary)
        outerRing = accum
        self.clearString()
    }
    
    func beginInnerBoundary() {
        polyFlags.insert(.inInnerBoundary)
    }
    
    func endInnerBoundary() {
        polyFlags.remove(.inInnerBoundary)
        let ring = accum
        innerRings.append(ring)
        self.clearString()
    }
    
    func beginLinearRing() {
        polyFlags.insert(.inLinearRing)
    }
    
    func endLinearRing() {
        polyFlags.remove(.inLinearRing)
    }
    
    override var mapkitShape: MKShape? {
        // KMLPolygon corresponds to MKPolygon
        
        // The inner and outer rings of the polygon are stored as kml coordinate
        // list strings until we're asked for mapkitShape.  Only once we're here
        // do we lazily transform them into CLLocationCoordinate2D arrays.
        
        // First build up a list of MKPolygon cutouts for the interior rings.
        let innerPolys: [MKPolygon] = innerRings.map {coordStr in
            var coords = CLLocationCoordinate2D.strToCoords(coordStr)
            return MKPolygon(coordinates: &coords, count: coords.count)
        }
        // Now parse the outer ring.
        
        var coords = CLLocationCoordinate2D.strToCoords(outerRing)
        
        // Build a polygon using both the outer coordinates and the list (if applicable)
        // of interior polygons parsed.
        let poly = MKPolygon(coordinates: &coords, count: coords.count, interiorPolygons: innerPolys)
        return poly
    }
    
    override func createOverlayPathRenderer(_ shape: MKShape) -> MKOverlayPathRenderer? {
        let polyPath = MKPolygonRenderer(polygon: shape as! MKPolygon)
        return polyPath
    }
    
}

class KMLLineString: KMLGeometry {
    var points: [CLLocationCoordinate2D] = []
    
    override func endCoordinates() {
        flags.remove(.inCoords)
        
        points = CLLocationCoordinate2D.strToCoords(accum)
        
        self.clearString()
    }
    
    override var mapkitShape: MKShape? {
        // KMLLineString corresponds to MKPolyline
        return MKPolyline(coordinates: &points, count: points.count)
    }
    
    override func createOverlayPathRenderer(_ shape: MKShape) -> MKOverlayPathRenderer? {
        let polyLine = MKPolylineRenderer(polyline: shape as! MKPolyline)
        return polyLine
    }
    
}


class KMLPlacemark: KMLElement {
    var style: KMLStyle?
    private(set) var geometry: KMLGeometry?
    
    // Corresponds to the title property on MKAnnotation
    private(set) var name: String?
    // Corresponds to the subtitle property on MKAnnotation
    private(set) var placemarkDescription: String?
    
    var styleUrl: String?
    
    private var mkShape: MKShape?
    
    private var _annotationView: MKAnnotationView?
    private var _overlayPathRenderer: MKOverlayPathRenderer?
    
    struct Flags: OptionSet {
        var rawValue: Int32
        init(rawValue: Int32) {self.rawValue = rawValue}
        
        static let inName = Flags(rawValue: 1<<0)
        static let inDescription = Flags(rawValue: 1<<1)
        static let inStyle = Flags(rawValue: 1<<2)
        static let inGeometry = Flags(rawValue: 1<<3)
        static let inStyleUrl = Flags(rawValue: 1<<4)
    }
    var flags: Flags = Flags(rawValue: 0)
    
    override var canAddString: Bool {
        return flags.intersection([.inName, .inStyleUrl, .inDescription]) != []
    }
    
    override func addString(_ str: String) {
        if flags.contains(.inStyle) {
            style?.addString(str)
        } else if flags.contains(.inGeometry) {
            geometry?.addString(str)
        } else {
            super.addString(str)
        }
    }
    
    func beginName() {
        flags.insert(.inName)
    }
    
    func endName() {
        flags.remove(.inName)
        name = accum
        self.clearString()
    }
    
    func beginDescription() {
        flags.insert(.inDescription)
    }
    
    func endDescription() {
        flags.remove(.inDescription)
        placemarkDescription = accum
        self.clearString()
    }
    
    func beginStyleUrl() {
        flags.insert(.inStyleUrl)
    }
    
    func endStyleUrl() {
        flags.remove(.inStyleUrl)
        styleUrl = accum
        self.clearString()
    }
    
    func beginStyleWithIdentifier(_ ident: String?) {
        flags.insert(.inStyle)
        style = KMLStyle(identifier: ident)
    }
    
    func endStyle() {
        flags.remove(.inStyle)
    }
    
    func beginGeometryOfType(_ elementName: String, withIdentifier ident: String?) {
        flags.insert(.inGeometry)
        switch elementName {
        case ELTYPE("Point"):
            geometry = KMLPoint(identifier: ident)
        case ELTYPE("Polygon"):
            geometry = KMLPolygon(identifier: ident)
        case ELTYPE("LineString"):
            geometry = KMLLineString(identifier: ident)
        default:
            break
        }
    }
    
    func endGeometry() {
        flags.remove(.inGeometry)
    }
    
    var polygon: KMLPolygon? {
        return geometry as? KMLPolygon
    }
    
    private func _createShape() {
        if mkShape == nil {
            mkShape = geometry?.mapkitShape
            mkShape?.title = name
            // Skip setting the subtitle for now because they're frequently
            // too verbose for viewing on in a callout in most kml files.
            //        mkShape.subtitle = placemarkDescription;
        }
    }
    
    var overlay: MKOverlay? {
        self._createShape()
        
        return mkShape as? MKOverlay
        
    }
    
    var point: MKAnnotation? {
        self._createShape()
        
        // Make sure to check if this is an MKPointAnnotation.  MKOverlays also
        // conform to MKAnnotation, so it isn't sufficient to just check to
        // conformance to MKAnnotation.
        return mkShape as? MKPointAnnotation
        
    }
    
    var overlayPathRenderer: MKOverlayPathRenderer? {
        if _overlayPathRenderer == nil {
            if let overlay = self.overlay {
                _overlayPathRenderer = geometry?.createOverlayPathRenderer(overlay as! MKShape)
                style?.applyToOverlayPathRenderer(_overlayPathRenderer!)
            }
        }
        return _overlayPathRenderer
    }
    
    var annotationView: MKAnnotationView? {
        if _annotationView == nil {
            if let annotation = self.point {
                let pin = MKPinAnnotationView(annotation: annotation, reuseIdentifier: nil)
                pin.canShowCallout = true
                pin.animatesDrop = true
                _annotationView = pin
            }
        }
        return _annotationView
    }
    
}

extension UIColor {
    convenience init(KMLString kmlColorString: String) {
        let scanner = Scanner(string: kmlColorString)
        var color: UInt32 = 0
        scanner.scanHexInt32(&color)
        
        let a = (color >> 24) & 0x000000FF
        let b = (color >> 16) & 0x000000FF
        let g = (color >> 8) & 0x000000FF
        let r = color & 0x000000FF
        
        let rf = CGFloat(r) / 255.0
        let gf = CGFloat(g) / 255.0
        let bf = CGFloat(b) / 255.0
        let af = CGFloat(a) / 255.0
        
        self.init(red: rf, green: gf, blue: bf, alpha: af)
    }
}
