//
//  QRCViewController.swift
//  edX
//
//  Created by Puneet JR on 23/03/17.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit
import AVFoundation
import Foundation

class QRCViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    @IBOutlet weak var lblQRCodeResult: UILabel!
    
    var objCaptureSession:AVCaptureSession?
    var objCaptureVideoPreviewLayer:AVCaptureVideoPreviewLayer?
    var viewQRCodeFrame:UIView?
    
//    var environment: RouterEnvironment?
    lazy var environment = Environment()
    
    struct Environment {
        let analytics = OEXRouter.sharedRouter().environment.analytics
        let config = OEXRouter.sharedRouter().environment.config
        let interface = OEXRouter.sharedRouter().environment.interface
        let networkManager = OEXRouter.sharedRouter().environment.networkManager
        let session = OEXRouter.sharedRouter().environment.session
        let userProfileManager = OEXRouter.sharedRouter().environment.dataManager.userProfileManager
        weak var router = OEXRouter.sharedRouter()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.configureVideoCapture()
        self.addVideoPreviewLayer()
        self.initializeQRView()
    }
    
    func configureVideoCapture() {
        //Get an instance of the AVCaptureDevice class to initialize a device object and provide the video as the media type parameter.
        let objCaptureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        var error:NSError?
        let objCaptureDeviceInput: AnyObject!
        
        do {
            //Get an instance of the AVCaptureDeviceInput class using the previous device object.
            objCaptureDeviceInput = try AVCaptureDeviceInput(device: objCaptureDevice) as AVCaptureDeviceInput
        } catch let error1 as NSError {
            error = error1
            objCaptureDeviceInput = nil
            //If any error occurs, just print it out and don't continue any more.
            print(error)
            return
        }
        
        if (error != nil) {
            let alertview:UIAlertView = UIAlertView(title: "Device Error", message: "Device not supported for this Application", delegate: nil, cancelButtonTitle: "Ok Done")
            alertview.show()
            return
        }
        
        //Initialize the objCaptureSession object.
        objCaptureSession = AVCaptureSession()
        //Set the input device on the objCaptureSession.
        objCaptureSession?.addInput(objCaptureDeviceInput as! AVCaptureInput)
        //Initialize a AVCaptureMetadataOutput object and set it as the output device to the objCaptureSession.
        let objCaptureMetadataOutput = AVCaptureMetadataOutput()
        objCaptureSession?.addOutput(objCaptureMetadataOutput)
        //Set delegate and use the default dispatch queue to execute the call back
        objCaptureMetadataOutput.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
//        objCaptureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        //Detect the QR Code
        objCaptureMetadataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
    }
    
    
    func addVideoPreviewLayer() {
        //Initialize the objCaptureVideoPreviewLayer and add it as a sublayer to the viewPreview view's layer.
        objCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: objCaptureSession)
        objCaptureVideoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        objCaptureVideoPreviewLayer?.frame = view.layer.bounds
        self.view.layer.addSublayer(objCaptureVideoPreviewLayer!)
        
        //Start video capture
        objCaptureSession?.startRunning()
        
        //Move the lblQRCodeResult to the top view
        self.view.bringSubviewToFront(lblQRCodeResult)
    }
    
    
    func initializeQRView() {
        //Initialize QR Code Frame(viewQRCode) to highlight the QR Code
        viewQRCodeFrame = UIView()
        viewQRCodeFrame?.layer.borderColor = UIColor.greenColor().CGColor
        viewQRCodeFrame?.layer.borderWidth = 5
        
        self.view.addSubview(viewQRCodeFrame!)
        //Move the viewQRCodeFrame subview to the topview
        self.view.bringSubviewToFront(viewQRCodeFrame!)
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        //Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects == nil || metadataObjects.count == 0 {
            viewQRCodeFrame?.frame = CGRect.zero
            lblQRCodeResult.text = "No QR Code text detected"
            return
        }
        
        //Get the metadata object.
        let objMetadataMachineReadableCodeObject = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        //Check if the type of objMetadataMachineReadableCodeObject is AVMetadataObjectTypeQRCode type.
        if objMetadataMachineReadableCodeObject.type == AVMetadataObjectTypeQRCode {
            //If the found metadata is equal to the QR Code metadata then update the status label's text and set the bounds.
            let objQRCode = objCaptureVideoPreviewLayer?.transformedMetadataObjectForMetadataObject(objMetadataMachineReadableCodeObject)
            
            viewQRCodeFrame?.frame = objQRCode!.bounds;
            
            if objMetadataMachineReadableCodeObject.stringValue != nil {
                lblQRCodeResult.text = objMetadataMachineReadableCodeObject.stringValue
                
                
                var pointsArr = lblQRCodeResult.text!.componentsSeparatedByString(",")
                print("PointsArr = ",pointsArr[0],pointsArr[1],pointsArr[2])
                
                
                let courseID: String? = pointsArr[0]
                let BlockID: CourseBlockID? = pointsArr[1]
                let typeString: String? = pointsArr[2]
                let type: CourseBlockDisplayType?
//                let type = CourseBlockDisplayType.HTML(.Base)
                
                if (typeString == "CourseBlockDisplayType.Outline") {
                    type = CourseBlockDisplayType.Outline
                } else if typeString ==  "CourseBlockDisplayType.HTML(.Base)" {
                    type = CourseBlockDisplayType.HTML(.Base)
                } else if typeString == "CourseBlockDisplayType.HTML(.Problem)" {
                    type = CourseBlockDisplayType.HTML(.Problem)
                } else if typeString == "CourseBlockDisplayType.Video" {
                    type = CourseBlockDisplayType.Video
                } else if typeString == "CourseBlockDisplayType.Unit" {
                    type = CourseBlockDisplayType.Unit
                } else {
                    type = CourseBlockDisplayType.Unknown
                }
                
                
                //without viewcontroller argument
//                environment.router?.controllerForBlockIDString(BlockID!, courseID: courseID!, type: type!)
                
                //with viewcontroller argument
                environment.router?.controllerForBlockIDString(BlockID!, courseID: courseID!, fromController: self, type: type!)
                
                //within the UIViewcontroller with no contain
//                environment.router?.showContainerForBlockWithID(BlockID, type:type!, parentID: BlockID, courseID: courseID!, fromController:self)
                
                objCaptureSession?.stopRunning()
                
            }
            
        }
        
    }
}
    
    
    
    
    
// Latest - commented code 6/4/2017
    
    
    
    
    //                let type: CourseBlockDisplayType = CourseBlockDisplayType(typeString)
    
    //                let parent: String? = pointsArr[2]
    //                let block: String? = pointsArr[2]
    
    //                environment.router?.showContainerForBlockWithID(BlockID, type:CourseBlockDisplayType.HTML(.Problem), parentID: nil, courseID: courseID!, fromController:self)
    
    //                environment.router?.controllerForBlockIDString(BlockID!, courseID: courseID!, type: CourseBlockDisplayType.HTML(.Problem))
    
    
    //                environment.router?.controllerForBlockWithID(block.blockID, type: block.displayName, courseID: courseID)
    
    //                environment.router?.controllerForBlock(block!, courseID: courseID!)
    
    //"block-v1:CI+CI8D+2016+type@sequential+block@22d511c75da34249a420131852eedcc2"//pointsArr[1] //"block-v1:ASMx+IoT101+2016_T1+type@problem+block@af1b24a0fac947659f976477b43d6ea8"
    
    
    //                environment.router?.showCoursewareForCourseWithID(courseID!, fromController: self)
    
    //                environment.router?.showCoursewareForCourseWithID(courseID!, blockID: BlockID, fromController: self)
    //                environment.router?.showContainerForBlockWithID(BlockID, type: CourseBlockDisplayType.Outline, parentID: nil, courseID: courseID!, fromController: self)
    
    //                environment.router?.showCourseForScanID(courseID!, blockID: BlockID, type : CourseBlockDisplayType.Outline, fromController: self)
    
    
    
    
    

    
    
    
//    old commented code - asm poc

//                environment.router?.showCoursewareForCourseWithID(courseID, fromController: self)
//
//
//                environment.router?.showContainerForBlockWithID("af1b24a0fac947659f976477b43d6ea8", type: CourseBlockDisplayType.HTML(problem), parentID: nil, courseID: "course-v1:ASM+CS101+2016_T1", fromController: self)
//
//                if let url = URL(string: objMetadataMachineReadableCodeObject.stringValue),
//                    UIApplication.sharedApplication().canOpenURL(url){
//
//                    UIApplication.sharedApplication().openURL(url)
//                }
//
//
//
//                var vc:QuizViewController?
//                vc.scanurl=objMetadataMachineReadableCodeObject.stringValue as! AVMetadataMachineReadableCodeObject
//                self.navigationController?.pushViewController(vc!, animated: true)
//
//
//                self.environment.router?.showContainerForBlockWithID(block.blockID, type:block.displayType, parentID: parent, courseID: courseQuerier.courseID, fromController:self)
//
//
//
//                let storyBoard : UIStoryboard = UIStoryboard(name: "Storyboard", bundle:nil)
//
//                let vc = storyBoard.instantiateViewControllerWithIdentifier("quizVC") as! QuizViewController
//                vc.scanUrl = objMetadataMachineReadableCodeObject.stringValue
//
//                // If you want to push to new ViewController then use this
//                self.navigationController?.pushViewController(vc, animated:false)
//
//                [loginController dismissViewControllerAnimated:YES completion:nil];
