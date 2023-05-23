//
//  TTProfileImageView.swift
//  TimeTangle
//
//  Created by Justin Wong on 5/22/23.
//

import UIKit

class TTProfileAvatarView: UIView {
    
    private var profileImageOuterView = UIView()
    private var profileImageView: UIImageView!
    private let profileImageActivityIndicator = UIActivityIndicatorView(style: .medium)
    
    private var profileImageWidthHeight: CGFloat = 150
    
    init(widthHeight: CGFloat) {
        profileImageWidthHeight = widthHeight
        super.init(frame: CGRect(x: 0, y: 0, width: widthHeight, height: widthHeight))
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame )
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureProfileImageView() {
        profileImageOuterView = UIView(frame: CGRect(x: 0, y: 0, width: profileImageWidthHeight, height: profileImageWidthHeight))
        profileImageOuterView.clipsToBounds = false
        profileImageOuterView.layer.shadowColor = UIColor.black.cgColor
        profileImageOuterView.layer.shadowOpacity = 1
        profileImageOuterView.layer.shadowOffset = CGSize.zero
        profileImageOuterView.layer.shadowRadius = 13
        profileImageOuterView.translatesAutoresizingMaskIntoConstraints = false
    
        profileImageView = UIImageView(frame: profileImageOuterView.bounds)
 
        profileImageOuterView.layer.shadowPath = UIBezierPath(roundedRect: profileImageOuterView.bounds, cornerRadius: profileImageView.frame.size.width / 2).cgPath
        profileImageOuterView.addSubview(profileImageView)
        
        profileImageActivityIndicator.color = .lightGray
        profileImageActivityIndicator.center = CGPoint(x: profileImageView.bounds.width / 2, y: profileImageView.bounds.height / 2)
        profileImageActivityIndicator.hidesWhenStopped = true
        profileImageView.addSubview(profileImageActivityIndicator)
        
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
//        setProfileImage()
        profileImageView.layer.borderWidth = 5.0
        profileImageView.layer.masksToBounds = false
        profileImageView.layer.borderColor = UIColor.lightGray.cgColor
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2
        profileImageView.clipsToBounds = true
        addSubview(profileImageOuterView)
        
        NSLayoutConstraint.activate([
            profileImageOuterView.centerXAnchor.constraint(equalTo: centerXAnchor),
            profileImageOuterView.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            profileImageOuterView.widthAnchor.constraint(equalToConstant: profileImageWidthHeight),
            profileImageOuterView.heightAnchor.constraint(equalToConstant: profileImageWidthHeight),
            
            profileImageView.topAnchor.constraint(equalTo: profileImageOuterView.safeAreaLayoutGuide.topAnchor),
            profileImageView.leadingAnchor.constraint(equalTo: profileImageOuterView.leadingAnchor),
            profileImageView.trailingAnchor.constraint(equalTo: profileImageOuterView.trailingAnchor),
            profileImageView.bottomAnchor.constraint(equalTo: profileImageOuterView.bottomAnchor)
        ])
    }
}
