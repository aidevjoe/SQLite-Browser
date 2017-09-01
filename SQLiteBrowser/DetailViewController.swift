import UIKit

class DetailViewController: UIViewController {

    var value: String = ""
    
    private lazy var label: UILabel = {
        let view = UILabel()
        view.frame = self.view.frame
        view.textColor = .black
        view.textAlignment = .center
        view.numberOfLines = 0
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        view.addSubview(label)
        label.text = value
    }
}
