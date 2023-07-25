//
//  ChatUser.swift
//  iOSFirebaseChat
//
//  Created by Aditt on 22/07/23.
//

import Foundation
import FirebaseFirestoreSwift

struct ChatUser: Codable, Identifiable {
    @DocumentID var id: String?
    let uid, email, profileImageUrl: String
}

