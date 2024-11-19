import SwiftUI

// MARK: - Supporting Types

// Define CatMood if not already defined
enum CatMood {
    case normal
    case happy
    case sad
    case sleepy
    case watching
}

// Define LineShape for drawing debug lines (if used)
struct LineShape: Shape {
    let angle: Double
    let length: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let dx = cos(angle) * length / 2
        let dy = sin(angle) * length / 2
        path.move(to: CGPoint(x: rect.midX - dx, y: rect.midY - dy))
        path.addLine(to: CGPoint(x: rect.midX + dx, y: rect.midY + dy))
        return path
    }
}

struct CatFeatures: View {
    let phase: Double
    let isWatching: Bool
    let mood: CatMood
    let touchLocation: CGPoint?
    var onDebugUpdate: ((EyeGeometry.PupilState, EyeGeometry.PupilState) -> Void)?

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)

            // Eye centers
            let leftEyeCenter = CGPoint(
                x: size * EyeGeometry.Configuration.leftEyeCenter.x,
                y: size * EyeGeometry.Configuration.leftEyeCenter.y
            )
            let rightEyeCenter = CGPoint(
                x: size * EyeGeometry.Configuration.rightEyeCenter.x,
                y: size * EyeGeometry.Configuration.rightEyeCenter.y
            )

            // Eye geometries
            let leftEyeGeometry = EyeGeometry(
                center: leftEyeCenter,
                boundaryA: EyeGeometry.Configuration.boundaryA,
                boundaryB: EyeGeometry.Configuration.boundaryB
            )
            let rightEyeGeometry = EyeGeometry(
                center: rightEyeCenter,
                boundaryA: EyeGeometry.Configuration.boundaryA,
                boundaryB: EyeGeometry.Configuration.boundaryB
            )

            // Pupil states
            let leftPupilState: EyeGeometry.PupilState
            let rightPupilState: EyeGeometry.PupilState

            if let touchLocation = touchLocation {
                leftPupilState = leftEyeGeometry.calculatePupilPosition(for: touchLocation)
                rightPupilState = rightEyeGeometry.calculatePupilPosition(for: touchLocation)
            } else {
                leftPupilState = leftEyeGeometry.initialPupilState()
                rightPupilState = rightEyeGeometry.initialPupilState()
            }

            ZStack {
                // Cat Ears
                Image("EarHump")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.9)
                    .position(x: size / 2, y: size * 0.3)
                    .accessibilityIdentifier("catEars")

                // Eyeballs (Eye Whites)
                Image("balls")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size)
                    .position(x: size / 2, y: size / 2)
                    .accessibilityIdentifier("eyeWhites")

                // Pupils and Debug Views
                ZStack {
                    // Pupils
                    PupilView(
                        state: leftPupilState,
                        position: CGPoint(x: leftEyeCenter.x + 3.5, y: leftEyeCenter.y),
                        size: size
                    )

                    PupilView(
                        state: rightPupilState,
                        position: CGPoint(x: rightEyeCenter.x + 4.9, y: rightEyeCenter.y + (-2.5)),
                        size: size
                    )

                    // Debug Views
                    #if DEBUG
                    EyeBoundaryDebug(
                        size: size,
                        leftEyeCenter: leftEyeCenter,
                        rightEyeCenter: rightEyeCenter,
                        leftPupilState: leftPupilState,
                        rightPupilState: rightPupilState
                    )
                    #endif
                }
                .onAppear {
                    onDebugUpdate?(leftPupilState, rightPupilState)
                }
                .onChange(of: touchLocation) { _ in
                    onDebugUpdate?(leftPupilState, rightPupilState)
                }

                // Mouth and Whiskers
                MouthAndWhiskers(mood: mood, size: size)
            }
        }
    }

    // MARK: - Supporting Views

    private struct PupilView: View {
        let state: EyeGeometry.PupilState
        let position: CGPoint
        let size: CGFloat

        var body: some View {
            let scalingFactor = size / EyeGeometry.Configuration.baseSize

            Image("Pupil")
                .resizable()
                .scaledToFit()
                .frame(width: size * 0.1)  // Adjust the multiplier as needed
                .position(
                    x: position.x + state.offset.x * scalingFactor,
                    y: position.y + state.offset.y * scalingFactor
                )
                .rotationEffect(.radians(-state.rotation + .pi / 2))
                .accessibilityIdentifier("pupil")
        }
    }

    private struct MouthAndWhiskers: View {
        let mood: CatMood
        let size: CGFloat

        var body: some View {
            Group {
                Image("Whiskers")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.9)
                    .accessibilityIdentifier("whiskers")

                Image(getMouthAsset())
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.35)
                    .accessibilityIdentifier("mouth")
            }
            .position(x: size * 0.5, y: size * 0.7)
        }

        private func getMouthAsset() -> String {
            switch mood {
            case .sleepy:
                return "SleepyMouth"
            case .happy:
                return "justMouth"
            default:
                return "ClosedMouth"
            }
        }
    }

    private struct EyeBoundaryDebug: View {
        let size: CGFloat
        let leftEyeCenter: CGPoint
        let rightEyeCenter: CGPoint
        let leftPupilState: EyeGeometry.PupilState
        let rightPupilState: EyeGeometry.PupilState

        var body: some View {
            // Ellipse dimensions based on boundaries
            let ellipseWidth = EyeGeometry.Configuration.boundaryA * 2
            let ellipseHeight = EyeGeometry.Configuration.boundaryB * 2

            Group {
                // Blue oval boundaries
                Ellipse()
                    .stroke(Color.blue.opacity(0.5), lineWidth: 1)
                    .frame(width: ellipseWidth, height: ellipseHeight)
                    .position(leftEyeCenter)

                Ellipse()
                    .stroke(Color.blue.opacity(0.5), lineWidth: 1)
                    .frame(width: ellipseWidth, height: ellipseHeight)
                    .position(rightEyeCenter)

                // Left Eye Tangent Line
                LineShape(angle: leftPupilState.rotation, length: 20)
                    .stroke(Color.green, lineWidth: 1)
                    .position(
                        x: leftEyeCenter.x + leftPupilState.offset.x,
                        y: leftEyeCenter.y + leftPupilState.offset.y
                    )

                // Right Eye Tangent Line
                LineShape(angle: rightPupilState.rotation, length: 20)
                    .stroke(Color.green, lineWidth: 1)
                    .position(
                        x: rightEyeCenter.x + rightPupilState.offset.x,
                        y: rightEyeCenter.y + rightPupilState.offset.y
                    )
            }
        }
    }
}
