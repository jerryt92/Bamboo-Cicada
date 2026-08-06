//
//  CicadaIntroductionView.swift
//  Bamboo Cicada
//

import SwiftUI

struct CicadaIntroductionView: View {
    let language: AppLanguage
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    Text(language.title)
                        .font(.system(size: 54, weight: .black, design: .serif))
                        .foregroundStyle(Color(red: 0.12, green: 0.08, blue: 0.04))
                        .minimumScaleFactor(0.62)
                        .lineLimit(1)

                    Text(language.subtitle)
                        .font(.system(size: 22, weight: .medium, design: .serif))
                        .foregroundStyle(Color(red: 0.23, green: 0.15, blue: 0.08))
                        .fixedSize(horizontal: false, vertical: true)

                    Rectangle()
                        .fill(Color(red: 0.12, green: 0.08, blue: 0.04).opacity(0.5))
                        .frame(width: 86, height: 2)
                        .padding(.top, 6)

                    VStack(alignment: .leading, spacing: 12) {
                        Text(language.sectionTitle)
                            .font(.system(size: 25, weight: .bold, design: .serif))
                            .foregroundStyle(Color(red: 0.13, green: 0.09, blue: 0.04))

                        Text(language.bodyText)
                            .font(.system(size: 18, weight: .regular, design: .serif))
                            .lineSpacing(8)
                            .foregroundStyle(Color(red: 0.18, green: 0.12, blue: 0.07))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 4)

                    Text(language.noteText)
                        .font(.system(size: 17, weight: .semibold, design: .serif))
                        .lineSpacing(6)
                        .foregroundStyle(Color(red: 0.55, green: 0.08, blue: 0.04))
                        .padding(.top, 8)
                        .fixedSize(horizontal: false, vertical: true)

                    NavigationLink {
                        CicadaPreferencesView(language: language)
                    } label: {
                        navigationRow(title: language.preferenceTitle, showsDivider: true)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .padding(.top, 22)

                    NavigationLink {
                        CicadaAboutView(language: language)
                    } label: {
                        navigationRow(title: language.aboutTitle, showsDivider: true)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())

                    Color.clear
                        .frame(height: 116)
                }
                .padding(.horizontal, 54)
                .padding(.top, 64)
                .frame(maxWidth: 640, alignment: .leading)
            }
            .background {
                ScrollPaperBackground()
                    .ignoresSafeArea()
            }
            .scrollContentBackground(.hidden)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel(language.closeTitle)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .background {
            ScrollPaperBackground()
                .ignoresSafeArea()
        }
        .statusBarHidden(true)
    }

    private func navigationRow(title: String, showsDivider: Bool) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .semibold, design: .serif))
                .foregroundStyle(Color(red: 0.14, green: 0.09, blue: 0.05))

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(red: 0.14, green: 0.09, blue: 0.05).opacity(0.64))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .padding(.vertical, 14)
        .overlay(alignment: .top) {
            if showsDivider {
                Rectangle()
                    .fill(Color(red: 0.12, green: 0.08, blue: 0.04).opacity(0.22))
                    .frame(height: 1)
            }
        }
    }
}

private struct CicadaPreferencesView: View {
    let language: AppLanguage
    @AppStorage(HapticStrength.storageKey) private var hapticStrengthRawValue = HapticStrength.medium.rawValue
    @AppStorage(CicadaBackgroundStyle.storageKey) private var backgroundStyleRawValue = CicadaBackgroundStyle.bamboo.rawValue
    @AppStorage(CicadaStyle.storageKey) private var cicadaStyleRawValue = CicadaStyle.red.rawValue

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 16) {
                    Text(language.hapticStrengthTitle)
                        .font(.system(size: 20, weight: .semibold, design: .serif))
                        .foregroundStyle(sectionTextColor)

                    Picker(language.hapticStrengthTitle, selection: $hapticStrengthRawValue) {
                        ForEach(HapticStrength.allCases) { strength in
                            Text(language.hapticStrengthSegmentTitle(for: strength))
                                .tag(strength.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(.preferencePaperYellow)
                    .accessibilityLabel(language.hapticStrengthTitle)
                }

                AppearanceCarousel(
                    items: CicadaBackgroundStyle.allCases,
                    selection: $backgroundStyleRawValue
                ) { style in
                    BackgroundStylePreview(style: style)
                }

                AppearanceCarousel(
                    items: CicadaStyle.allCases,
                    selection: $cicadaStyleRawValue
                ) { style in
                    CicadaStylePreview(style: style)
                }
            }
            .padding(.top, 48)
            .padding(.horizontal, 36)
            .padding(.bottom, 64)
            .frame(maxWidth: 640, alignment: .leading)
        }
        .background {
            ScrollPaperBackground()
                .ignoresSafeArea()
        }
        .navigationTitle(language.preferenceTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    private var sectionTextColor: Color {
        Color(red: 0.14, green: 0.09, blue: 0.05)
    }
}

private struct AppearanceCarousel<Item: Identifiable, Preview: View>: View where Item.ID == String {
    let items: [Item]
    @Binding var selection: String
    @ViewBuilder let preview: (Item) -> Preview
    @State private var scrollPosition: String?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                ForEach(items) { item in
                    Button {
                        selection = item.id
                        withAnimation(.snappy) {
                            scrollPosition = item.id
                        }
                    } label: {
                        preview(item)
                            .frame(width: 136, height: 94)
                            .padding(8)
                            .background(Color.preferencePaperYellow.opacity(selection == item.id ? 1.0 : 0.66))
                            .shadow(
                                color: selection == item.id
                                    ? Color(red: 0.38, green: 0.23, blue: 0.05).opacity(0.22)
                                    : .clear,
                                radius: 5,
                                y: 2
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(
                                        selection == item.id
                                            ? Color(red: 0.48, green: 0.29, blue: 0.05)
                                            : Color(red: 0.12, green: 0.08, blue: 0.04).opacity(0.2),
                                        lineWidth: selection == item.id ? 2.5 : 1
                                    )
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .id(item.id)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $scrollPosition)
        .onAppear {
            scrollPosition = selection
        }
        .onChange(of: selection) { _, value in
            if scrollPosition != value {
                scrollPosition = value
            }
        }
    }
}

private struct BackgroundStylePreview: View {
    let style: CicadaBackgroundStyle

    var body: some View {
        ZStack {
            style.baseColor

            if let textureAssetName = style.textureAssetName {
                BundlePNGImage(name: textureAssetName)
            }

            LinearGradient(
                colors: [.clear, Color.black.opacity(0.24)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

private struct CicadaStylePreview: View {
    let style: CicadaStyle

    var body: some View {
        ZStack {
            Color.preferencePaperYellow

            Capsule()
                .fill(Color(red: 0.93, green: 0.79, blue: 0.51))
                .frame(width: 9, height: 100)
                .offset(x: 42, y: 31)

            Path { path in
                path.move(to: CGPoint(x: 68, y: 76))
                path.addLine(to: CGPoint(x: 90, y: 32))
            }
            .stroke(Color(red: 0.62, green: 0.58, blue: 0.43), lineWidth: 1.5)

            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Color(red: 0.91, green: 0.75, blue: 0.43))
                .frame(width: 44, height: 66)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(style.headColor)
                        .frame(height: 9)
                }
                .overlay {
                    HStack(spacing: 17) {
                        Circle().fill(.black).frame(width: 6, height: 6)
                        Circle().fill(.black).frame(width: 6, height: 6)
                    }
                    .offset(y: -5)
                }
                .overlay(alignment: .bottom) {
                    HStack(spacing: 8) {
                        CicadaPreviewWing(side: .left)
                        CicadaPreviewWing(side: .right)
                    }
                    .offset(y: 28)
                }
                .offset(x: -12, y: 3)

            VStack(spacing: 4) {
                Circle().fill(style.beadColor).frame(width: 14, height: 14)
                Circle().fill(style.beadColor).frame(width: 14, height: 14)
            }
            .offset(x: 43, y: -28)
        }
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}


private struct CicadaPreviewWing: View {
    enum Side {
        case left
        case right
    }

    let side: Side

    var body: some View {
        CicadaPreviewWingShape()
            .fill(Color(red: 1.0, green: 0.92, blue: 0.68))
            .overlay {
                CicadaPreviewWingShape()
                    .stroke(Color.white.opacity(0.55), lineWidth: 1)
            }
            .frame(width: 20, height: 52)
            .rotationEffect(.degrees(side == .left ? 7 : -7), anchor: .top)
            .shadow(color: .black.opacity(0.12), radius: 2, y: 2)
    }
}

private struct CicadaPreviewWingShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.maxY),
            control1: CGPoint(x: rect.maxX + rect.width * 0.12, y: rect.minY + rect.height * 0.24),
            control2: CGPoint(x: rect.maxX + rect.width * 0.12, y: rect.minY + rect.height * 0.78)
        )
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.minY),
            control1: CGPoint(x: rect.minX - rect.width * 0.12, y: rect.minY + rect.height * 0.78),
            control2: CGPoint(x: rect.minX - rect.width * 0.12, y: rect.minY + rect.height * 0.24)
        )
        path.closeSubpath()
        return path
    }
}

private struct CicadaAboutView: View {
    let language: AppLanguage

    var body: some View {
        VStack(spacing: 22) {
            VStack(spacing: 14) {
                Image("AppLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 96, height: 96)
                    .clipShape(RoundedRectangle(cornerRadius: 21, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 21, style: .continuous)
                            .stroke(Color(red: 0.98, green: 0.88, blue: 0.62).opacity(0.72), lineWidth: 1)
                    }
                    .shadow(color: Color(red: 0.12, green: 0.08, blue: 0.04).opacity(0.22), radius: 10, y: 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)

            aboutRow(title: language.versionTitle, value: appVersionText)
        }
        .padding(.top, 64)
        .padding(.horizontal, 54)
        .frame(maxWidth: 640, maxHeight: .infinity, alignment: .top)
        .scrollContentBackground(.hidden)
        .background {
            ScrollPaperBackground()
                .ignoresSafeArea()
        }
        .navigationTitle(language.aboutTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    private var appVersionText: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    private func aboutRow(title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .semibold, design: .serif))
                .foregroundStyle(Color(red: 0.14, green: 0.09, blue: 0.05))

            Spacer()

            Text(value)
                .font(.system(size: 18, weight: .semibold, design: .serif))
                .foregroundStyle(Color(red: 0.14, green: 0.09, blue: 0.05).opacity(0.62))
        }
        .padding(.vertical, 14)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color(red: 0.12, green: 0.08, blue: 0.04).opacity(0.22))
                .frame(height: 1)
        }
    }
}


private extension Color {
    static let preferencePaperYellow = Color(red: 0.98, green: 0.89, blue: 0.66)
}
