//
//  JoinGroupCodeTextField.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/28/22.
//

import UIKit
import FirebaseFirestore

class JoinGroupCodeTextField: UITextField {
    
    private var digitLabels = [UILabel]()
    private var enterCodeCompletion: (() -> Void)?
    
    private lazy var tapRecognizer: UITapGestureRecognizer = {
        let recognizer = UITapGestureRecognizer()
        recognizer.addTarget(self, action: #selector(becomeFirstResponder))
        return recognizer
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    init(with slotCount: Int, enterCodeCompletion: (() -> Void)?) {
        self.enterCodeCompletion = enterCodeCompletion
        super.init(frame: .zero)
        configure(with: slotCount)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with slotCount: Int = 6) {
        configureTextField()
        
        addGestureRecognizer(tapRecognizer)
        
        let labelsStackView = createLabelsStackView(with: slotCount)
        addSubview(labelsStackView)
        
        NSLayoutConstraint.activate([
            labelsStackView.topAnchor.constraint(equalTo: topAnchor),
            labelsStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            labelsStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            labelsStackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    private func configureTextField() {
        tintColor = .clear
        textColor = .clear
        textContentType = .oneTimeCode
    
        addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        delegate = self
    }
    
    private func createLabelsStackView(with count: Int) -> UIStackView {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = 8
        
        for _ in 1 ... count {
            let label = UILabel()
            
            label.translatesAutoresizingMaskIntoConstraints = false
            label.textAlignment = .center
            label.font = UIFont.boldSystemFont(ofSize: 40)
            label.backgroundColor = .systemGray5
            label.layer.masksToBounds = true 
            label.layer.cornerRadius = 8
            label.isUserInteractionEnabled = true
            
            stackView.addArrangedSubview(label)
            
            digitLabels.append(label)
        }
        return stackView
    }
    
    @objc private func textDidChange() {
        guard let text = self.text, text.count <= digitLabels.count else { return }
        
        for i in 0..<digitLabels.count {
            let currentLabel = digitLabels[i]
            
            if i < text.count {
                let index = text.index(text.startIndex, offsetBy: i)
                currentLabel.text = String(text[index]).uppercased()
            } else {
                currentLabel.text?.removeAll()
            }
        }
    }
    
    private func getUserEnteredCode() -> String {
        var userEnteredCode = ""
        for digitLabel in digitLabels {
            userEnteredCode += digitLabel.text ?? ""
        }
        return userEnteredCode
    }
}

extension JoinGroupCodeTextField: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let characterCount = textField.text?.count else { return false }
        //check to see input only contains alphabets and numbers 
        let allowedCharacters = CharacterSet.alphanumerics
        let characterSet = CharacterSet(charactersIn: string)
        return (characterCount < digitLabels.count || string == "") && (allowedCharacters.isSuperset(of: characterSet))
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let currentUser = FirebaseManager.shared.currentUser else { return false }

        let userEnteredCode = getUserEnteredCode()
        if userEnteredCode.count == digitLabels.count {
            textField.resignFirstResponder()
            
            let db = Firestore.firestore()
            let batch = db.batch()
            
            let groupRef = db.collection(TTConstants.groupsCollection).document(userEnteredCode)
            batch.updateData([
                TTConstants.groupUsers: FieldValue.arrayUnion([currentUser.id])
            ], forDocument: groupRef)
            
            let currentUserRef = db.collection(TTConstants.usersCollection).document(currentUser.id)
            batch.updateData([
                TTConstants.groupCodes: FieldValue.arrayUnion([userEnteredCode])
            ], forDocument: currentUserRef)
            
            batch.commit() { [weak self] error in
                if let _ = error, let enterCodeCompletion = self?.enterCodeCompletion {
                    enterCodeCompletion()
                }
            }
        }
        return false
    }
}
