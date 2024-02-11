import XCTest
@testable import BasicPageView

final class BasicPageViewTests: XCTestCase {
    
    private lazy var controllers: [UIViewController] = {
        let controller1 = UIViewController()
        let controller2 = UIViewController()
        let controller3 = UIViewController()
        let controllers: [UIViewController] = [controller1,controller2,controller3]
        return controllers
    }()
    
    override func setUp() {
        super.setUp()
    }
    
    private let pageView = BasicPageView()
    
    func testDelegatation() {
        pageView.autoSwipeDelegate = self
    }
    
    func testGoToNextPage() {
        pageView.goToNextPage()
    }
    
    func testGoToPreviousPage() {
        pageView.goToPreviousPage()
    }
    
    func testAutoSwipeControlStartTimer() {
        let autoSwipeControl = BasicAutoPageControl()
        autoSwipeControl.startTimer()
    }
}

// MARK: PageScrollNotifiable

extension BasicPageViewTests: PageScrollNotifiable {
    
    func inputControllersForController(_ pageViewController: UIPageViewController) -> [UIViewController] {
        self.controllers
    }
    
    func swipeIntervalForController(_ pageViewController: UIPageViewController) -> TimeInterval? {
        2.0
    }
    
    func isCyclicPaginationController(_ pageViewController: UIPageViewController) -> Bool {
        true
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, shouldMoveTo viewController: UIViewController?) -> Bool {
        true
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, willMoveTo viewController: UIViewController?) {
        XCTAssert(viewController != nil)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didMoveTo viewController: UIViewController?) {
        XCTAssert(viewController != nil)
    }
}
