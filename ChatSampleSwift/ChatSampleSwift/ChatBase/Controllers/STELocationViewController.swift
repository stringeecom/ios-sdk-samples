//
//  STELocationViewController.swift
//  ChatSampleSwift
//
//  Created by HoangDuoc on 4/20/19.
//  Copyright © 2019 HoangDuoc. All rights reserved.
//

import UIKit
import MapKit
import SnapKit
import CoreLocation

let STELocationCustomPinIdentifer = "STELocationCustomPinIdentifer"

class STELocationViewController: UIViewController {
    
    let mapview: MKMapView = {
        let mapview = MKMapView()
        mapview.mapType = .standard
        mapview.showsUserLocation = true
        mapview.userTrackingMode = .follow
        return mapview
    }()
    
    let detailView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 7
        view.clipsToBounds = true
        view.layer.shadowColor = UIColor(red: 176, green: 199, blue: 226, alpha: 1).cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 0)
        view.layer.shadowOpacity = 0.5
        view.layer.shadowRadius = 5.0
        view.layer.masksToBounds = false
        return view
    }()
    
    let btMaptype: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "LocationInfo"), for: .normal)
        return button
    }()
    
    let btLocation: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "TrackingLocationOff"), for: .normal)
        return button
    }()
    
    let optionView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()

    let btDirect: UIButton = {
        let button = UIButton()
        button.setTitle("Chỉ đường", for: .normal)
        button.setTitleColor(STEColor.blue, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
        button.layer.borderColor = STEColor.blue.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 8
        button.clipsToBounds = true
        
        return button
    }()
    
    let ivLocation: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "LocationPinIcon"))
        iv.contentMode = .scaleAspectFit
        iv.backgroundColor = STEColor.blue
        return iv
    }()
    
    let trackingView: UIView = {
        let view = UIView()
        view.backgroundColor = .red
        return view
    }()
    
    let ivPoint: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "Point"))
        return iv
    }()
    
    let ivTracking: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "PinLocation"))
        return iv
    }()
    
    let lbTitle: UILabel = {
        let lb = UILabel()
        lb.text = "Vị trí"
        lb.font = UIFont.boldSystemFont(ofSize: 17)
        lb.textColor = STEColor.blue
        return lb
    }()
    
    let lbDes: UILabel = {
        let lb = UILabel()
        lb.text = "Description"
        lb.font = UIFont.systemFont(ofSize: 12)
        lb.textColor = UIColor.darkGray
        return lb
    }()
    
    let btSend: UIButton = {
        let button = UIButton()
        return button
    }()
    
    lazy var locationManager: CLLocationManager = {
        let locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        return locationManager
    }()
    
    let segmentMapOptions: UISegmentedControl = {
        let segment = UISegmentedControl(items: ["Map", "Satellite", "Hybrid"])
        segment.selectedSegmentIndex = 0
        segment.clipsToBounds = true
        segment.backgroundColor = .white
        
        return segment
    }()
    
    var currentAnnotation: MKPointAnnotation? = nil
    let geocoder = CLGeocoder()
    var locationToSend: CLLocationCoordinate2D = kCLLocationCoordinate2DInvalid
    var destinationLocation: CLLocationCoordinate2D = kCLLocationCoordinate2DInvalid
    var userLocation: MKUserLocation?
    var shouldAnimationUp = true
    
    var isSendingMode = true
    var isUserLocation = true
    
    var ivLocationBottomToBtDirectionContraint: Constraint? = nil
    var ivLocationBottomToOptionViewContraint: Constraint? = nil

    init(isSendingMode: Bool, destinationLocation: CLLocationCoordinate2D = kCLLocationCoordinate2DInvalid) {
        super.init(nibName: nil, bundle: nil)
        self.isSendingMode = isSendingMode
        self.destinationLocation = destinationLocation
    }
    
    override func loadView() {
        super.loadView()
        view.backgroundColor = .white
        
        view.addSubview(mapview)
        view.addSubview(detailView)
        detailView.addSubview(btMaptype)
        detailView.addSubview(btLocation)
        
        view.addSubview(optionView)
        optionView.addSubview(btDirect)
        optionView.addSubview(ivLocation)
        optionView.addSubview(lbTitle)
        optionView.addSubview(lbDes)
        optionView.addSubview(btSend)
        
        mapview.addSubview(trackingView)
        trackingView.addSubview(ivPoint)
        trackingView.addSubview(ivTracking)

        btMaptype.addTarget(self, action: #selector(STELocationViewController.handleDetailTapped), for: .touchUpInside)
        btLocation.addTarget(self, action: #selector(STELocationViewController.handleTrackingLocationTapped), for: .touchUpInside)
        btSend.addTarget(self, action: #selector(STELocationViewController.handleSendLocationTapped), for: .touchUpInside)
        btDirect.addTarget(self, action: #selector(STELocationViewController.handleDirectionTapped), for: .touchUpInside)

        let pan = UIPanGestureRecognizer(target: self, action: #selector(STELocationViewController.handlePanGestureOnMapViewTapped(gesture:)))
        pan.delegate = self
        mapview.addGestureRecognizer(pan)
        
        // Mapview
        mapview.snp.makeConstraints { (make) in
            make.bottom.equalTo(optionView.snp.top).offset(20)
            if #available(iOS 11.0, *) {
//                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottomMargin)
                make.left.equalTo(view.safeAreaLayoutGuide.snp.leftMargin)
                make.right.equalTo(view.safeAreaLayoutGuide.snp.rightMargin)
                make.top.equalTo(view.safeAreaLayoutGuide.snp.topMargin)
            } else {
                make.top.equalTo(self.topLayoutGuide.snp.bottom)
                make.left.equalTo(view)
                make.right.equalTo(view)
//                make.bottom.equalTo(self.bottomLayoutGuide.snp.bottom)
            }
        }
        
        // Segment
        view.addSubview(segmentMapOptions)
        segmentMapOptions.addTarget(self, action: #selector(STELocationViewController.handleSegmentValueChanged(segment:)), for: .valueChanged)
        segmentMapOptions.snp.makeConstraints { (make) in
            make.centerY.equalTo(btMaptype)
            make.left.equalTo(view).offset(10)
            make.right.equalTo(detailView.snp.left).offset(-10)
        }
        
        // DetailView
        detailView.snp.makeConstraints { (make) in
            make.top.equalTo(mapview).offset(8)
            make.right.equalTo(mapview).offset(-8)
            make.size.equalTo(CGSize(width: 45, height: 90))
        }
        
        btMaptype.snp.makeConstraints { (make) in
            make.top.equalTo(detailView)
            make.centerX.equalTo(detailView)
            make.width.equalTo(detailView)
            make.height.equalTo(detailView).multipliedBy(0.5)
        }
        
        btLocation.snp.makeConstraints { (make) in
            make.bottom.equalTo(detailView)
            make.centerX.equalTo(detailView)
            make.width.equalTo(detailView)
            make.height.equalTo(detailView).multipliedBy(0.5)
        }
        
        // Option View
        optionView.snp.makeConstraints { (make) in
            make.left.equalTo(mapview)
            make.right.equalTo(mapview)
//            make.bottom.equalTo(mapview)
            if #available(iOS 11.0, *) {
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottomMargin)
            } else {
                make.bottom.equalTo(self.bottomLayoutGuide.snp.bottom)
            }
        }

        btDirect.snp.makeConstraints { (make) in
            make.bottom.equalTo(optionView).offset(-10)
            make.left.equalTo(optionView).offset(10)
            make.right.equalTo(optionView).offset(-10)
            make.height.equalTo(45)
        }
        
        ivLocation.snp.makeConstraints { (make) in
            make.left.equalTo(btDirect)
            make.width.equalTo(ivLocation.snp.height)
            make.width.equalTo(45)
            ivLocationBottomToBtDirectionContraint = make.bottom.equalTo(btDirect.snp.top).offset(-15).priority(.high).constraint
            ivLocationBottomToOptionViewContraint = make.bottom.equalTo(optionView.snp.bottom).offset(-15).priority(.required).constraint
            make.top.equalTo(optionView.snp.top).offset(15)
        }
        ivLocationBottomToBtDirectionContraint?.deactivate()
        
        lbTitle.snp.makeConstraints { (make) in
            make.left.equalTo(ivLocation.snp.right).offset(10)
            make.centerY.equalTo(ivLocation).offset(-10)
        }
        
        lbDes.snp.makeConstraints { (make) in
            make.left.equalTo(lbTitle)
            make.centerY.equalTo(ivLocation).offset(10)
        }
        
        btSend.snp.makeConstraints { (make) in
            make.top.equalTo(lbTitle)
            make.left.equalTo(lbTitle)
            make.bottom.equalTo(lbDes)
            make.right.equalTo(btDirect)
        }
        
        // Tracking View
        trackingView.snp.makeConstraints { (make) in
            make.bottom.equalTo(mapview.snp.centerY)
            make.centerX.equalTo(mapview)
        }
        
        ivPoint.snp.makeConstraints { (make) in
            make.bottom.equalTo(trackingView)
            make.centerX.equalTo(trackingView)
        }
        
        ivTracking.snp.makeConstraints { (make) in
            make.bottom.equalTo(ivPoint.snp.top).offset(-3)
            make.centerX.equalTo(trackingView)
            make.top.equalTo(trackingView)
        }
        
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        mapview.delegate = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Vị trí"
        
        
        // UI
        segmentMapOptions.transform = CGAffineTransform(translationX: 0, y: -60)
        trackingView.isHidden = true
        if isSendingMode {
            ivLocationBottomToBtDirectionContraint?.deactivate()
            ivLocationBottomToOptionViewContraint?.activate()
            
            let cancelItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(STELocationViewController.handleCancelTapped))
            navigationItem.leftBarButtonItem = cancelItem
        } else {
            ivLocationBottomToBtDirectionContraint?.activate()
            ivLocationBottomToOptionViewContraint?.deactivate()
            
            // Lây thông tin vị trí đang xem
            if CLLocationCoordinate2DIsValid(destinationLocation) {
                let loc = CLLocation(latitude: destinationLocation.latitude, longitude: destinationLocation.longitude)
                getPlaceAndDisplay(location: loc)
                
                // Pin annotation cho vị trí này
                currentAnnotation = currentAnnotation != nil ? currentAnnotation : MKPointAnnotation()
                currentAnnotation?.coordinate = destinationLocation
                mapview.addAnnotation(currentAnnotation!)
                
                // zoom đến vị trí này
                zoomTo(location: destinationLocation)
            }
            
        }
        btDirect.isHidden = isSendingMode
        lbTitle.text = isSendingMode ? "Gửi vị trí hiện tại của bạn" : "Vị trí"
        
        // Location
        mapview.delegate = self
        locationServicesEnabled()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        btLocation.addBorderAt(edge: .layerTopEdge, color: UIColor(red: 221, green: 221, blue: 221, alpha: 1))
        optionView.roundCorners(corners: [.topLeft, .topRight], radius: 10)
        ivLocation.round()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    // MARK: - Actions
    
    @objc private func handleCancelTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func handleDetailTapped() {
        presentSegment()
    }

    @objc private func handleTrackingLocationTapped() {
        // Thay đổi ui
        configureLocationModeAndPinDisplay(isUserLocation: true)
        
        // Cập nhật pin cho user location
        addUserCurrentLocationAnnotation()
        
        // zoom đến current user location
        zoomTo(location: mapview.userLocation.coordinate)
    }
    
    @objc private func handleSendLocationTapped() {
        if !isSendingMode || !CLLocationCoordinate2DIsValid(locationToSend) { return }
        print("handleSendLocationTapped")
        let userInfo = ["latitude": locationToSend.latitude,
                        "longitude": locationToSend.longitude,
                        ] as [String: Any]
        NotificationCenter.default.post(name: Notification.Name.STEDidTapSendLocationNotification, object: nil, userInfo: userInfo)
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func handleDirectionTapped() {
        if isSendingMode, !CLLocationCoordinate2DIsValid(destinationLocation)  { return }
        print("handleSendLocationTapped")
        let fromCoordinate = userLocation != nil ? userLocation?.coordinate : mapview.userLocation.coordinate
        let strDirection = String(format: "http://maps.apple.com/?saddr=%f,%f&daddr=%f,%f", fromCoordinate!.latitude, fromCoordinate!.longitude, destinationLocation.latitude, destinationLocation.longitude)
        
        if let directionURL = URL(string: strDirection), UIApplication.shared.canOpenURL(directionURL) {
            UIApplication.shared.openURL(directionURL)
        }
    }
    
    @objc private func handleSegmentValueChanged(segment: UISegmentedControl) {
        switch segment.selectedSegmentIndex {
        case 0:
            mapview.mapType = .standard
            break
        case 1:
            mapview.mapType = .satellite
            break
        case 2:
            mapview.mapType = .hybrid
            break
        default:
            break
        }
    }
    
    private func presentSegment() {
        let shouldShow = segmentMapOptions.transform.ty != 0
        let transform = shouldShow ? CGAffineTransform(translationX: 0, y: 0) : CGAffineTransform(translationX: 0, y: -60)
        UIView.animate(withDuration: 0.2) {
            self.segmentMapOptions.transform = transform
        }
    }
}

// MARK: - Location

extension STELocationViewController {
    private func locationServicesEnabled()  {
        let status = CLLocationManager.authorizationStatus()
        
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            return
        case .denied, .restricted:
            displayLocationEnablementAlert()
            return
        case .authorizedAlways, .authorizedWhenInUse:
            break
            
        }
        
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
    }
    
    private func displayLocationEnablementAlert() {
        let alert = UIAlertController(title: "Cấp quyền", message: "Để chia sẻ vị trí của bạn, cho phép ứng dụng truy cập vị trí của bạn bằng cách đi đến Cài Đặt", preferredStyle: .alert)
        let settingAction = UIAlertAction(title: "Cài đặt", style: .default) { (action) in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.openURL(url)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Huỷ", style: .cancel, handler: nil)
        alert.addAction(settingAction)
        alert.addAction(cancelAction)
    
        present(alert, animated: true, completion: nil)
    }
    
    private func zoomTo(location: CLLocationCoordinate2D) {
        var region = MKCoordinateRegion()
        var span = MKCoordinateSpan()
        span.latitudeDelta = 0.02
        span.longitudeDelta = 0.02
        region.span = span
        region.center = location
        mapview.setRegion(region, animated: true)
    }
    
    private func addUserCurrentLocationAnnotation() {
        if !isSendingMode { return }
        if !self.isUserLocation { return }
        
        currentAnnotation = currentAnnotation != nil ? currentAnnotation : MKPointAnnotation()
        currentAnnotation?.coordinate = mapview.userLocation.coordinate
        mapview.addAnnotation(currentAnnotation!)
    }
    
    private func getPlaceAndDisplay(location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] (placemarks, error) in
            guard let self = self else { return }
            
            guard let placeMark = placemarks?.first, error == nil else {
                self.lbDes.text = "Không thể xác định"
                return
            }
            
            self.lbDes.text = placeMark.name
        }
    }
    
    private func configureLocationModeAndPinDisplay(isUserLocation: Bool) {
        if !isSendingMode { return }
        if isUserLocation == self.isUserLocation { return }
        
        self.isUserLocation = isUserLocation
        
        if isUserLocation {
            lbTitle.text = "Gửi vị trí hiện tại của bạn"
            trackingView.isHidden = true
        } else {
            lbTitle.text = "Gửi vị trí này"
            trackingView.isHidden = false
            mapview.removeAnnotations(mapview.annotations)
        }
    }
    
    @objc private func animationForPinLocation() {
        if !isSendingMode  || isUserLocation { return }
        if self.shouldAnimationUp {
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
                self.ivTracking.transform = CGAffineTransform(translationX: 0, y: -25)
            }, completion: nil)
        } else {
            UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseIn, animations: {
                self.ivTracking.transform = CGAffineTransform(translationX: 0, y: 0)
            }, completion: nil)
        }
    }
    
    private func startAnimationForPinLocation() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(STELocationViewController.animationForPinLocation), object: nil)
        perform(#selector(STELocationViewController.animationForPinLocation), with: nil, afterDelay: 0.05)
    }
}

// MARK: - Gesture Delegate

extension STELocationViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    @objc private func handlePanGestureOnMapViewTapped(gesture: UIGestureRecognizer) {
        switch gesture.state {
        case .began:
            shouldAnimationUp = true
            startAnimationForPinLocation()
            configureLocationModeAndPinDisplay(isUserLocation: false)
            break
        case .changed:
            break
        case .ended:
            break
        default:
            break
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension STELocationViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("locationManager - didUpdateLocations")
//        zoomTo(location: (locations.last?.coordinate)!)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("locationManager - didFailWithError \(error.localizedDescription)")
    }
}

// MARK: - MapviewDelegate

extension STELocationViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        print("mapView - didUpdate userLocation")
        self.userLocation = userLocation
        
        if isUserLocation && isSendingMode {
            zoomTo(location: mapview.userLocation.coordinate)
        }
        
        addUserCurrentLocationAnnotation()
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // Nếu là current user location thì ko làm gì
        if annotation.isKind(of: MKUserLocation.self) || !annotation.isKind(of: MKPointAnnotation.self) { return nil }
        
        var pinView = mapview.dequeueReusableAnnotationView(withIdentifier: STELocationCustomPinIdentifer)
        
        if pinView == nil {
            pinView = MKAnnotationView(annotation: annotation, reuseIdentifier: STELocationCustomPinIdentifer)
            if isSendingMode {
                pinView?.image = UIImage(named: "LocationMessagePinSmallBackground")
            } else {
                pinView?.image = UIImage(named: "PinLocation")
            }
//            pinView?.centerOffset = CGPoint(x: 0, y: -32)
            pinView?.centerOffset = CGPoint(x: 0, y: -(pinView?.frame.height ?? 0) / 2)
        } else {
            pinView?.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        print("====================== regionWillChangeAnimated")
        shouldAnimationUp = true
        if !isSendingMode { return }
        lbDes.text = "Đang định vị..."
        locationToSend = kCLLocationCoordinate2DInvalid
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        print("====================== regionDidChangeAnimated")
        locationToSend = mapview.centerCoordinate
        shouldAnimationUp = false
        if !isSendingMode { return }
        startAnimationForPinLocation()

        let centerLocation = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
        getPlaceAndDisplay(location: centerLocation)
    }
}
