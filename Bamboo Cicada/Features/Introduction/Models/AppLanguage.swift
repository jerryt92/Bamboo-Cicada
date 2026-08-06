//
//  AppLanguage.swift
//  Bamboo Cicada
//

import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case zh
    case zhHant
    case en
    case ja
    case ko
    case fr

    var id: String { rawValue }

    init(code: String) {
        self = AppLanguage(rawValue: code) ?? .zh
    }

    init(locale: Locale) {
        let preferredLanguage = Bundle.main.preferredLocalizations.first
        let languageCode = preferredLanguage ?? locale.language.languageCode?.identifier ?? "zh"
        let resolvedLanguage: AppLanguage
        if languageCode.hasPrefix("ja") {
            resolvedLanguage = .ja
        } else if languageCode.hasPrefix("ko") {
            resolvedLanguage = .ko
        } else if languageCode.hasPrefix("fr") {
            resolvedLanguage = .fr
        } else if languageCode.hasPrefix("en") {
            resolvedLanguage = .en
        } else if languageCode.hasPrefix("zh-Hant")
            || languageCode.hasPrefix("zh_TW")
            || languageCode.hasPrefix("zh-HK")
            || languageCode.hasPrefix("zh-MO") {
            resolvedLanguage = .zhHant
        } else {
            resolvedLanguage = .zh
        }
        self = resolvedLanguage
    }

    var introductionButtonTitle: String {
        switch self {
        case .zh: "介绍"
        case .zhHant: "介紹"
        case .en: "About"
        case .ja: "紹介"
        case .ko: "소개"
        case .fr: "À propos"
        }
    }

    var introductionButtonAccessibility: String {
        switch self {
        case .zh: "进入竹知了介绍页面"
        case .zhHant: "進入竹知了介紹頁面"
        case .en: "Open the Bamboo Cicada introduction"
        case .ja: "竹知了の紹介ページを開く"
        case .ko: "죽지료 소개 페이지 열기"
        case .fr: "Ouvrir la présentation de Bamboo Cicada"
        }
    }

    var closeTitle: String {
        switch self {
        case .zh: "关闭"
        case .zhHant: "關閉"
        case .en: "Close"
        case .ja: "閉じる"
        case .ko: "닫기"
        case .fr: "Fermer"
        }
    }

    var title: String {
        switch self {
        case .zh: "竹知了"
        case .zhHant: "竹知了"
        case .en: "Bamboo Cicada"
        case .ja: "竹知了"
        case .ko: "죽지료"
        case .fr: "Bamboo Cicada"
        }
    }

    var subtitle: String {
        switch self {
        case .zh: "竹、细绳与纸筒做成的民间声玩。"
        case .zhHant: "竹、細繩與紙筒做成的民間聲玩。"
        case .en: "A folk sound toy made from bamboo, cord, and a paper cylinder."
        case .ja: "竹、細いひも、紙筒から作られる民間の音玩具。"
        case .ko: "대나무, 가는 줄, 종이 원통으로 만든 민간 소리 장난감입니다."
        case .fr: "Un jouet sonore populaire fait de bambou, de corde et d’un cylindre de papier."
        }
    }

    var sectionTitle: String {
        switch self {
        case .zh: "民间童玩"
        case .zhHant: "民間童玩"
        case .en: "A Folk Toy"
        case .ja: "民間玩具"
        case .ko: "민간 장난감"
        case .fr: "Un Jouet Populaire"
        }
    }

    var bodyText: String {
        switch self {
        case .zh:
            "竹知了，又称竹蝉，是一种取材于自然的传统童玩。常见做法以竹籤、细绳和纸筒组成，摇转时发出近似鸣蝉的声音。它的妙处不在复杂机关，而在竹、纸、绳这些朴素材料，把手上的节奏变成夏日的声响。"
        case .zhHant:
            "竹知了，又稱竹蟬，是一種取材於自然的傳統童玩。常見做法以竹籤、細繩和紙筒組成，搖轉時發出近似鳴蟬的聲音。它的妙處不在複雜機關，而在竹、紙、繩這些樸素材料，把手上的節奏變成夏日的聲響。"
        case .en:
            "Bamboo Cicada, also known as the bamboo cicada, is a traditional toy made from natural materials. A typical form combines a bamboo skewer, cord, and paper cylinder; when swung, it produces a call like a cicada. Its charm is not a complex mechanism, but the way bamboo, paper, and string turn hand rhythm into the sound of summer."
        case .ja:
            "竹知了、または竹蝉は、自然の素材から作られる伝統的な玩具です。一般的には竹ひご、細いひも、紙筒を組み合わせ、振り回すと蝉に似た音が鳴ります。複雑な仕掛けではなく、竹、紙、ひもが手のリズムを夏の音へ変えるところに味わいがあります。"
        case .ko:
            "죽지료, 또는 대나무 매미는 자연 재료로 만든 전통 장난감입니다. 보통 대나무 꼬챙이, 가는 줄, 종이 원통으로 이루어지며 흔들어 돌리면 매미와 비슷한 소리가 납니다. 복잡한 장치보다 대나무와 종이, 줄이 손의 리듬을 여름의 소리로 바꾸는 점이 매력입니다."
        case .fr:
            "Bamboo Cicada, ou cigale de bambou, est un jouet traditionnel fait de matériaux naturels. Sa forme courante associe une tige de bambou, une corde et un cylindre de papier ; lorsqu’on le fait tourner, il produit un son proche de la cigale. Son charme tient à la manière dont bambou, papier et corde transforment le rythme de la main en son d’été."
        }
    }

    var noteText: String {
        switch self {
        case .zh: "轻轻摇动，听见一声夏天。"
        case .zhHant: "輕輕搖動，聽見一聲夏天。"
        case .en: "Shake gently, and hear a small summer."
        case .ja: "そっと振ると、小さな夏の音がします。"
        case .ko: "가볍게 흔들면 작은 여름 소리가 납니다."
        case .fr: "Secouez doucement, et écoutez un petit été."
        }
    }

    var preferenceTitle: String {
        switch self {
        case .zh: "偏好"
        case .zhHant: "偏好"
        case .en: "Preferences"
        case .ja: "環境設定"
        case .ko: "환경설정"
        case .fr: "Préférences"
        }
    }

    var hapticStrengthTitle: String {
        switch self {
        case .zh: "震动强度"
        case .zhHant: "震動強度"
        case .en: "Haptic Strength"
        case .ja: "触覚の強さ"
        case .ko: "햅틱 강도"
        case .fr: "Intensité haptique"
        }
    }

    func hapticStrengthTitle(for strength: HapticStrength) -> String {
        switch (self, strength) {
        case (.zh, .gentle): "弱"
        case (.zh, .medium): "适中"
        case (.zh, .strong): "强"
        case (.zhHant, .gentle): "弱"
        case (.zhHant, .medium): "適中"
        case (.zhHant, .strong): "強"
        case (.en, .gentle): "Gentle"
        case (.en, .medium): "Medium"
        case (.en, .strong): "Strong"
        case (.ja, .gentle): "弱"
        case (.ja, .medium): "標準"
        case (.ja, .strong): "強"
        case (.ko, .gentle): "약함"
        case (.ko, .medium): "보통"
        case (.ko, .strong): "강함"
        case (.fr, .gentle): "Faible"
        case (.fr, .medium): "Moyenne"
        case (.fr, .strong): "Forte"
        }
    }

    func hapticStrengthSegmentTitle(for strength: HapticStrength) -> String {
        switch (self, strength) {
        case (.zh, .gentle): "弱"
        case (.zh, .medium): "适中"
        case (.zh, .strong): "强"
        case (.zhHant, .gentle): "弱"
        case (.zhHant, .medium): "適中"
        case (.zhHant, .strong): "強"
        case (.en, .gentle): "Gentle"
        case (.en, .medium): "Medium"
        case (.en, .strong): "Strong"
        case (.ja, .gentle): "弱"
        case (.ja, .medium): "標準"
        case (.ja, .strong): "強"
        case (.ko, .gentle): "약함"
        case (.ko, .medium): "보통"
        case (.ko, .strong): "강함"
        case (.fr, .gentle): "Faible"
        case (.fr, .medium): "Moyenne"
        case (.fr, .strong): "Forte"
        }
    }

    var aboutTitle: String {
        switch self {
        case .zh: "关于"
        case .zhHant: "關於"
        case .en: "About"
        case .ja: "このアプリについて"
        case .ko: "정보"
        case .fr: "À propos"
        }
    }

    var versionTitle: String {
        switch self {
        case .zh: "版本"
        case .zhHant: "版本"
        case .en: "Version"
        case .ja: "バージョン"
        case .ko: "버전"
        case .fr: "Version"
        }
    }
}
