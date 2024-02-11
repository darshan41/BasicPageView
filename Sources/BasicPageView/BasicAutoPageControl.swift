//
//  BasicAutoPageControl.swift
//
//
//  Created by Darshan S on 11/02/24.
//

import Foundation

public class BasicAutoPageControl {
    
    public weak var delegate: BasicAutoPageControlDelegate?
    
    public var autoSwipeInterval: TimeInterval? {
        didSet {
            guard (autoSwipeInterval ?? 0) > 0 else { return }
            self.startTimer()
        }
    }
    
    private var autoSwipe: Timer?
    
    public init(with autoSwipeIntcerval: TimeInterval? = nil) {
        self.autoSwipeInterval = autoSwipeIntcerval
        guard (autoSwipeIntcerval ?? 0) > 0 else { return }
        startTimer()
    }
    
    func startTimer() {
        invalidateTimer()
        guard let interval = autoSwipeInterval else {
            return
        }
        delegate?.willStartTicking(with: interval)
        autoSwipe = Timer.scheduledTimer(
            timeInterval: interval,
            target: self,
            selector: #selector(didSwipe),
            userInfo: nil,
            repeats: false
        )
    }
    
    func invalidateTimer() {
        self.autoSwipe?.invalidate()
        self.autoSwipe = nil
    }
    
    @objc private func didSwipe() {
        self.delegate?.pageViewController.goToNextPage()
        self.startTimer()
    }
}
