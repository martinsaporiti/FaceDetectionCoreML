//
//  ViewController.swift
//  Face Detection Core ML
//
//  Created by Martin Saporiti on 22/05/2018.
//  Copyright © 2018 Martin Saporiti. All rights reserved.
//

import UIKit
import Vision

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    @IBOutlet weak var cantFacesLabel: UILabel!
    
    
    var imagePicker : UIImagePickerController? = UIImagePickerController()
    
    
    var facesRectangles : [UIView] = []
    var currentImage : UIImage!
    let imageView : UIImageView = UIImageView()
    let initialImage = UIImage(named: "sample1")
    
    
    let topAnchor : CGFloat = 20
    var portrait : Bool!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.portrait = !UIDevice.current.orientation.isLandscape
        setUpLayout()
        imagePicker?.delegate = self;
        self.loadImageAndDetect(image: #imageLiteral(resourceName: "sample1"))
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.rotated), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)


    }

    @objc func rotated() {
        if UIDevice.current.orientation.isLandscape {
            print("Landscape")
        } else {
            print("Portrait")
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
        imageView.image = image
        self.currentImage = image
       
        let scaledHeight = (view.frame.width / (image.size.width) * (image.size.height))
        imageView.heightAnchor.constraint(equalToConstant: scaledHeight).isActive = true
        
        let request = VNDetectFaceRectanglesRequest { (request, error) in
            if let err = error {
                print("Failed to detect a face: ", err);
                return
            }

            let count : String = String(stringInterpolationSegment: request.results!.count)
            self.cantFacesLabel.text = "Se detectaron: \(count) rostros."

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
    
    
    func clearFaces(){
        self.facesRectangles.forEach { (face) in
            face.removeFromSuperview()
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
    
    
}





