//
//  SnapshotButton.swift
//  SXSW Logo
//
//  Created by Dan Murrell on 3/15/18.
//  Copyright © 2018 MutantSoup. All rights reserved.
//

import Foundation
import UIKit

protocol SnapshotButtonDelegate {
    func countdownStarting()
    func countdown(remaining: Int)
    func countdownStopped(at: Int)
    func countdownFinished()
}

extension SnapshotButtonDelegate {
    func countdownStarting() {}
    func countdown(remaining: Int) {}
    func countdownStopped(at: Int) {}
}

@IBDesignable
public class SnapshotButton: UIView {
    let button = UIButton(type: UIButtonType.custom)
    let countLabel = UILabel()
    
    var delegate: SnapshotButtonDelegate?
    var delay: Int = 3
    
    private var countdown: Int = 0
    private var isCounting: Bool = false
    private var timer: Timer?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        configure()
    }
}

private extension SnapshotButton {
    func configure() {
        configureButton()
        configureCountLabel()
    }
    
    func configureButton() {
        button.setImage(UIImage(named: "SnapshotButton"), for: .normal)
        button.contentMode = .scaleAspectFit
        button.addTarget(self, action: #selector(tappedButton), for: .touchUpInside)
        
        addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        button.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        button.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        button.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        button.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
    }
    
    func configureCountLabel() {
        countLabel.font = UIFont.boldSystemFont(ofSize: 12)
        countLabel.text = ""
        countLabel.textAlignment = .center
        countLabel.textColor = UIColor.black
        
        addSubview(countLabel)
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        
        countLabel.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        countLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        countLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        countLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
    }
}

private extension SnapshotButton {
    @objc func tappedButton() {
        if isCounting && countdown > 0 {
            delegate?.countdownStopped(at: countdown)
            stopCountdown()
        } else {
            startCountdown()
        }
    }
    
    func startCountdown() {
        countdown = delay
        countLabel.text = "\(countdown)"
        isCounting = true
        delegate?.countdownStarting()
        delegate?.countdown(remaining: countdown)
        startTimer()
    }
    
    func stopCountdown() {
        countLabel.text = ""
        isCounting = false
        stopTimer()
    }
}

private extension SnapshotButton {
    func startTimer() {
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { timer in
            DispatchQueue.main.async {
                self.countdown -= 1
                self.countLabel.text = "\(self.countdown)"
                self.delegate?.countdown(remaining: self.countdown)
                
                if self.countdown == 0 {
                    self.stopCountdown()
                    self.delegate?.countdownFinished()
                }
            }
        })
    }
    
    func stopTimer() {
        timer?.invalidate()
    }
}
