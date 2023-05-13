import SwiftUI
import Charts
import FirebaseFirestore
import AVKit

enum Constants{
    static let updateInterval = 0.05
    static let barAmount = 40
    static let magnitudeLimit: Float = 32
}

struct WaveformView: View {
    let timer = Timer.publish(
        every: Constants.updateInterval,
        on: .main,
        in: .common
    ).autoconnect()
    
    @State private var playerManager = PlayerManager()
    @State private var player: AVPlayer?
    @State private var playerStatus = AVPlayer.TimeControlStatus.paused
    @State var soundURL: URL
    @State var backgroundImage: URL
    @State var tapped: Bool = false
    @State var data: [Float] = Array(repeating: 0, count: Constants.barAmount)
        .map{ _ in Float.random(in: 0 ... Constants.magnitudeLimit) }
    
    var body: some View {
            VStack {
                Spacer()
                VStack {
                    Chart(Array(data.enumerated()), id: \.0) { index, magnitude in
                        BarMark(
                            x: .value("Frequency", String(index)),
                            y: .value("Magnitude", magnitude)
                        )
                        .foregroundStyle(
                            Color(
                                hue: 0.3 - Double((magnitude / Constants.magnitudeLimit) / 5),
                                saturation: 1,
                                brightness: 1,
                                opacity: 0.7
                            )
                        )
                    }
                    .onReceive(timer, perform: updateData)
                    .chartYScale(domain: 0 ... Constants.magnitudeLimit)
                    .chartXAxis(.hidden)
                    .chartYAxis(.hidden)
                    .frame(height:100)
                    .padding()
                    .background(
                        Color.black.opacity(0.3)
                            .shadow(radius: 20)
                    )
                    .cornerRadius(10)

                    playerControls
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                .shadow(radius: 40)
                .padding()
            }
            .background {
                backgroundPic
            }
            .preferredColorScheme(.dark)
        }
    
    var backgroundPic: some View {
            AsyncImage(
                url: backgroundImage,
                transaction: Transaction(animation: .easeOut(duration: 1))
            ) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    Color.clear
                }
            }
            .overlay {
                LinearGradient(
                    colors: [.clear, .black],
                    startPoint: .center,
                    endPoint: .bottom
                )
            }
            .ignoresSafeArea()
            .aspectRatio(contentMode: .fill)
        }
    
    var playerControls: some View{
        Group{
            ProgressView(value: 0.4)
                .tint(.secondary)
            
            HStack(spacing: 40){
                Image(systemName: "backward.fill")
                Button(action: playTaped){
                    Image(systemName: "\(playerManager.isPlaying && self.tapped ? "pause" : "play").circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                }
                Image(systemName: "forward.fill")
            }
        }
    }
    
    func playTaped() {
        if self.tapped {
            playerManager.stopPlayback()
            self.tapped = false
        } else {
            playerManager = PlayerManager()
            playerManager.startPlayback(with: soundURL)
            self.tapped = true
        }
    }
    
    func updateData(_: Date) {
        if playerManager.isPlaying && self.tapped {
            withAnimation(.easeOut(duration: 0.2)) {
                data = Array(repeating: 0, count: Constants.barAmount)
                    .map { _ in Float.random(in: 0 ... Constants.magnitudeLimit) }
            }
        }
    }
}

class PlayerManager: ObservableObject {
    @Published var isPlaying = true
    private var player: AVPlayer?
    
    init() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerItemDidReachEnd(_:)),
                                               name: .AVPlayerItemDidPlayToEndTime,
                                               object: nil)
    }

    func startPlayback(with url: URL) {
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        player?.play()
        isPlaying = true
    }

    func stopPlayback() {
        player?.pause()
        isPlaying = false
    }

    @objc private func playerItemDidReachEnd(_ notification: Notification) {
        stopPlayback()
    }
}
