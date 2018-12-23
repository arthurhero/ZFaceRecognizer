import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var people : [Person.personCell] = [Person.personCell]()
    
    let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: [CIDetectorAccuracy : CIDetectorAccuracyHigh])

    @IBOutlet weak var mainImageView: UIImageView!
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        mainImageView.transform = mainImageView.transform.rotated(by: .pi/2)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if (stalk && rect != nil) {
            let cropped_raw = raw.cropped(to: rect!)
            let ciContext = CIContext()
            let cgImage = ciContext.createCGImage(cropped_raw, from: cropped_raw.extent)
            res = UIImage(cgImage: cgImage!)
            
            /*
            let allFeatures = faceDetector?.features(in: raw, options: nil)
            
            if (!allFeatures!.isEmpty) {
                print("we are here!")
                guard let features = allFeatures else { return }
                let feature = features[0]
                if let faceFeature = feature as? CIFaceFeature {
                    let faceRect = faceFeature.bounds
                    let cropped_raw = raw.cropped(to: faceRect)
                    res = UIImage(ciImage: cropped_raw)
                }
 
            } else {
                print("we are not here!")
            }
             */
            mainImageView.image = res!
            Person.fetchPeople(image: res!) { (persons) in
                self.people=persons
                self.tableView.reloadData()
            }
        } else {
            mainImageView.image = UIImage(ciImage: raw)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK - table view methods

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return people.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! personTableViewCell
        cell.nameLabel.text = people[indexPath.row].name
        cell.photoImageView.image = people[indexPath.row].image
        
        cell.selectionStyle = .none
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

}

