import UIKit

class Person: NSObject {
    
    static var detectedImage : UIImage? = nil
    
    struct personCell {
        var name : String!
        var image : UIImage
    }
    
    class func fetchPeople(image : UIImage, completion : ([personCell]) -> Void){
        var people = [personCell]()
        people.append(personCell(name: "Z. Chen", image: #imageLiteral(resourceName: "1")))
        people.append(personCell(name: "A. Pendragon", image: #imageLiteral(resourceName: "2")))

        completion(people)
    }

}
