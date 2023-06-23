//
//  WelcomeViewController.swift
//  SuperTranslator
//
//  Created by Chaii on 22/06/23.
//

import UIKit
import Speech

final class WelcomeViewController: UIViewController {

    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "es_MX"))
    private var recognitionTask: SFSpeechRecognitionTask?
    var isRecording: Bool = false

    @IBOutlet weak var speechTextLabel: UILabel!

    init() {
        super.init(nibName: String(describing: Self.self), bundle: .main)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        speechPermissions()
    }

    @IBAction func micChange() {
        if !isRecording {
            print("Funca")
            do {
                speechTextLabel.text = ""
                try self.beginRecording()
                isRecording.toggle()
            } catch let error {
                print("\(error.localizedDescription)")
            }
        } else {
            if audioEngine.isRunning {
                recognitionRequest?.endAudio()
                audioEngine.stop()
                isRecording.toggle()
            }
        }
    }

    private func speechPermissions() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    print("Authorized")
                default:
                    break
                }
            }
        }
    }

    private func beginRecording() throws {
        recognitionTask?.cancel()
        self.recognitionTask = nil
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat){ (
            buffer: AVAudioPCMBuffer,
            when: AVAudioTime) in

            self.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create a SFSpeechAudioBufferRecognitionRequest object")
        }
        recognitionRequest.shouldReportPartialResults = true

        if speechRecognizer?.supportsOnDeviceRecognition ?? false{
            recognitionRequest.requiresOnDeviceRecognition = true
        }

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
                    if let result = result {
                        DispatchQueue.main.async {
                                let transcribedString = result.bestTranscription.formattedString
                                self.speechTextLabel.text = (transcribedString)
                        }
                    }

                    if error != nil {
                        self.audioEngine.stop()
                        inputNode.removeTap(onBus: 0)
                        self.recognitionRequest = nil
                        self.recognitionTask = nil
                    }
                }

    }
}
