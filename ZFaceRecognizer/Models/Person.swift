import UIKit

let host = "http://184.105.225.21/zfacenet"

class Person: NSObject {
    
    struct personCell {
        var name : String!
        var image : UIImage
    }
    
    //helpers for image---------
    
    static func imageOrientation(_ src:UIImage)->UIImage {
        if src.imageOrientation == UIImage.Orientation.up {
            return src
        }
        var transform: CGAffineTransform = CGAffineTransform.identity
        switch src.imageOrientation {
        case UIImage.Orientation.down, UIImage.Orientation.downMirrored:
            transform = transform.translatedBy(x: src.size.width, y: src.size.height)
            transform = transform.rotated(by: CGFloat(Double.pi))
            break
        case UIImage.Orientation.left, UIImage.Orientation.leftMirrored:
            transform = transform.translatedBy(x: src.size.width, y: 0)
            transform = transform.rotated(by: CGFloat(Double.pi / 2))
            break
        case UIImage.Orientation.right, UIImage.Orientation.rightMirrored:
            transform = transform.translatedBy(x: 0, y: src.size.height)
            transform = transform.rotated(by: CGFloat(-Double.pi / 2))
            break
        case UIImage.Orientation.up, UIImage.Orientation.upMirrored:
            break
        }
        
        switch src.imageOrientation {
        case UIImage.Orientation.upMirrored, UIImage.Orientation.downMirrored:
            transform.translatedBy(x: src.size.width, y: 0)
            transform.scaledBy(x: -1, y: 1)
            break
        case UIImage.Orientation.leftMirrored, UIImage.Orientation.rightMirrored:
            transform.translatedBy(x: src.size.height, y: 0)
            transform.scaledBy(x: -1, y: 1)
        case UIImage.Orientation.up, UIImage.Orientation.down, UIImage.Orientation.left, UIImage.Orientation.right:
            break
        }
        
        let ctx:CGContext = CGContext(data: nil, width: Int(src.size.width), height: Int(src.size.height), bitsPerComponent: (src.cgImage)!.bitsPerComponent, bytesPerRow: 0, space: (src.cgImage)!.colorSpace!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        
        ctx.concatenate(transform)
        
        switch src.imageOrientation {
        case UIImage.Orientation.left, UIImage.Orientation.leftMirrored, UIImage.Orientation.right, UIImage.Orientation.rightMirrored:
            ctx.draw(src.cgImage!, in: CGRect(x: 0, y: 0, width: src.size.height, height: src.size.width))
            break
        default:
            ctx.draw(src.cgImage!, in: CGRect(x: 0, y: 0, width: src.size.width, height: src.size.height))
            break
        }
        
        let cgimg:CGImage = ctx.makeImage()!
        let img:UIImage = UIImage(cgImage: cgimg)
        
        return img
    }
    
    static func generateBoundaryString() -> String {
        return "Boundary-\(NSUUID().uuidString)"
    }
    
    static func createBodyWithParameters(parameters: [String: String]?, filePathKey: String?, imageDataKey: Data, boundary: String) -> Data {
        let body = NSMutableData();
        
        let mimetype = "image/jpg"
        
        body.append("------\(boundary)\r\n".data(using: String.Encoding.utf8)!)
        body.append("Content-Disposition:form-data; name=\"file\"; filename=\"tmp.jpg\"\r\n".data(using: String.Encoding.utf8)!)
        body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: String.Encoding.utf8)!)
        body.append(imageDataKey)
        body.append("\r\n".data(using: String.Encoding.utf8)!)
        body.append("------\(boundary)--".data(using: String.Encoding.utf8)!)
        
        return body as Data
    }
    
    //http request method~~~~~~~
    
    class func fetchPeople(image : UIImage, completion : @escaping ([personCell]) -> Void){
        
        let url = URL(string: host)
        let session = URLSession(configuration: .default)
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        
        let boundary = generateBoundaryString()
        request.setValue("multipart/form-data; boundary=----\(boundary)", forHTTPHeaderField: "Content-Type")
        let image_oriented = imageOrientation(image)
        let imageData = UIImageJPEGRepresentation(image_oriented, 1)
        if (imageData == nil){
            print("nil image data")
        }
        let fullData = createBodyWithParameters(parameters:nil, filePathKey: "file", imageDataKey: imageData!, boundary: boundary)
        request.setValue(String(fullData.count), forHTTPHeaderField: "Content-Length")
        request.httpBody = fullData
        request.httpShouldHandleCookies = false
        
        let task = session.dataTask(with: request) { (data, response, error) in
            if (error != nil) {
                print("Failed to get predictions!")
                return
            }
            let result = try? JSONSerialization.jsonObject(with: data!, options: []) as! Dictionary<String, Array<String>>
            let names = result?["names"]
            let urls = result?["urls"]
            
            var people = [personCell]()
            
            for i in stride(from: 0, to: (names?.count)!, by: 1) {
                let imageURL = URL(string: urls![i])
                let image = UIImage(data: try! Data(contentsOf: imageURL!))
                people.append(personCell(name: names![i], image: image!))
            }
            completion(people)
        }
        task.resume()
    }
}
