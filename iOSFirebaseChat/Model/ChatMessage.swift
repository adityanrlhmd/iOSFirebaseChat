//
//  ChatMessage.swift
//  iOSFirebaseChat
//
//  Created by Aditt on 23/07/23.
//

import Foundation
import FirebaseFirestoreSwift

struct ChatMessage: Codable, Identifiable {
    @DocumentID var id: String?
    let fromId, toId, text: String
    let timestamp: Date
}
