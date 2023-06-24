//
//  WelcomeViewController.swift
//  SuperTranslator
//
//  Created by Chaii on 22/06/23.
//

import UIKit
import Speech
import Hero

final class WelcomeViewController: UIViewController {

    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "es_MX"))
    private var recognitionTask: SFSpeechRecognitionTask?
    var isRecording: Bool = false
    private var lastMetadata: SFSpeechRecognitionMetadata?
    private var dataSource = [TranscriptMetadata]()

    private var date: Date {
        return Date()
    }

    @IBOutlet weak var speechTextView: UITextView!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var tableView: UITableView!

    init() {
        super.init(nibName: String(describing: Self.self), bundle: .main)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        speechPermissions()
        cellRegister()
    }

    override func viewDidAppear(_ animated: Bool) {
        micChangexxx()
    }

    func micChangexxx() {
        let vc = TranslatorViewController()
        vc.heroModalAnimationType = .zoom
        self.present(vc, animated: true)
    }

    @IBAction func micChange() {
        if !isRecording {
            print("Funca")
            do {
                recordButton.setTitle("Recording...", for: .normal)
                speechTextView.text = ""
                try self.beginRecording()
                isRecording.toggle()
            } catch let error {
                print("\(error.localizedDescription)")
            }
        } else {
            guard let lastTranscriptText = self.speechTextView.text else {
                return
            }
            recordButton.setTitle("Record", for: .normal)
            if audioEngine.isRunning {
                recognitionRequest?.endAudio()
                audioEngine.stop()
                isRecording.toggle()
                guard let currentMetadata = lastMetadata else {
                    return
                }
                let recording = TranscriptMetadata(
                    transcriptText: lastTranscriptText,
                    dateRecorded: date,
                    totalCharacters: lastTranscriptText.count,
                    averagePauseDuration: currentMetadata.averagePauseDuration,
                    speakingRate: currentMetadata.speakingRate,
                    speechDuration: currentMetadata.speechDuration
                )
                dataSource.append(recording)
                tableView.reloadData()
                print(recording)
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
                    self.speechTextView.text = (transcribedString)
                    self.lastMetadata = result.speechRecognitionMetadata
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

    private func cellRegister() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "defaultCell")
        tableView.register(UINib(nibName: String(describing: TranscriptTableViewCell.self), bundle: nil), forCellReuseIdentifier: String(describing: TranscriptTableViewCell.self))
    }

    
}
extension WelcomeViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: String(describing: TranscriptTableViewCell.self), for: indexPath
        ) as? TranscriptTableViewCell

        return cell ?? tableView.dequeueReusableCell(withIdentifier: "defaultCell", for: indexPath)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        dataSource.count
    }
}
