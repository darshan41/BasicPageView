// The Swift Programming Language
// https://docs.swift.org/swift-book

#if canImport(UIKit)

import UIKit

public protocol PageRequesterDelegate: UIViewController {
    
    /// Also Calls Asks shouldMoveTo Controller { if false no movement }
    func goToNextPage()
    /// Also Calls Asks shouldMoveTo Controller { if false no movement }
    func goToPreviousPage()
}

public protocol BasicAutoPageControlDelegate: PageRequesterDelegate {
    
    var pageViewController: UIPageViewController { get }
    
    func pageViewNextViewController() -> UIViewController?
    func pageViewPreviousViewController() -> UIViewController?
    func goToNextPage()
    func goToPreviousPage()
    
    func willStartTicking(with fedInterval: TimeInterval)
}

public extension BasicAutoPageControlDelegate {
    
    func pageViewNextViewController() -> UIViewController? { nil }
    func pageViewPreviousViewController() -> UIViewController? { nil }
    
    func willStartTicking(with fedInterval: TimeInterval) { }
}

public protocol PageScrollNotifiable: AnyObject {
    
    func inputControllersForController(_ pageViewController: UIPageViewController) -> [UIViewController]
    
    func swipeIntervalForController(_ pageViewController: UIPageViewController) -> TimeInterval?
    
    func isCyclicPaginationController(_ pageViewController: UIPageViewController) -> Bool
    
    func pageViewController(_ pageViewController: UIPageViewController, shouldMoveTo viewController: UIViewController?) -> Bool
    
    func pageViewController(_ pageViewController: UIPageViewController, willMoveTo viewController: UIViewController?)
    func pageViewController(_ pageViewController: UIPageViewController, didMoveTo viewController: UIViewController?)
    
    func willStartTicking(with fedInterval: TimeInterval)
}

public extension PageScrollNotifiable {
    
    func pageViewController(_ pageViewController: UIPageViewController, shouldMoveTo viewController: UIViewController?) -> Bool { true }
    func pageViewController(_ pageViewController: UIPageViewController, willMoveTo viewController: UIViewController?) { }
    func pageViewController(_ pageViewController: UIPageViewController, didMoveTo viewController: UIViewController?) { }
    
    func swipeIntervalForController(_ pageViewController: UIPageViewController) -> TimeInterval? { nil }
    func isCyclicPaginationController(_ pageViewController: UIPageViewController) -> Bool { false }
    
    func willStartTicking(with fedInterval: TimeInterval) { }
}

// MARK: - BasicScrollControlable

public class BasicPageView: UIPageViewController {
    
    private lazy var autoSwipeControl: BasicAutoPageControl = {
        let control = BasicAutoPageControl()
        guard let interval = self.autoSwipeTimeInterval else { return control }
        control.autoSwipeInterval = interval
        return control
    }()
    
    private var startTimerDispatchWork: DispatchWorkItem?
    private let bQueue: DispatchQueue = .init(label: "PageControl.bQueue", qos: .background)
    
    public private (set)var controllers = [UIViewController]()
    public private (set)var isCyclic: Bool = false
    public private (set)var autoSwipeTimeInterval: TimeInterval? = 0 {
        didSet {
            autoSwipeControl.autoSwipeInterval = self.autoSwipeTimeInterval
        }
    }
    
    public weak var autoSwipeDelegate: PageScrollNotifiable?
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let autoSwipeTimeInterval = autoSwipeTimeInterval,autoSwipeTimeInterval > 0 {
            autoSwipeControl.invalidateTimer()
        }
        super.touchesBegan(touches, with: event)
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        startTimerDispatchWork?.cancel()
        super.touchesMoved(touches, with: event)
        let item = DispatchWorkItem { [weak self] in
            if let autoSwipeTimeInterval = self?.autoSwipeTimeInterval,autoSwipeTimeInterval > 0 {
                DispatchQueue.main.async { [weak self] in
                    self?.autoSwipeControl.startTimer()
                }
            }
        }
        self.startTimerDispatchWork = item
        bQueue.asyncAfter(deadline: .now() + .milliseconds(500), execute: item)
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        startTimerDispatchWork?.cancel()
        super.touchesEnded(touches, with: event)
        let item = DispatchWorkItem { [weak self] in
            if let autoSwipeTimeInterval = self?.autoSwipeTimeInterval,autoSwipeTimeInterval > 0 {
                DispatchQueue.main.async { [weak self] in
                    self?.autoSwipeControl.startTimer()
                }
            }
        }
        self.startTimerDispatchWork = item
        bQueue.asyncAfter(deadline: .now() + .milliseconds(500), execute: item)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    public override func goToNextPage() {
        guard let nextcontroller = pageViewNextViewController(),(autoSwipeDelegate == nil) || autoSwipeDelegate?.pageViewController(self, shouldMoveTo: nextcontroller) == true else { return }
        autoSwipeControl.startTimer()
        autoSwipeDelegate?.pageViewController(self, willMoveTo: nextcontroller)
        autoSwipeDelegate?.pageViewController(self, didMoveTo: nextcontroller)
        DispatchQueue.main.async {
            self.setViewControllers([nextcontroller], direction: .forward, animated: true)
        }
    }
    
    public override func goToPreviousPage() {
        guard let previouscontroller = pageViewPreviousViewController(),(autoSwipeDelegate == nil) || autoSwipeDelegate?.pageViewController(self, shouldMoveTo: previouscontroller) == true else { return }
        autoSwipeControl.startTimer()
        autoSwipeDelegate?.pageViewController(self, willMoveTo: previouscontroller)
        autoSwipeDelegate?.pageViewController(self, didMoveTo: previouscontroller)
        DispatchQueue.main.async {
            self.setViewControllers([previouscontroller], direction: .reverse, animated: true)
        }
    }
    
    deinit {
        autoSwipeControl.invalidateTimer()
        print("BasicPageView")
    }
}

// MARK: - UIPageViewControllerDelegate

extension BasicPageView: UIPageViewControllerDelegate { }

// MARK: - UIPageViewControllerDataSource

extension BasicPageView: UIPageViewControllerDataSource {
        
    public func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed else { return }
        autoSwipeDelegate?.pageViewController(self, didMoveTo: pageViewController.viewControllers?.first)
    }
    
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if let firstIndex = controllers.firstIndex(of: viewController),
           let previousController = controllers[safe: firstIndex - 1] {
            return previousController
        } else if self.isCyclic,let lastController = controllers.last {
            return lastController
        }
        return nil
    }
    
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if let firstIndex = controllers.firstIndex(of: viewController),
           let nextController = controllers[safe: firstIndex + 1] {
            return nextController
        } else if self.isCyclic,let firstController = controllers.first {
            return firstController
        }
        return nil
    }
}

// MARK: - BasicAutoPageControlDelegate

extension BasicPageView: BasicAutoPageControlDelegate {
    
    public var pageViewController: UIPageViewController { self }
    
    public func pageViewNextViewController() -> UIViewController? {
        guard let currentViewController = self.viewControllers?.first else { return nil }
        return dataSource?.pageViewController(self, viewControllerAfter: currentViewController)
    }
    
    public func pageViewPreviousViewController() -> UIViewController? {
        guard let currentViewController = self.viewControllers?.first else { return nil }
        return dataSource?.pageViewController(self, viewControllerBefore: currentViewController)
    }
    
    public func willStartTicking(with fedInterval: TimeInterval) {
        autoSwipeDelegate?.willStartTicking(with: fedInterval)
    }
}

// MARK: - Helper func's

private extension BasicPageView {
    
    func setup() {
        self.gestureRecognizers.forEach({ $0.cancelsTouchesInView = false })
        self.view.isMultipleTouchEnabled = true
        guard let controllers = autoSwipeDelegate?.inputControllersForController(self),!controllers.isEmpty else { return }
        self.controllers = controllers
        delegate = self
        dataSource = self
        guard let firstController = self.controllers.first else { return }
        self.setViewControllers([firstController], direction: .forward, animated: true)
        /// By the
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.autoSwipeDelegate?.pageViewController(self, willMoveTo: firstController)
            self.autoSwipeDelegate?.pageViewController(self, didMoveTo: firstController)
        }
        self.isCyclic = autoSwipeDelegate?.isCyclicPaginationController(self) ?? false
        if let interval = autoSwipeDelegate?.swipeIntervalForController(self),interval > 0 {
            autoSwipeControl.delegate = self
            autoSwipeTimeInterval = interval
        }
    }
}

// MARK: @objc func's

@objc public extension UIPageViewController {

    func goToNextPage() {
       guard let currentViewController = self.viewControllers?.first else { return }
       guard let nextViewController = dataSource?.pageViewController(self, viewControllerAfter: currentViewController ) else { return }
        DispatchQueue.main.async {
            self.setViewControllers([nextViewController], direction: .forward, animated: false, completion: nil)
        }
    }

    func goToPreviousPage() {
       guard let currentViewController = self.viewControllers?.first else { return }
       guard let previousViewController = dataSource?.pageViewController( self, viewControllerBefore: currentViewController ) else { return }
        DispatchQueue.main.async {
            self.setViewControllers([previousViewController], direction: .reverse, animated: false, completion: nil)
        }
    }
}

#endif
