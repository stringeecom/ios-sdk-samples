//
//  SampleConversationViewController.swift
//  ChatSampleSwift
//
//  Created by HoangDuoc on 1/2/19.
//  Copyright © 2019 HoangDuoc. All rights reserved.
//

import UIKit

class SampleConversationViewController: STEConversationViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let imageView = UIImageView(image: UIImage(named: "chat_background.jpg"))
        imageView.frame = UIScreen.main.bounds
        imageView.contentMode = .scaleAspectFill
        self.view.insertSubview(imageView, at: 0)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
