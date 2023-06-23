//
//  QRScannerView.swift
//  TOTPApp
//
//  Created by Lilly Cham on 23/06/2023.
//

import AVFoundation
import SwiftUI

#if os(iOS)

class QRScannerController: UIViewController {
  var captureSession = AVCaptureSession()
  var previewLayer: AVCaptureVideoPreviewLayer?
  var qrFrameView: UIView?
  
  var delegate: AVCaptureMetadataOutputObjectsDelegate?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // acquire the main back camera to scan the qr code
    guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
      print("Failed to acquire capture device! Are we running in the simulator?")
      
      return
    }
    
    guard let videoInput: AVCaptureDeviceInput = try? AVCaptureDeviceInput(device: captureDevice) else {
      return
    }
    
    self.captureSession.addInput(videoInput)
    
    let metadataOutput = AVCaptureMetadataOutput()
    self.captureSession.addOutput(metadataOutput)
    
    metadataOutput.setMetadataObjectsDelegate(delegate, queue: DispatchQueue.main)
    metadataOutput.metadataObjectTypes = [.qr]
    
    // Add video preview layer as a sublayer
    self.previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    self.previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
    self.previewLayer?.frame = view.layer.bounds
    view.layer.addSublayer(self.previewLayer!)
    
    
    // Start video capture.
    DispatchQueue.global(qos: .background).async {
      self.captureSession.startRunning()
    }
  }
}

enum ScanError: Error {
  case noneFound
  case notScannedYet
}

struct QRScannerView: UIViewControllerRepresentable {
  @Binding var result: Result<String, ScanError>
  
  class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    internal init(_ result: Binding<Result<String, ScanError>>) {
      self._result = result
    }
    
    @Binding var result: Result<String, ScanError>
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
      guard let _metadataObject = metadataObjects.first else {
        self.result = .failure(.noneFound)
        return
      }
      
      let metadataObject = _metadataObject as! AVMetadataMachineReadableCodeObject
      
      if let _result = metadataObject.stringValue,
         metadataObject.type == AVMetadataObject.ObjectType.qr {
           self.result = .success(_result)
      }
    }
  }
  
  func makeCoordinator() -> Coordinator {
    Coordinator($result)
  }
  
  func makeUIViewController(context: Context) -> QRScannerController {
    let controller = QRScannerController()
    controller.delegate = context.coordinator
    
    return controller
  }
  
  func updateUIViewController(_ uiViewController: QRScannerController, context: Context) { }
}


//#Preview {
//  QRScannerView()
//}
#endif
