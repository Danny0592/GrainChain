//
//  UIVCMapViewController.swift
//  GrainChain
//
//  Created by daniel ortiz millan on 06/05/24.
//

import UIKit
import SwiftUI
import GoogleMaps
import CoreLocation
import SwiftData
import CoreData

class MapViewController: UIViewController, CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate {
    
    let context = PersistenceController.shared.container.viewContext
    
    
    private var mapView : GMSMapView!
    private var isRecording = false //para controlar el estado del recorrido
    private var hasRecorded = false
    private let locationManager = CLLocationManager()
    private var locations: [CLLocation] = []
    private let saveButton = UIButton(type: .system)
    private let button = UIButton(type: .system) //Boton para grabar
    private var routeDetails = [Route]() //
    private var starRecordingDate: Date = .now //
    private var endRecordingDate: Date = .now //
    private var pathPolyline: GMSPolyline?
    private var coordinates = [CLLocation]()
    var tableView: UITableView!//
    
    let nameLabel = UILabel()
    let distanceLabel = UILabel()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        //mapa
        let camera: GMSCameraPosition = GMSCameraPosition.camera(withLatitude: 19.640436, longitude: -99.097681, zoom: 15)
        mapView = GMSMapView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height / 2), camera: camera)
        view.addSubview(mapView)
        
        //tabla
        tableView = UITableView(frame:  CGRect(x: 0, y: view.frame.height / 2, width: view.frame.width, height: view.frame.height / 2))
        tableView.backgroundColor = .white
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "RouteCell")
        
        
        //Botón para Grabar
        button.setTitle("Start", for: .normal)
        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(button)
        
        NSLayoutConstraint.activate([
            button.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            button.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 16)
        ])
        
        // Configurar CLLocationManager
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    @objc func buttonAction() {
        isRecording.toggle()
        let buttonTitle = isRecording ? "Stop Recording" : "Sstar Recording"
        button.setTitle(buttonTitle, for: .normal)
        if isRecording {
            startTour()
        } else {
            stopTour()
        }
    }
    
    func startTour() {
        print("Iniciando recorrido...")
        
        // Registra la fecha de inicio
        let startDate = Date()
        print(startDate)
        
        // Agregar marcador de inicio de ruta
        let location = locationManager.location
        if let currentLocation = location {
            addMarker(at: currentLocation)
        } else {
        }
    }
    
    func stopTour() {
        print("Deteniendo recorrido...")
        
        // Registra la fecha de fin
        let endDate = Date()
        print(endDate)
        
        // distancia recorrida en kilometros con 3 decimales
        let distanceInMeters = calculateDistance()
        let distanceInKilometers = Double(distanceInMeters) / 1000.0
        let formattedDistance = String(format: "%.3f", distanceInKilometers)
        print("Distancia total recorrida: \(formattedDistance) kilómetros")
        
        // Crea el cuadro de texto
        let alertController = UIAlertController(title: "Nombre de la ruta", message: "Ingresa el nombre de la ruta", preferredStyle: .alert)
        alertController.addTextField { (textField) in
            textField.placeholder = "Nombre"
            
            // Agrega acciones al cuadro de texto
            let saveAction = UIAlertAction(title: "Guardar", style: .default) { (_) in
                if let userRouteName = alertController.textFields?.first?.text, !userRouteName.isEmpty {
                    // Despues de la validación, el usuario ingresa el nombre de la ruta
                    saveRouteWithName(userRouteName)
                } else {
                    showAlert(message: "Please, add a name for the Route.")
                }
                // Llama a la función para limpiar el mapa
               // self.clearRute()
            }
            
            let cancelAction = UIAlertAction(title: "Cancell", style: .cancel, handler: nil)
            
            alertController.addAction(saveAction)
            alertController.addAction(cancelAction)
            
            self.present(alertController, animated: true, completion: nil)
        }
        
        // funcion que almacena el nombre de la ruta y la distancia recorrida
        
        func saveRouteWithName(_ routeName: String) {
                    guard !coordinates.isEmpty else { return }
                    let newRoute = Route(context: context)
                    newRoute.nameOfRoute = routeName
                    newRoute.distance = calculateDistance()
            
            do {
                try context.save()
                print("Ruta guardada correctamente")
            } catch {
                print("Error al guardar la ruta: \(error)")
            }
//            recarga los datos
            routeDetails.append(newRoute)
            clearRute()
                        tableView.reloadData()
            
         func fetchRoutes() {
                do {
                    routeDetails = try context.fetch(Route.fetchRequest()) as? [Route] ?? []
                    tableView.reloadData()
                } catch {
                    print("Error al recuperar las rutras: \(error)")
                }
            }

        
        
//        func saveRouteWithName(_ routeName: String) {
//            //Constante que tien el valor de mi modelo
//            let route = Route(nameOfRoute: routeName, distance: calculateDistance(), startDate: starRecordingDate, endDate: endRecordingDate, points: locations)
            
            routeDetails.append(newRoute)
            showAlert(message: "The route have been saved as \(routeName)")
            tableView.reloadData()
            print(routeDetails)
        }
        
        func showAlert(message: String) {
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
        
        // Lógica para detener el recorrido en el mapa
        isRecording = false
        let location = locationManager.location
        if let currentLocation = location {
            addMarker(at: currentLocation)
        } else {
        }
        
    }
    // funcion para pintar un marcador
    private func addMarker(at coordinate: CLLocation) {
        let marker = GMSMarker()
        marker.position = coordinate.coordinate
        marker.map = mapView
    }
    
    //funcion para pintar la linea (polyLine)
    struct Marker: Identifiable {
        let id: Int
        let location: CLLocationCoordinate2D
    }
    
    //funcion para pintar la linea (polyLine)
    func updatePolyline(with locations: [CLLocation]) {
        let path = GMSMutablePath()
        for coordinate in locations {
            path.add(coordinate.coordinate)
            
            let polyline = GMSPolyline(path: path)
            polyline.strokeColor = .systemPink
            polyline.strokeWidth = 3.0
            polyline.map = mapView
        }
    }
    
    func clearRute() {
        // Elimina todos los marcadores del mapa
        mapView.clear()
        // Limpia el array de coordenadas
        coordinates.removeAll()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isRecording, let location = locations.last else { return }
        // Agregar la ubicación actual a la ruta si se está realizando el recorrido
        if isRecording {
            addLocationToRoute(location)
            
            //simular la ruta
            let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude, longitude: location.coordinate.longitude, zoom: 15)
            mapView.animate(to: camera)
        }
    }
    
    //funcion para medir la distancia recorrida
    func calculateDistance() -> CLLocationDistance {
        var totalDistance: CLLocationDistance = 0
        // Verificar si hay al menos dos coordenadas para calcular la distancia
        guard coordinates.count >= 2 else {
            print("No hay suficientes coordenadas para calcular la distancia.")
            return 0
        }
        // Iterar sobre las coordenadas para calcular la distancia
        for i in 0..<coordinates.count - 1 {
            let coordinate1 = coordinates[i]
            let coordinate2 = coordinates[i + 1]
            let distance = coordinate1.distance(from: coordinate2)
            totalDistance += distance
        }
        return totalDistance
    }
    
    func addLocationToRoute(_ coordinate: CLLocation) {
        coordinates.append(coordinate)
        updatePolyline(with: coordinates)
    }
    //    funcion para la tableView
    
    //    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    //        5
    //    }
    //    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    //        return UITableViewCell()
    //    }
    class RouteTableViewCell: UITableViewCell {
        let nameLabel = UILabel()
//        let distanceLabel = UILabel()
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            configureLabels()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func configureLabels() {
            // Configura la etiqueta para el nombre de la ruta
            nameLabel.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(nameLabel)
            NSLayoutConstraint.activate([
                nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
                nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
            ])
            
            // Configura la etiqueta para la distancia recorrida
//            distanceLabel.translatesAutoresizingMaskIntoConstraints = false
//            contentView.addSubview(distanceLabel)
//            NSLayoutConstraint.activate([
//                distanceLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
//                distanceLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
//                distanceLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
//                distanceLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
//            ])
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return routeDetails.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RouteCell", for: indexPath)
        let route1 = routeDetails[indexPath.row]
        cell.textLabel?.text = route1.nameOfRoute
        cell.detailTextLabel?.text = "distance: \(route1.distance) km"
        return cell
    }
    

}

// Vista de los datos debajo del mapa (reemplaza esto con tus datos reales)
struct DatosView: View {
    var body: some View {
        Text("Aquí van tus datos")
            .font(.title)
            .foregroundColor(.blue)
    }
}




struct MapViewControllerBridge: UIViewControllerRepresentable {
    
    func makeUIViewController(context: Context) -> MapViewController {
        return MapViewController()
    }
    func updateUIViewController(_ uiViewController: MapViewController, context: Context) {
    }
}

/* 
 que es y cual es la deiferencia
 
 1. cual es la diferencia entre una clase y una estructura
 2. delegado y protocolo
 3. que significa ARC y como funciona en IOS
 4. como utilizar view controller de  en swuiftUI
 que es un opcional ? en swift (bainding)
 que es un type inference R= infiere que tipo de datoes
 Cual es la sentencia guard en Swift?
 cual es la diferencia entre un if let y un guard
 cual es el roll de los viewController en IOS
 que es el Model View Controller MVC
 mvc
 mvp
 mvvm
 viper
 tdd
 cuantos tipos de patrones de diseño existen y cuales son R= 3
 que es inyeccion de dependencias y como se utilizan en swift
 cual es el ciclo de vida de una aplicacion
 
 */

