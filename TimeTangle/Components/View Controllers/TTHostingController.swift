//
//  TTHostingController.swift
//  TimeTangle
//
//  Created by Justin Wong on 5/25/23.
//

import SwiftUI

class TTHostingController<ContentView: View>: UIHostingController<ContentView> {
    
    override func viewDidAppear(_ animated: Bool) {
      super.viewDidAppear(true)
      navigationController?.setNavigationBarHidden(true, animated: false)
    }
}
