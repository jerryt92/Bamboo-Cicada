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

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(language.hapticStrengthTitle)
                .font(.system(size: 20, weight: .semibold, design: .serif))
                .foregroundStyle(Color(red: 0.14, green: 0.09, blue: 0.05))

            Picker(language.hapticStrengthTitle, selection: $hapticStrengthRawValue) {
                ForEach(HapticStrength.allCases) { strength in
                    Text(language.hapticStrengthSegmentTitle(for: strength))
                        .tag(strength.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel(language.hapticStrengthTitle)
        }
        .padding(.top, 64)
        .padding(.horizontal, 54)
        .frame(maxWidth: 640, maxHeight: .infinity, alignment: .topLeading)
        .background {
            ScrollPaperBackground()
                .ignoresSafeArea()
        }
        .navigationTitle(language.preferenceTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
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
