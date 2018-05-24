//
//  ViewController.swift
//  Face Detection Core ML
//
//  Created by Martin Saporiti on 22/05/2018.
//  Copyright © 2018 Martin Saporiti. All rights reserved.
//

import UIKit
import Vision
import Firebase

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    @IBOutlet weak var cantFacesLabel: UILabel!
    
    @IBOutlet weak var cantFacesSmiling: UILabel!
    
    @IBOutlet weak var cantFacesLabelMl: UILabel!
    var imagePicker : UIImagePickerController? = UIImagePickerController()
    
    
    var facesRectangles : [UIView] = []
    var currentImage : UIImage!
    let imageView : UIImageView = UIImageView()
    let initialImage = UIImage(named: "sample1")
    
    
    let topAnchor : CGFloat = 20
    var portrait : Bool!
    
    
    // Google ML (Firebase)
    var optionsMLFirebase : VisionFaceDetectorOptions = {
        var options = VisionFaceDetectorOptions()
        options.modeType = .accurate
        options.landmarkType = .all
        options.classificationType = .all
        options.minFaceSize = CGFloat(0.1)
        options.isTrackingEnabled = true
        return options
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.portrait = !UIDevice.current.orientation.isLandscape
        setUpLayout()
        imagePicker?.delegate = self;
        self.loadImageAndDetect(image: #imageLiteral(resourceName: "sample1"))
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.rotated), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }
    
    
    func visionMLSetUp(){
        
    }

    @objc func rotated() {
        if UIDevice.current.orientation.isLandscape {
//            print("Landscape")
        } else {
//            print("Portrait")
        }
    }
    
    
    func visionFaceDetaction(initialImage: UIImage){
        var vision = Vision.vision()
        let faceDetector = vision.faceDetector(options: self.optionsMLFirebase)
        let image = VisionImage(image: initialImage)
        
        
        var countFacesSmiling = 0;
        faceDetector.detect(in: image) { (faces, error) in
            guard error == nil, let faces = faces, !faces.isEmpty else {
                // Error. You should also check the console for error messages.
                // ...
                return
            }
            
            // Faces detected
            // ...
            
            let count: Int = faces.count
            self.cantFacesLabelMl.text =  "Se detectaron: \(count) rostros con Firebase"

            let scaledHeight = (self.view.frame.width / (initialImage.size.width) * (initialImage.size.height))

            for face in faces {
                let frame = face.frame
                
                if face.hasHeadEulerAngleY {
                    let rotY = face.headEulerAngleY  // Head is rotated to the right rotY degrees
                }
                if face.hasHeadEulerAngleZ {
                    let rotZ = face.headEulerAngleZ  // Head is rotated upward rotZ degrees
                }
                
                // If landmark detection was enabled (mouth, ears, eyes, cheeks, and
                // nose available):
                if let leftEye = face.landmark(ofType: .leftEye) {
                    let leftEyePosition = leftEye.position
                }
                
                // If classification was enabled:
                if face.hasSmilingProbability {
                    let smileProb = face.smilingProbability
                    print(smileProb)
                    if(smileProb > 0.75){
                       countFacesSmiling = countFacesSmiling + 1
                    }
                }
                if face.hasRightEyeOpenProbability {
                    let rightEyeOpenProb = face.rightEyeOpenProbability
                }
                
                // If face tracking was enabled:
                if face.hasTrackingID {
                    let trackingId = face.trackingID
                }
            
                let widthRatio = self.imageView.frame.size.width / initialImage.size.width
                let heightRatio = self.imageView.frame.size.height / initialImage.size.height
                
                let greenView = UIView(frame: CGRect(x: face.frame.minX * widthRatio, y: (face.frame.minY * heightRatio) + self.topAnchor, width: face.frame.width * widthRatio, height: face.frame.height * heightRatio))
                
                greenView.backgroundColor = UIColor.green
                greenView.alpha = 0.5
                self.view.addSubview(greenView);
                self.facesRectangles.append(greenView);

            }
            
            self.cantFacesSmiling.text =  "Se detectaron: \(countFacesSmiling) sonrisas"
        }

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    private func  setUpLayout(){
        self.view.addSubview(imageView);
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: self.view.frame.width).isActive = true
        imageView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0)
        imageView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0)
        imageView.topAnchor.constraint(equalTo: view.topAnchor, constant: self.topAnchor).isActive = true
    }

    func loadImageAndDetect(image: UIImage){
        
        self.clearFaces()
        self.visionFaceDetaction(initialImage: image)
        imageView.image = image
        self.currentImage = image
        
        
        // Detección de imágenes utilizando el CoreML
        let scaledHeight = (view.frame.width / (image.size.width) * (image.size.height))
        imageView.heightAnchor.constraint(equalToConstant: scaledHeight).isActive = true
        let request = VNDetectFaceRectanglesRequest { (request, error) in
            if let err = error {
                print("Failed to detect a face: ", err);
                return
            }

            let count : String = String(stringInterpolationSegment: request.results!.count)
            self.cantFacesLabel.text = "Se detectaron: \(count) rostros con CoreML"

            request.results?.forEach({ (res) in

                guard let faceObservation = res as? VNFaceObservation else {return}
                
                let x : CGFloat!;
                let width = self.view.frame.width * faceObservation.boundingBox.width
                let height = scaledHeight * faceObservation.boundingBox.height
                
                let y : CGFloat!;
                if(image.size.width < image.size.height){
                    y = ((scaledHeight * (1 - faceObservation.boundingBox.origin.y) - height))/2
                    x = self.view.frame.width * faceObservation.boundingBox.origin.x
                } else {
                    y = (scaledHeight * (1 - faceObservation.boundingBox.origin.y) - height) + self.topAnchor
                    x = self.view.frame.width * faceObservation.boundingBox.origin.x
                }
                
//                print("=====")
//                print("faceObservation.x: ", faceObservation.boundingBox.origin.x)
//                print("faceObservation.y: ", faceObservation.boundingBox.origin.y)
//
//                print("Red scaledHeight: :", scaledHeight)
//                print("red width: :", width)
//                print("red height: :", height)
//                print("red y: :", y)
//                print("red x: :", x)
//                print("=====")
                
                let redView = UIView(frame: CGRect(x: x, y: y, width: width, height: height))
                redView.backgroundColor = UIColor.red
                redView.alpha = 0.5
                
                self.view.addSubview(redView)
                self.facesRectangles.append(redView);

            })

        }
        
        guard let cgImage = image.cgImage else {return}

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:] )

        do {
            try handler.perform([request])
        } catch let errReq {
            print("Error to perform request: " , errReq)
        }

    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        let selectedImage : UIImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        self.currentImage = selectedImage.fixedOrientation()
        
        loadImageAndDetect(image: self.currentImage)
    }
    
    
    @IBAction func openCamera(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            imagePicker?.sourceType = .camera;
            imagePicker?.allowsEditing = false
            self.present(imagePicker!, animated: true, completion: nil);
        }
    }
    

    @IBAction func openLibrary(_ sender: Any) {
        imagePicker!.allowsEditing = false
        imagePicker!.sourceType = UIImagePickerControllerSourceType.photoLibrary
        self.present(imagePicker!, animated: true, completion: nil)
    }
    
    func clearFaces(){
        self.facesRectangles.forEach { (face) in
            face.removeFromSuperview()
        }
    }
    
}





