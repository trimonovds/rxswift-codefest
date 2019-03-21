import RxSwift
import Utils
import Foundation
import UIKit

// Before Rx

//protocol ImageLoader {
//    var image: UIImage? { get }
//    func loadImage(completion: @escaping (UIImage) -> Void)
//}
//
//class ImageLoadinViewController: UIViewController {
//    var imageLoader: ImageLoader!
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        if let loaded = imageLoader.image {
//            imageView.image = loaded
//        } else {
//            activityIndicator.startAnimating()
//            imageLoader.loadImage { [weak self] (img) in
//                self?.activityIndicator.startAnimating()
//                self?.imageView.image = img
//            }
//        }
//    }
//
//    private let activityIndicator = UIActivityIndicatorView()
//    private let imageView = UIImageView()
//}

// After Rx

//protocol ImageLoader {
//    func image() -> Observable<UIImage>
//}
//
//class ImageLoadinViewController: UIViewController {
//    var imageLoader: ImageLoader!
//
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//
//        activityIndicator.startAnimating()
//        imageLoader.image().subscribe(onNext: { [weak self] (img) in
//            self?.activityIndicator.startAnimating()
//            self?.imageView.image = img
//        })
//    }
//
//    private let activityIndicator = UIActivityIndicatorView()
//    private let imageView = UIImageView()
//}

protocol ImageLoader {
    var loadedImage: UIImage? { get }
    func image() -> Observable<UIImage>
}

class ImageLoadinViewController: UIViewController {
    var imageLoader: ImageLoader!

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        activityIndicator.startAnimating()
        imageLoader.image().subscribe(onNext: { [weak self] (img) in
            self?.activityIndicator.startAnimating()
            self?.imageView.image = img
        })
    }

    private let activityIndicator = UIActivityIndicatorView()
    private let imageView = UIImageView()
}
