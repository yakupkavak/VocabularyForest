//
//  MockData.swift
//  Domain
//
//  Created by Yakup Kavak on 24.03.2026.
//

import Foundation
import DTO

// MARK: - MOCK

extension Libraries {
    nonisolated(unsafe) public static let mock: Libraries = Libraries(
        version: 1,
        updatedAt: "2025-12-22T12:00:00.000Z",
        libraries: [
            // --- MEVCUTLAR ---
            Library(
                id: "en-US_tr/a1",
                sourceLanguage: "en-US",
                targetLanguage: "tr",
                name: "a1",
                wordCount: 3,
                fileKey: "libraries/en-US_tr/a1.json",
                updatedAt: "2025-12-22T09:55:00.000Z"
            ),
            Library(
                id: "en-US_en-GB/a1",
                sourceLanguage: "en-US",
                targetLanguage: "en-GB",
                name: "a1",
                wordCount: 2,
                fileKey: "libraries/en-US_en-GB/a1.json",
                updatedAt: "2025-12-22T09:40:00.000Z"
            ),
            Library(
                id: "de_en/a2", // Almanya -> İngilizce (US)
                sourceLanguage: "de",
                targetLanguage: "en-US",
                name: "a2",
                wordCount: 4,
                fileKey: "libraries/de_en/a2.json",
                updatedAt: "2025-12-22T09:20:00.000Z"
            ),
            
            // --- YENİ EKLENENLER ---
            
            // 1. İspanyolca -> İngilizce (US) (B1)
            Library(
                id: "es_en-US/b1",
                sourceLanguage: "es",
                targetLanguage: "en-US",
                name: "b1",
                wordCount: 5,
                fileKey: "libraries/es_en-US/b1.json",
                updatedAt: "2025-12-21T15:30:00.000Z"
            ),
            
            // 2. Fransızca -> Türkçe (A1)
            Library(
                id: "fr_tr/a1",
                sourceLanguage: "fr",
                targetLanguage: "tr",
                name: "a1",
                wordCount: 3,
                fileKey: "libraries/fr_tr/a1.json",
                updatedAt: "2025-12-21T14:20:00.000Z"
            ),
            
            // 3. Japonca -> İngilizce (US) (N5/Basit) - Alfabe Testi
            Library(
                id: "ja_en-US/n5",
                sourceLanguage: "ja",
                targetLanguage: "en-US",
                name: "n5",
                wordCount: 4,
                fileKey: "libraries/ja_en/n5.json",
                updatedAt: "2025-12-21T10:00:00.000Z"
            ),
            
            // 4. Çince -> Türkçe (HSK1) - Karakter Testi
            Library(
                id: "zh-CN_tr/hsk1",
                sourceLanguage: "zh-CN",
                targetLanguage: "tr",
                name: "hsk1",
                wordCount: 3,
                fileKey: "libraries/zh-CN_tr/hsk1.json",
                updatedAt: "2025-12-20T09:00:00.000Z"
            ),
            
            // 5. Arapça -> İngilizce (US) (RTL Testi - Sağdan Sola)
            Library(
                id: "ar_en-US/basic",
                sourceLanguage: "ar",
                targetLanguage: "en-US",
                name: "a1",
                wordCount: 3,
                fileKey: "libraries/ar_en/basic.json",
                updatedAt: "2025-12-19T11:00:00.000Z"
            ),
            
            // 6. Rusça -> Türkçe (A2) - Kiril Alfabesi
            Library(
                id: "ru_tr/a2",
                sourceLanguage: "ru",
                targetLanguage: "tr",
                name: "a2",
                wordCount: 3,
                fileKey: "libraries/ru_tr/a2.json",
                updatedAt: "2025-12-19T09:00:00.000Z"
            ),
            
            // 7. Portekizce (BR) -> İspanyolca (Benzer diller)
            Library(
                id: "pt-BR_es/b2",
                sourceLanguage: "pt-BR",
                targetLanguage: "es",
                name: "b2",
                wordCount: 4,
                fileKey: "libraries/pt-BR_es/b2.json",
                updatedAt: "2025-12-18T16:45:00.000Z"
            ),
            
            // 8. Korece -> İngilizce (Hangul Testi)
            Library(
                id: "ko_en-US/beginner",
                sourceLanguage: "ko",
                targetLanguage: "en-US",
                name: "a1",
                wordCount: 3,
                fileKey: "libraries/ko_en/beginner.json",
                updatedAt: "2025-12-18T10:00:00.000Z"
            )
        ]
    )
}

// MARK: - Mock Bookcase Requests (Details)

public extension BookcaseRequest {
    
    // --- MEVCUTLAR ---
    
    nonisolated(unsafe) static let mockEnUSTrA1: BookcaseRequest = BookcaseRequest(
        id: "en-US_tr/a1",
        sourceLanguage: "en-US",
        targetLanguage: "tr",
        name: "a1",
        wordCount: 3,
        version: 1,
        updatedAt: "2025-12-22T09:55:00.000Z",
        words: [
            Word(id: "A1-001", term: "play", definition: "oynamak", example: "I play basketball.", description: "to take part in a sport or game", partOfSpeech: "verb", createdAt: "2025-12-22T09:54:10.000Z"),
            Word(id: "A1-002", term: "happy", definition: "mutlu", example: "I am happy today.", description: "feeling good or pleased", partOfSpeech: "adjective", createdAt: "2025-12-22T09:53:20.000Z"),
            Word(id: "A1-003", term: "apple", definition: "elma", example: "I eat an apple every day.", description: "a common fruit", partOfSpeech: "noun", createdAt: "2025-12-22T09:52:00.000Z")
        ]
    )

    nonisolated(unsafe) static let mockEnUSEnGBA1: BookcaseRequest = BookcaseRequest(
        id: "en-US_en-GB/a1",
        sourceLanguage: "en-US",
        targetLanguage: "en-GB",
        name: "a1",
        wordCount: 2,
        version: 1,
        updatedAt: "2025-12-22T09:40:00.000Z",
        words: [
            Word(id: "UK-001", term: "lift", definition: "elevator", example: "Take the lift to the second floor.", description: "British English for elevator", partOfSpeech: "noun", createdAt: "2025-12-22T09:39:10.000Z"),
            Word(id: "UK-002", term: "rubbish", definition: "trash", example: "Put the rubbish in the bin.", description: "British English for trash/garbage", partOfSpeech: "noun", createdAt: "2025-12-22T09:38:00.000Z")
        ]
    )

    nonisolated(unsafe) static let mockDeEnA2: BookcaseRequest = BookcaseRequest(
        id: "de_en/a2",
        sourceLanguage: "de",
        targetLanguage: "en-US",
        name: "a2",
        wordCount: 4,
        version: 1,
        updatedAt: "2025-12-22T09:20:00.000Z",
        words: [
            Word(id: "DE-001", term: "gehen", definition: "to go", example: "Ich gehe nach Hause.", description: "common verb meaning 'to go'", partOfSpeech: "verb", createdAt: "2025-12-22T09:19:10.000Z"),
            Word(id: "DE-002", term: "schnell", definition: "fast", example: "Das Auto ist schnell.", description: "describes speed", partOfSpeech: "adjective", createdAt: "2025-12-22T09:18:00.000Z"),
            Word(id: "DE-003", term: "lernen", definition: "to learn", example: "Ich lerne Englisch.", description: "to study / acquire knowledge", partOfSpeech: "verb", createdAt: "2025-12-22T09:17:00.000Z"),
            Word(id: "DE-004", term: "Buch", definition: "book", example: "Das Buch ist interessant.", description: "a set of printed pages", partOfSpeech: "noun", createdAt: "2025-12-22T09:16:00.000Z")
        ]
    )
    
    // --- YENİ DETAYLI VERİLER ---
    
    // İspanyolca -> İngilizce (US) (B1 - Orta Seviye)
    nonisolated(unsafe) static let mockEsEnB1: BookcaseRequest = BookcaseRequest(
        id: "es_en-US/b1",
        sourceLanguage: "es",
        targetLanguage: "en-US",
        name: "b1",
        wordCount: 5,
        version: 2,
        updatedAt: "2025-12-21T15:30:00.000Z",
        words: [
            Word(id: "ES-001", term: "desarrollar", definition: "to develop", example: "Necesitamos desarrollar un plan.", description: "to grow or cause to grow", partOfSpeech: "verb", createdAt: "2025-12-21T15:00:00.000Z"),
            Word(id: "ES-002", term: "éxito", definition: "success", example: "La fiesta fue un éxito.", description: "the accomplishment of an aim", partOfSpeech: "noun", createdAt: "2025-12-21T15:05:00.000Z"),
            Word(id: "ES-003", term: "quizás", definition: "maybe", example: "Quizás vaya al cine mañana.", description: "possibly but not certainly", partOfSpeech: "adverb", createdAt: "2025-12-21T15:10:00.000Z"),
            Word(id: "ES-004", term: "peligroso", definition: "dangerous", example: "Es peligroso nadar aquí.", description: "able or likely to cause harm", partOfSpeech: "adjective", createdAt: "2025-12-21T15:15:00.000Z"),
            Word(id: "ES-005", term: "corazón", definition: "heart", example: "Mi corazón late rápido.", description: "organ that pumps blood", partOfSpeech: "noun", createdAt: "2025-12-21T15:20:00.000Z")
        ]
    )
    
    // Fransızca -> Türkçe (A1)
    nonisolated(unsafe) static let mockFrTrA1: BookcaseRequest = BookcaseRequest(
        id: "fr_tr/a1",
        sourceLanguage: "fr",
        targetLanguage: "tr",
        name: "a1",
        wordCount: 3,
        version: 1,
        updatedAt: "2025-12-21T14:20:00.000Z",
        words: [
            Word(id: "FR-001", term: "bonjour", definition: "merhaba", example: "Bonjour, comment ça va?", description: "sabahları veya gün içinde selamlama", partOfSpeech: "interjection", createdAt: "2025-12-21T14:00:00.000Z"),
            Word(id: "FR-002", term: "chat", definition: "kedi", example: "Le chat est noir.", description: "evcil hayvan", partOfSpeech: "noun", createdAt: "2025-12-21T14:05:00.000Z"),
            Word(id: "FR-003", term: "merci", definition: "teşekkürler", example: "Merci beaucoup.", description: "minnet bildirme sözü", partOfSpeech: "interjection", createdAt: "2025-12-21T14:10:00.000Z")
        ]
    )
    
    // Japonca -> İngilizce (US) (N5)
    nonisolated(unsafe) static let mockJaEnN5: BookcaseRequest = BookcaseRequest(
        id: "ja_en-US/n5",
        sourceLanguage: "ja",
        targetLanguage: "en-US",
        name: "n5",
        wordCount: 4,
        version: 1,
        updatedAt: "2025-12-21T10:00:00.000Z",
        words: [
            Word(id: "JA-001", term: "ありがとう (Arigatou)", definition: "Thank you", example: "Arigatou gozaimasu.", description: "Standard expression of gratitude", partOfSpeech: "phrase", createdAt: "2025-12-21T09:50:00.000Z"),
            Word(id: "JA-002", term: "猫 (Neko)", definition: "Cat", example: "Neko ga suki desu.", description: "Small feline animal", partOfSpeech: "noun", createdAt: "2025-12-21T09:52:00.000Z"),
            Word(id: "JA-003", term: "食べる (Taberu)", definition: "To eat", example: "Sushi o tabemasu.", description: "Consuming food", partOfSpeech: "verb", createdAt: "2025-12-21T09:54:00.000Z"),
            Word(id: "JA-004", term: "水 (Mizu)", definition: "Water", example: "Mizu o kudasai.", description: "Clear liquid essential for life", partOfSpeech: "noun", createdAt: "2025-12-21T09:56:00.000Z")
        ]
    )
    
    // Çince -> Türkçe (HSK1)
    nonisolated(unsafe) static let mockZhTrHSK1: BookcaseRequest = BookcaseRequest(
        id: "zh-CN_tr/hsk1",
        sourceLanguage: "zh-CN",
        targetLanguage: "tr",
        name: "hsk1",
        wordCount: 3,
        version: 1,
        updatedAt: "2025-12-20T09:00:00.000Z",
        words: [
            Word(id: "ZH-001", term: "你好 (nǐ hǎo)", definition: "merhaba", example: "你好！", description: "standart selamlama", partOfSpeech: "phrase", createdAt: "2025-12-20T08:50:00.000Z"),
            Word(id: "ZH-002", term: "谢谢 (xièxie)", definition: "teşekkürler", example: "谢谢你的帮助。", description: "minnet ifadesi", partOfSpeech: "verb", createdAt: "2025-12-20T08:55:00.000Z"),
            Word(id: "ZH-003", term: "朋友 (péngyou)", definition: "arkadaş", example: "他是我的好朋友。", description: "sevilen ve güvenilen kişi", partOfSpeech: "noun", createdAt: "2025-12-20T08:58:00.000Z")
        ]
    )
    
    // Arapça -> İngilizce (US) (RTL Testi)
    nonisolated(unsafe) static let mockArEnBasic: BookcaseRequest = BookcaseRequest(
        id: "ar_en-US/basic",
        sourceLanguage: "ar",
        targetLanguage: "en-US",
        name: "a1",
        wordCount: 3,
        version: 1,
        updatedAt: "2025-12-19T11:00:00.000Z",
        words: [
            Word(id: "AR-001", term: "سلام (Salam)", definition: "Peace/Hello", example: "Salam alaykum.", description: "Universal greeting in Arabic", partOfSpeech: "noun", createdAt: "2025-12-19T10:50:00.000Z"),
            Word(id: "AR-002", term: "کتاب (Kitab)", definition: "Book", example: "Hadha kitab.", description: "Something to read", partOfSpeech: "noun", createdAt: "2025-12-19T10:55:00.000Z"),
            Word(id: "AR-003", term: "shukran (شكراً)", definition: "Thank you", example: "Shukran jazeelan.", description: "Expression of thanks", partOfSpeech: "phrase", createdAt: "2025-12-19T10:58:00.000Z")
        ]
    )
    
    // Rusça -> Türkçe (A2)
    nonisolated(unsafe) static let mockRuTrA2: BookcaseRequest = BookcaseRequest(
        id: "ru_tr/a2",
        sourceLanguage: "ru",
        targetLanguage: "tr",
        name: "a2",
        wordCount: 3,
        version: 1,
        updatedAt: "2025-12-19T09:00:00.000Z",
        words: [
            Word(id: "RU-001", term: "Привет (Privet)", definition: "Selam", example: "Привет, как дела?", description: "samimi selamlama", partOfSpeech: "interjection", createdAt: "2025-12-19T08:50:00.000Z"),
            Word(id: "RU-002", term: "Спасибо (Spasibo)", definition: "Teşekkürler", example: "Спасибо большое.", description: "teşekkür ifadesi", partOfSpeech: "interjection", createdAt: "2025-12-19T08:52:00.000Z"),
            Word(id: "RU-003", term: "Друг (Drug)", definition: "Arkadaş", example: "O benim en iyi arkadaşım.", description: "yakın tanıdık", partOfSpeech: "noun", createdAt: "2025-12-19T08:55:00.000Z")
        ]
    )
    
    // Korece -> İngilizce (US)
    nonisolated(unsafe) static let mockKoEnBeginner: BookcaseRequest = BookcaseRequest(
        id: "ko_en-US/beginner",
        sourceLanguage: "ko",
        targetLanguage: "en-US",
        name: "a1",
        wordCount: 3,
        version: 1,
        updatedAt: "2025-12-18T10:00:00.000Z",
        words: [
            Word(id: "KO-001", term: "안녕하세요 (Annyeonghaseyo)", definition: "Hello", example: "Annyeonghaseyo!", description: "Polite greeting", partOfSpeech: "phrase", createdAt: "2025-12-18T09:50:00.000Z"),
            Word(id: "KO-002", term: "감사합니다 (Gamsahamnida)", definition: "Thank you", example: "Gamsahamnida teacher.", description: "Polite thanks", partOfSpeech: "phrase", createdAt: "2025-12-18T09:52:00.000Z"),
            Word(id: "KO-003", term: "사랑 (Sarang)", definition: "Love", example: "Saranghae.", description: "Deep affection", partOfSpeech: "noun", createdAt: "2025-12-18T09:55:00.000Z")
        ]
    )
}

