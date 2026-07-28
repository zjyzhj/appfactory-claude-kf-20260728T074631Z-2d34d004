import SwiftUI

/// "Stitching atelier" design system (build/design.md §视觉方向):
/// warm linen ground, Aida cloth grid texture, thread-red primary,
/// indigo secondary, sage success, amber warning.
enum Theme {

    // MARK: Colors

    static let linen = Color(hexString: "#F5EFE4")
    static let threadRed = Color(hexString: "#C0453E")
    static let indigo = Color(hexString: "#3E5F8A")
    static let sage = Color(hexString: "#5F8A4C")
    static let amber = Color(hexString: "#C8842C")

    static var background: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hexString: "#1D1A16")
                : UIColor(hexString: "#F5EFE4")
        })
    }

    static var card: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hexString: "#2A251F")
                : UIColor(hexString: "#FFFFFF")
        })
    }

    static var ink: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hexString: "#F5EFE4")
                : UIColor(hexString: "#2B2118")
        })
    }

    static var inkSecondary: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hexString: "#B8AC9C")
                : UIColor(hexString: "#6E5F4E")
        })
    }

    static var hairline: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(white: 1, alpha: 0.12)
                : UIColor(red: 0.42, green: 0.34, blue: 0.24, alpha: 0.18)
        })
    }

    // MARK: Type

    static func titleFont(_ size: CGFloat = 28, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    static func headlineSerif(_ size: CGFloat = 20) -> Font {
        .system(size: size, weight: .semibold, design: .serif)
    }

    static func mono(_ size: CGFloat = 13, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    // MARK: Surfaces

    struct AidaGridTexture: View {
        var spacing: CGFloat = 14
        var opacity: Double = 0.08

        var body: some View {
            Canvas { context, size in
                let lineColor = Color.primary.opacity(opacity)
                var path = Path()
                var x: CGFloat = 0
                while x <= size.width {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                    x += spacing
                }
                var y: CGFloat = 0
                while y <= size.height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    y += spacing
                }
                context.stroke(path, with: .color(lineColor), lineWidth: 0.5)
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }

    struct ScreenBackground: View {
        var body: some View {
            ZStack {
                Theme.background.ignoresSafeArea()
                AidaGridTexture().ignoresSafeArea()
            }
        }
    }

    struct CardStyle: ViewModifier {
        func body(content: Content) -> some View {
            content
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Theme.card)
                        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Theme.hairline, lineWidth: 1)
                )
        }
    }

    struct PrimaryButtonStyle: ButtonStyle {
        @Environment(\.isEnabled) private var isEnabled
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 50)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(isEnabled ? Theme.threadRed : Theme.threadRed.opacity(0.45))
                )
                .scaleEffect(configuration.isPressed ? 0.97 : 1)
                .animation(Motion.pullSpring, value: configuration.isPressed)
        }
    }

    struct SecondaryButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.indigo)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Theme.indigo.opacity(0.5), lineWidth: 1.5)
                )
                .opacity(configuration.isPressed ? 0.7 : 1)
        }
    }
}

extension View {
    func atelierCard() -> some View {
        modifier(Theme.CardStyle())
    }
}
