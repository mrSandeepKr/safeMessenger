//
//  ChatService.swift
//  SafeMessenger
//
//  Created by Sandeep Kumar on 09/06/21.
//

import Foundation
import FirebaseDatabase

enum ChatServiceError: Error {
    case FailedToCreateThread
}

final class ChatService {
    static let shared = ChatService()
    
    private let database = Database.database(url: URLStrings.databaseURL).reference()
}

extension ChatService {
    func getAllConversations(with member: String, completion: (Result<Bool, Error>) -> Void) {
        
    }
    
    func createNewConversation(with members: [String],
                               convo: ConversationObject,
                               convoThread: ConversationThread,
                               completion: @escaping (Result<Bool, Error>) -> Void) {
        members.forEach { member in
            addConversation(to: member, convo: convo)
        }
        updateConversationThread(for: convoThread, completion: completion)
    }
    func getAllMessagesForConversation(with id: String, completion: (Result<Bool, Error>) -> Void) {
        
    }
    
    func sendMessage(to conversation: String, message: Message, completion: (Result<Bool, Error>) -> Void) {
        
    }
}

extension ChatService {
    private func addConversation(to email: String,
                                 convo: ConversationObject,
                                 completion: @escaping ((Result<Bool, Error>) -> Void) = {_ in}) {
        guard !email.isEmpty, let email = Utils.shared.safeEmail(email: email) else {
            print("ChatService: Add conversation Failed because of empty email")
            return
        }
        let ref = database.child(email)
        ref.observeSingleEvent(of: .value) { snapshot in
            guard var userNode = snapshot.value as? User else {
                completion(.failure(ApiHandlerErrors.userNotFound))
                print("ChatService: Add conversation Failed because \(email) not found")
                return
            }
            
            if var conversations = userNode[Constants.conversations] as? [[String: Any]] {
                conversations.append(convo.serialisedObject())
                userNode[Constants.conversations] = conversations
            }
            else {
                userNode[Constants.conversations] = [convo.serialisedObject()]
            }
            
            ref.setValue(userNode) { err, databaseRef in
                guard err == nil else {
                    completion(.failure(err!))
                    return
                }
                print("ChatService: Add Conversation Successful")
                completion(.success(true))
            }
        }
    }
    
    //TODO: make things more decoupled - Only update the thread with latest msgs created here.
    private func updateConversationThread(for thread:ConversationThread,
                                          completion: @escaping (Result<Bool,Error>) -> Void) {
        database.child(thread.convoID).setValue(thread.serialisedObject()) { err, _ in
            guard err != nil else {
                completion(.failure(ChatServiceError.FailedToCreateThread))
                return
            }
            completion(.success(true))
        }
    }
}
