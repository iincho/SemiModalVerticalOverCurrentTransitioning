import UIKit

final class SemiModalViewController: UIViewController, OverCurrentTransitionable {
    var percentThreshold: CGFloat = 0.3
    var interactor = OverCurrentTransitioningInteractor()

    private var tableViewContentOffsetY: CGFloat = 0.0

    @IBOutlet private weak var headerView: UIView!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var backgroundView: UIView!

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        transitioningDelegate = self
        modalPresentationStyle = .custom
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        transitioningDelegate = self
        modalPresentationStyle = .custom
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        interactor.startHandler = { [weak self] in
            self?.tableView.bounces = false
        }
        interactor.resetHandler = { [weak self] in
            self?.tableView.bounces = true
        }

        setupViews()
    }

    private func setupViews() {
        headerView.layer.cornerRadius = 8.0
        headerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        let headerGesture = UIPanGestureRecognizer(target: self, action: #selector(headerDidScroll(_:)))
        headerView.addGestureRecognizer(headerGesture)

        let gesture = UITapGestureRecognizer(target: self, action: #selector(backgroundDidTap))
        backgroundView.addGestureRecognizer(gesture)

        let tableViewGesture = UIPanGestureRecognizer(target: self, action: #selector(tableViewDidScroll(_:)))
        tableViewGesture.delegate = self
        tableView.addGestureRecognizer(tableViewGesture)
        tableView.delegate = self
        tableView.dataSource = self
    }

    static func make() -> SemiModalViewController {
        let sb = UIStoryboard(name: "SemiModalViewController", bundle: nil)
        let vc = sb.instantiateInitialViewController() as! SemiModalViewController
        return vc
    }

    @objc private func backgroundDidTap() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func headerDidScroll(_ sender: UIPanGestureRecognizer) {
        interactor.updateStateShouldStartIfNeeded()
        handleTransitionGesture(sender)
    }

    @objc private func tableViewDidScroll(_ sender: UIPanGestureRecognizer) {
        if tableViewContentOffsetY <= 0 {
            interactor.updateStateShouldStartIfNeeded()
        }
        interactor.setStartInteractionTranslationY(sender.translation(in: view).y)
        handleTransitionGesture(sender)
    }
}

extension SemiModalViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 30
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "Cell")
        cell.textLabel?.text = String(indexPath.row)
        return cell
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        tableViewContentOffsetY = scrollView.contentOffset.y
    }
}

extension SemiModalViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

extension SemiModalViewController: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return ModalPresentationController(presentedViewController: presented, presenting: presenting)
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DismissAnimator()
    }

    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        switch interactor.state {
        case .hasStarted, .shouldFinish:
            return interactor
        case .none, .shouldStart:
            return nil
        }
    }
}
