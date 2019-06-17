//
//  ViewController.swift
//  FlowerApp
//
//  Created by Frank Chen on 2018-10-16.
//  Copyright © 2018 Frank Chen. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    let imagePicker = UIImagePickerController()
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = true
        
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let userPickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage{
        
            guard let convertedCiImage = CIImage(image: userPickedImage) else {
                fatalError("Cannot conver to ciImage")
            }
            detect(image: convertedCiImage)
            
            
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func detect(image: CIImage){
        
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("Cannot importa model")
        }
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let classification = request.results?.first as? VNClassificationObservation else {
                fatalError("Cannot classifiy an image")
            }
            
            self.navigationItem.title =   classification.identifier.capitalized
            self.requestInfo(flowerName: classification.identifier)
            
        }
        let handler = VNImageRequestHandler(ciImage: image)
        
        do{
        try handler.perform([request])
        } catch {
            print(error)
        }
        
    }
    
    //MARK: HTTP REQUEST USING ALAMOFIRE TO GET JSON
 
    func requestInfo(flowerName: String){
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize": "500"
            ]
        Alamofire.request(wikipediaURl, method: .get, parameters: parameters).responseJSON { (response) in
            if response.result.isSuccess {
                print("got the wikipedia info")
                let flowerJSON : JSON = JSON(response.result.value!)
                self.updateFlowerInfo(json: flowerJSON)
                print(flowerJSON)
            }
            else {
                print("Error \(String(describing: response.result.error))")
                self.navigationItem.title = "Connection Issues"
            }
        }
    }
    
    func updateFlowerInfo(json:JSON){
        let pageid = json["query"]["pageids"][0].stringValue
        let flowerInfo = json["query"]["pages"][pageid]["extract"].stringValue
        let flowerImageURL = json["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
        
        updateUI(info: flowerInfo, image: flowerImageURL)
        print(pageid)
        print(flowerImageURL)
    }
    
    func updateUI(info: String, image: String){
        imageLabel.text = info
        imageView.sd_setImage(with: URL(string: image))
    }
    
    
    

    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
    }
    
}

