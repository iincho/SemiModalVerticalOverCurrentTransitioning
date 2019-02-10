import UIKit

class ViewController: UIViewController {

    @IBAction func buttonDidTap(_ sender: Any) {
        let vc = SemiModalViewController.make()
        present(vc, animated: true, completion: nil)
    }
}
