//
//  TTProfileImageView.swift
//  TimeTangle
//
//  Created by Justin Wong on 5/22/23.
//

import UIKit

class TTProfileImageView: UIView {
    
    private var profileImageOuterView = UIView()
    private var profileImageView: UIImageView!
    private let profileImageActivityIndicator = UIActivityIndicatorView(style: .medium)
    
    private var image: UIImage!
    
    var showShadow: Bool = false {
        didSet {
            updateShadow()
        }
    }
    
    var showBorder: Bool = false {
        didSet {
            updateImageViewBorderColor()
        }
    }
    
    private var profileImageWidthHeight: CGFloat = 150
    
    init(image: UIImage, widthHeight: CGFloat) {
        profileImageWidthHeight = widthHeight
        self.image = image
        super.init(frame: CGRect(x: 0, y: 0, width: widthHeight, height: widthHeight))
        configureProfileImageView()
    }
    
    convenience init(widthHeight: CGFloat) {
        let config = UIImage.SymbolConfiguration(pointSize: 50)
        let profileImage = UIImage(systemName: "person.crop.circle", withConfiguration: config)
        self.init(image: profileImage!, widthHeight: widthHeight)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureProfileImageView()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        updateImageViewBorderColor()
    }
    
    private func updateImageViewBorderColor() {
        if showBorder {
            if traitCollection.userInterfaceStyle == .dark {
                profileImageView.layer.borderColor = UIColor.white.cgColor
            } else {
                profileImageView.layer.borderColor = UIColor.gray.cgColor
            }
        } else {
            profileImageView.layer.borderColor = UIColor.clear.cgColor
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureProfileImageView() {
        translatesAutoresizingMaskIntoConstraints = false
        
        profileImageOuterView = UIView(frame: CGRect(x: 0, y: 0, width: profileImageWidthHeight, height: profileImageWidthHeight))
        profileImageOuterView.translatesAutoresizingMaskIntoConstraints = false
    
        profileImageView = UIImageView(frame: profileImageOuterView.bounds)
        profileImageView.tintColor = .lightGray
        profileImageView.layer.borderWidth = 1
        profileImageOuterView.addSubview(profileImageView)
        
        profileImageActivityIndicator.color = .white
        profileImageActivityIndicator.center = CGPoint(x: profileImageView.bounds.width / 2, y: profileImageView.bounds.height / 2)
        profileImageActivityIndicator.hidesWhenStopped = true
        profileImageView.addSubview(profileImageActivityIndicator)
        
        profileImageView.image = image 
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.masksToBounds = false
        profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2
        profileImageView.clipsToBounds = true
        addSubview(profileImageOuterView)
        
        NSLayoutConstraint.activate([
            profileImageOuterView.widthAnchor.constraint(equalToConstant: profileImageWidthHeight),
            profileImageOuterView.heightAnchor.constraint(equalToConstant: profileImageWidthHeight),
            
            profileImageOuterView.topAnchor.constraint(equalTo: topAnchor),
            profileImageOuterView.leadingAnchor.constraint(equalTo: leadingAnchor),
            profileImageOuterView.trailingAnchor.constraint(equalTo: trailingAnchor),
            profileImageOuterView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            profileImageView.topAnchor.constraint(equalTo: profileImageOuterView.topAnchor),
            profileImageView.leadingAnchor.constraint(equalTo: profileImageOuterView.leadingAnchor),
            profileImageView.trailingAnchor.constraint(equalTo: profileImageOuterView.trailingAnchor),
            profileImageView.bottomAnchor.constraint(equalTo: profileImageOuterView.bottomAnchor)
        ])
    }
    
    private func updateShadow() {
        if showShadow {
            profileImageOuterView.clipsToBounds = false
            profileImageOuterView.layer.shadowColor = UIColor.black.cgColor
            profileImageOuterView.layer.shadowOpacity = 1
            profileImageOuterView.layer.shadowOffset = CGSize.zero
            profileImageOuterView.layer.shadowRadius = 13
            profileImageOuterView.layer.shadowPath = UIBezierPath(roundedRect: profileImageOuterView.bounds, cornerRadius: profileImageView.frame.size.width / 2).cgPath
        }
    }
    
    //MARK: - Public Methods
    
    func setImageForUser(for user: TTUser) {
        user.getProfilePictureUIImage { [weak self] image in
            guard let image = image else { return }
            self?.profileImageView.image = image
            self?.showBorder = true
        }
    }
    
    func setImage(to image: UIImage) {
        profileImageView.image = image 
        showBorder = true
    }
    
    func setToDefaultImage() {
        let config = UIImage.SymbolConfiguration(scale: .large)
        let profileImage = UIImage(systemName: "person.crop.circle", withConfiguration: config)
        profileImageView.image = profileImage
        showBorder = false
    }
    
    func setShadowColor(to color: CGColor) {
        profileImageOuterView.layer.shadowColor = color 
    }
    
    func startAnimatingProgressIndicator() {
        DispatchQueue.main.async {
            self.profileImageActivityIndicator.startAnimating()
        }
    }
    
    func stopAnimatingProgressIndicator() {
        DispatchQueue.main.async {
            self.profileImageActivityIndicator.stopAnimating()
        }
    }
}
