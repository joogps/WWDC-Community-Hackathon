//
//  Data.swift
//  ShareBits
//
//  Created by João Gabriel Pozzobon dos Santos on 12/06/21.
//

import SwiftUI
import GroupActivities

@MainActor
class Canvas: ObservableObject {
    @Published var currentScreen: CurrentScreen
    
    // Título do quadro
    @Published var title: String
    
    // Definem o número de linhas e colunas da grade
    let cols: Int
    let rows: Int
    
    // Array com as informações sobre cada ponto
    @Published var bits: [Bit]
    
    // Session do SharePlay
    @Published var session: GroupSession<ShareBitsActivity>?
    
    // Messenger do SharePlay
    var messenger: GroupSessionMessenger?
    
    init(currentScreen: CurrentScreen, title: String = "Canvas", cols: Int = 32, rows: Int = 32) {
        self.currentScreen = currentScreen
        
        self.title = title
        
        self.cols = cols
        self.rows = rows
        
        self.bits = []
        
        populateBits()
    }
    
    func toggleBit(index: Int, color: Color = .white) {
        bits[index].active.toggle()
        bits[index].color = color
        
        UISelectionFeedbackGenerator().selectionChanged()
        
        if let messenger = messenger {
            async {
                do {
                    try await messenger.send(ToggleBitMessage(index: index, active: bits[index].active))
                } catch {
                    // Pegou no pulo
                }
            }
        }
    }
    
    func populateBits() {
        for _ in 0...(cols*rows) {
            self.bits.append(Bit())
        }
    }
    
    func configureSession(_ session: GroupSession<ShareBitsActivity>) async {
        self.session = session
        
        
        let messenger = GroupSessionMessenger(session: session)
        self.messenger = messenger
        
        async {
            for await (message, _) in messenger.messages(of: ToggleBitMessage.self) {
                self.handle(message)
            }
        }
        
        session.join()
    }
    
    func handle(_ message: ToggleBitMessage) {
        bits[message.index].active = message.active
        //bits[message.index].color = message.color
        
        UISelectionFeedbackGenerator().selectionChanged()
    }
}

struct Bit: Identifiable {
    let id = UUID()
    
    var active = false
    var color = Color.white
}

struct ToggleBitMessage: Codable {
    let index: Int
    let active: Bool
}
