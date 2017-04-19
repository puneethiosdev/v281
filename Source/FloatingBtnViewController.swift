////
////  FloatingBtnViewController.swift
////  edX
////
////  Created by Puneet JR on 30/03/17.
////  Copyright © 2017 edX. All rights reserved.
////
//
//import UIKit
//import LiquidFloatingActionButton
//
//
//class FloatingBtnViewController: UIViewController {
//    
//    var cells = [LiquidFloatingCell]() //datasource
//    var floatinfgActionButton: LiquidFloatingActionButton!
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        createFloatingButton()
//
//    }
//
//    private func createFloatingButton() {
//        cells.append(createButtonCell(iconName: "CameraIcon"))
//        
//        let floatingFrame = CGRect(x: self.view.frame.width - 56 - 16, y: self.view.frame.height - 56 - 16, width: 56, height: 56)
//        
//        let floatingButton = createButton(frame: floatingFrame, style: .up)
//        
//        self.view.addSubview(floatingButton)
//        self.floatingActionButton = floatingButton
//    }
//    
//    
//    private func createButtonCell(iconName: String) -> LiquidFloatingCell {
//        return LiquidFloatingCell(icon: UIImage(named: iconName)!)
//    }
//    
//    private func createButton(frame:CGRect, style: LiquidFloatingActionButtonAnimateStyle) -> LiquidFloatingActionButton {
//        
//        let floatingActionButton = LiquidFloatingActionButton(frame: frame)
//        floatingActionButton.animateStyle = style
//        floatingActionButton.dataSource = self
//        floatingActionButton.delegate = self
//        
//        return floatingActionButton
//    }
//
//}
//
//extension ViewController: LiquidFloatingActionButtonDataSource {
//    
//    func numberOfCells(liquidFloatingActionButton: LiquidFloatingActionButton) -> Int {
//        return cells.count
//    }
//    func cellForIndex(index: Int) -> LiquidFloatingCell {
//        return cells[index]
//    }
//}
//    
//
//
//extension ViewController: LiquidFloatingActionButtonDelegate {
//    func liquidFloatingActionButton(liquidFloatingActionButton: LiquidFloatingActionButton, didSelectItemAtIndex index: Int) {
//        print("You tapped button number \(index)")
//        self.floatingActionButton.close()
//    }
//}
