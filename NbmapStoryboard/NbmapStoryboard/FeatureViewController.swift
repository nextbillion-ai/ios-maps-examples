import UIKit
import Nbmap

class FeatureViewController: UIViewController, NGLMapViewDelegate {
    
    var feature: Feature?
    private let apiClient: NBAPIClient = NBAPIClient()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        let mapView = NGLMapView(frame: view.bounds)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.setCenter(CLLocationCoordinate2D(latitude: 12.973388, longitude: 77.593181), zoomLevel: 12, animated: false)
        mapView.delegate = self
        
        view.addSubview(mapView)
    }
    
    func mapView(_ mapView: NGLMapView, didFinishLoading style: NGLStyle) {
        switch feature?.type {
        case .directions:
            showDirections(mapView:mapView)
            break
        case .marker:
            loadMarker(mapView:mapView, style: style)
            break
        case .polyline:
            loadPolyline(mapView:mapView)
            break
        case .polygon:
            loadPolygon(mapView:mapView)
            break
        case .distanceMatrix:
            showDistanceMatrix(mapView:mapView)
            break
        case .matching:
            showMatching(mapView:mapView)
            break
        default:
            loadSimpleMap()
        }
    }
    
    
    private func loadSimpleMap() {
        
    }

    
    private func loadMarker(mapView: NGLMapView, style: NGLStyle) {
        let locations: [CLLocationCoordinate2D] =  [
            CLLocationCoordinate2D(latitude: 12.97780156, longitude: 77.59656748),
            CLLocationCoordinate2D(latitude: 12.98208919, longitude: 77.60329262)
        ]
        
        if let currentAnnotations = mapView.annotations {
            mapView.removeAnnotations(currentAnnotations)
        }
        
        mapView.addAnnotations(locations.map({(coord)->
            NGLPointAnnotation in
            let annotation = NGLPointAnnotation()
            annotation.coordinate = coord
            return annotation
        }))
        
        
        let customizedMarkersPoint = NGLPointAnnotation()
        customizedMarkersPoint.coordinate = mapView.centerCoordinate
        
        let customizedMarkersSource = NGLShapeSource(identifier: "customised-marker-source", shape: customizedMarkersPoint, options: nil)
        let customizedMarkersLayer = NGLSymbolStyleLayer(identifier: "customised-marker-style", source: customizedMarkersSource)
        
        if let image = UIImage(named: "nb-icon") {
            style.setImage(image, forName: "nb-symbol")
        }
        
        customizedMarkersLayer.iconImageName = NSExpression(forConstantValue: "nb-symbol")
        style.addSource(customizedMarkersSource)
        style.addLayer(customizedMarkersLayer)
    }
    
    
    private func loadPolyline(mapView: NGLMapView) {
        let locations: [CLLocationCoordinate2D] =  [
            CLLocationCoordinate2D(latitude: 12.92948165, longitude: 77.61501446),
            CLLocationCoordinate2D(latitude: 12.95205978, longitude: 77.60494206),
            CLLocationCoordinate2D(latitude: 12.96612918, longitude: 77.60678866),
            CLLocationCoordinate2D(latitude: 12.96449325, longitude: 77.59654839)
        ]
        
        if let currentAnnotations = mapView.annotations {
            mapView.removeAnnotations(currentAnnotations)
        }
        
        
        let polyline: NGLPolyline = NGLPolyline.init(coordinates: locations, count: 4)
        mapView.addAnnotation(polyline)
        
        let source: NGLShapeSource = NGLShapeSource(identifier: "polyline", shape: polyline)
        guard let style = mapView.style else { return }
        style.addSource(source)
        let layer = NGLLineStyleLayer(identifier: "polyline-layer", source: source)
        // Set the line join and cap to a rounded end.
        layer.lineJoin = NSExpression(forConstantValue: "round")
        layer.lineCap = NSExpression(forConstantValue: "round")
         
        // Set the line color to a constant blue color.
        layer.lineColor = NSExpression(forConstantValue: UIColor(red: 255/255, green: 78/255, blue: 208/255, alpha: 1))
        layer.lineWidth = NSExpression(forConstantValue: 2)
        
        style.addLayer(layer)
    }
    
    
    private func loadPolygon(mapView: NGLMapView) {
        let locations: [CLLocationCoordinate2D] =  [
            CLLocationCoordinate2D(latitude: 12.94798778, longitude: 77.57375084),
            CLLocationCoordinate2D(latitude: 12.93669616, longitude: 77.57385337),
            CLLocationCoordinate2D(latitude: 12.93639637, longitude: 77.58031279),
            CLLocationCoordinate2D(latitude: 12.94808770, longitude: 77.58000520)
        ]
        if let currentAnnotations = mapView.annotations {
            mapView.removeAnnotations(currentAnnotations)
        }
        
        let polygon: NGLPolygon = NGLPolygon.init(coordinates: locations, count: 4)
        mapView.addAnnotation(polygon)
    }
    
    
    private func showDirections(mapView: NGLMapView) {
        let locations: [CLLocationCoordinate2D] =  [
            CLLocationCoordinate2D(latitude: 12.96206481, longitude: 77.56687669),
            CLLocationCoordinate2D(latitude: 12.99150562, longitude: 77.61940507)
        ]

        apiClient.getDirections(locations) {
            resp in
            
            let first = resp?.routes.first;
            if first is NBRoute {
                let route:NBRoute? = first as? NBRoute
                let geometry = route?.geometry
                let routeline = GeometryDecoder.covert(toFeature: geometry, precision:5)
                let routeSource = NGLShapeSource.init(identifier: "route-style-source", shape: routeline)
                mapView.style?.addSource(routeSource)
                let routeLayer = NGLLineStyleLayer.init(identifier: "route-layer", source: routeSource)
                routeLayer.lineColor = NSExpression.init(forConstantValue: UIColor.red)
                routeLayer.lineWidth = NSExpression.init(forConstantValue: 2)
            
                mapView.style?.addLayer(routeLayer)

            }
        }
    }
    
    
    private func showDistanceMatrix(mapView: NGLMapView) {
        
    }
    
    
    private func showMatching(mapView: NGLMapView) {
        let locations: [NBLocation] = [
            NBLocation().inti(withValues: 12.94685395, lng: 77.57421511),
            NBLocation().inti(withValues: 12.96087173, lng: 77.57567788),
            NBLocation().inti(withValues: 12.96628856, lng: 77.58859895),
        ]
        
        let apiClient: NBAPIClient = NBAPIClient()
        apiClient.getMatching(locations) { resp in
            let geometry:String? = resp?.geometry[0] as? String
            let routeline = GeometryDecoder.covert(toFeature: geometry, precision:5)
            let routeSource = NGLShapeSource.init(identifier: "snapped-route-style-source", shape: routeline)
            mapView.style?.addSource(routeSource)
            let routeLayer = NGLLineStyleLayer.init(identifier: "snapped-route-layer", source: routeSource)
            routeLayer.lineColor = NSExpression.init(forConstantValue: UIColor.red)
            routeLayer.lineWidth = NSExpression.init(forConstantValue: 2)
            mapView.style?.addLayer(routeLayer)
        }
    }

}
