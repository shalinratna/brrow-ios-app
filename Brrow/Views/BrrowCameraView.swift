//
//  BrrowCameraView.swift
//  Brrow
//
//  Camera for Stories and Quick Posts
//

import SwiftUI
import AVFoundation

struct BrrowCameraView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var cameraManager = CameraManager()
    @State private var selectedMode: CameraMode = .photo
    @State private var showingPreview = false
    @State private var capturedImage: UIImage?
    
    enum CameraMode: String, CaseIterable {
        case photo = "Photo"
        case story = "Story"
    }
    
    var body: some View {
        ZStack {
            // Camera preview
            CameraPreview(cameraManager: cameraManager)
                .ignoresSafeArea()
            
            // Overlay controls
            VStack {
                // Top controls
                topControls
                
                Spacer()
                
                // Bottom controls
                bottomControls
            }
        }
        .onAppear {
            cameraManager.requestPermissions()
        }
        .sheet(isPresented: $showingPreview) {
            if let image = capturedImage {
                CameraPreviewView(image: image, mode: selectedMode) {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
    
    // MARK: - Top Controls
    private var topControls: some View {
        HStack {
            Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }
            .foregroundColor(.white)
            .padding()
            
            Spacer()
            
            // Mode selector
            Picker("Mode", selection: $selectedMode) {
                ForEach(CameraMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(width: 150)
            
            Spacer()
            
            // Flash toggle
            Button(action: {
                cameraManager.toggleFlash()
            }) {
                Image(systemName: cameraManager.isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                    .foregroundColor(.white)
                    .font(.title2)
            }
            .padding()
        }
        .background(Color.black.opacity(0.3))
    }
    
    // MARK: - Bottom Controls
    private var bottomControls: some View {
        HStack {
            // Gallery button
            Button(action: {
                // Open photo library
            }) {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "photo.on.rectangle")
                            .foregroundColor(.white)
                    )
            }
            
            Spacer()
            
            // Capture button
            Button(action: {
                capturePhoto()
            }) {
                ZStack {
                    Circle()
                        .stroke(Color.white, lineWidth: 4)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 65, height: 65)
                        .scaleEffect(cameraManager.isCapturing ? 0.8 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: cameraManager.isCapturing)
                }
            }
            .disabled(cameraManager.isCapturing)
            
            Spacer()
            
            // Switch camera
            Button(action: {
                cameraManager.switchCamera()
            }) {
                Image(systemName: "camera.rotate")
                    .foregroundColor(.white)
                    .font(.title2)
                    .frame(width: 50, height: 50)
            }
        }
        .padding(.horizontal, 30)
        .padding(.bottom, 50)
    }
    
    private func capturePhoto() {
        cameraManager.capturePhoto { image in
            if let image = image {
                capturedImage = image
                showingPreview = true
            }
        }
    }
}

// MARK: - Camera Manager
class CameraManager: NSObject, ObservableObject {
    @Published var isFlashOn = false
    @Published var isCapturing = false
    
    var captureSession = AVCaptureSession()
    private var backCamera: AVCaptureDevice?
    private var frontCamera: AVCaptureDevice?
    private var currentCamera: AVCaptureDevice?
    private var photoOutput = AVCapturePhotoOutput()
    private var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    
    private var photoCaptureCompletion: ((UIImage?) -> Void)?
    
    override init() {
        super.init()
        setupCamera()
    }
    
    func requestPermissions() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if granted {
                DispatchQueue.main.async {
                    self.startSession()
                }
            }
        }
    }
    
    func setupCamera() {
        captureSession.sessionPreset = .photo
        
        // Setup devices
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .unspecified
        )
        
        for device in deviceDiscoverySession.devices {
            switch device.position {
            case .back:
                backCamera = device
            case .front:
                frontCamera = device
            default:
                break
            }
        }
        
        currentCamera = backCamera
        
        do {
            let input = try AVCaptureDeviceInput(device: currentCamera!)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            
            if captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
            }
        } catch {
            print("Error setting up camera: \(error)")
        }
    }
    
    func startSession() {
        if !captureSession.isRunning {
            DispatchQueue.global(qos: .background).async {
                self.captureSession.startRunning()
            }
        }
    }
    
    func stopSession() {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }
    
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        isCapturing = true
        photoCaptureCompletion = completion
        
        let photoSettings = AVCapturePhotoSettings()
        if isFlashOn {
            photoSettings.flashMode = .on
        }
        
        photoOutput.capturePhoto(with: photoSettings, delegate: self)
    }
    
    func toggleFlash() {
        isFlashOn.toggle()
    }
    
    func switchCamera() {
        captureSession.beginConfiguration()
        
        // Remove current input
        if let currentInput = captureSession.inputs.first as? AVCaptureDeviceInput {
            captureSession.removeInput(currentInput)
        }
        
        // Switch camera
        currentCamera = (currentCamera == backCamera) ? frontCamera : backCamera
        
        // Add new input
        do {
            if let camera = currentCamera {
                let input = try AVCaptureDeviceInput(device: camera)
                if captureSession.canAddInput(input) {
                    captureSession.addInput(input)
                }
            }
        } catch {
            print("Error switching camera: \(error)")
        }
        
        captureSession.commitConfiguration()
    }
}

// MARK: - Photo Capture Delegate
extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        isCapturing = false
        
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            photoCaptureCompletion?(nil)
            return
        }
        
        photoCaptureCompletion?(image)
    }
}

// MARK: - Camera Preview
struct CameraPreview: UIViewRepresentable {
    let cameraManager: CameraManager
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: cameraManager.captureSession)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let layer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            layer.frame = uiView.bounds
        }
    }
}

// MARK: - Camera Preview View
struct CameraPreviewView: View {
    let image: UIImage
    let mode: BrrowCameraView.CameraMode
    let onDismiss: () -> Void
    
    @State private var caption = ""
    
    var body: some View {
        ZStack {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
            
            VStack {
                // Top controls
                HStack {
                    Button("Retake") {
                        onDismiss()
                    }
                    .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button("Next") {
                        postContent()
                    }
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                }
                .padding()
                .background(Color.black.opacity(0.3))
                
                Spacer()
                
                // Caption input for stories
                if mode == .story {
                    HStack {
                        TextField("Add a caption...", text: $caption)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(25)
                        
                        Button("Share") {
                            shareStory()
                        }
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Theme.Colors.primary)
                        .cornerRadius(20)
                    }
                    .padding()
                }
            }
        }
    }
    
    private func postContent() {
        // Handle posting based on mode
        switch mode {
        case .photo:
            // Create new listing with photo
            break
        case .story:
            shareStory()
        }
        onDismiss()
    }
    
    private func shareStory() {
        // Share as BrrowStory
        print("Sharing story with caption: \(caption)")
        onDismiss()
    }
}

#Preview {
    BrrowCameraView()
}