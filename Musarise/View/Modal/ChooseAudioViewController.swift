//
//  ChooseAudioViewController.swift
//  Musarise
//
//  Created by annaphens on 27/04/2023.
//

import UIKit

class ChooseAudioViewController: UIViewController {

    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var contentView: UIView!
    @IBAction func selectAction(_ sender: UIButton){
        hide()
    }
    @IBAction func chooseAnotherAction(_ sender: UIButton){
        hide()
    }
    
    init(){
        super.init(nibName: "ChooseAudioViewController", bundle: nil)
        self.modalPresentationStyle = .overFullScreen
    }
    
    required init?(coder: NSCoder){
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configView()
    }
    
    func configView(){
        self.view.backgroundColor = .clear
        self.backView.backgroundColor = .black.withAlphaComponent(0.6)
        self.backView.alpha = 0
        self.contentView.alpha = 0
        self.contentView.layer.cornerRadius = 10
    }
    
    // Step 3: Create a function to present the popup modal when the button is pressed.
    func presentPopupModal() {
        // Step 4: Create an instance of the popup modal view controller and set any necessary properties.
        present(self, animated: true, completion: nil)
    }
    
    func appear(sender: UIViewController){
        sender.present(self, animated: false){
            self.show()
        }
    }
    
    private func show(){
        UIView.animate(withDuration: 1, delay: 0.1){
            self.backView.alpha = 1
            self.contentView.alpha = 1
        }
    }
    
    func hide(){
        UIView.animate(withDuration: 1, delay: 0.0, options: .curveEaseOut){
            self.backView.alpha = 0
            self.contentView.alpha = 0
        } completion: { _ in
            self.dismiss(animated: false)
            self.removeFromParent()
        }
    }
}
