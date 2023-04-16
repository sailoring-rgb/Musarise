//
//  GuitarView.swift
//  Musarise
//
//  Created by annaphens on 16/04/2023.
//

import SwiftUI
import CoreMotion

struct GuitarView: View {
    let motionManager = CMMotionManager()
    @State private var accelerationData: CMAcceleration? = nil

    var body: some View {
        VStack {
            if let acceleration = accelerationData {
                Text("X: \(acceleration.x)\nY: \(acceleration.y)\nZ: \(acceleration.z)")
            } else {
                ProgressView()
            }
        }
        .onAppear {
            startAccelerometerUpdates()
        }
        .onDisappear {
            stopAccelerometerUpdates()
        }
    }

    func startAccelerometerUpdates() {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.1
            motionManager.startAccelerometerUpdates(to: .main) { data, error in
                if let acceleration = data?.acceleration {
                    accelerationData = acceleration
                }
            }
        }
    }

    func stopAccelerometerUpdates() {
        // Para a atualização dos dados de aceleração
        motionManager.stopAccelerometerUpdates()
    }
}

struct GuitarView_Previews: PreviewProvider {
    static var previews: some View {
        GuitarView()
    }
}
