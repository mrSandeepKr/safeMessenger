//
//  ChatViewController.swift
//  SafeMessenger
//
//  Created by Sandeep Kumar on 01/06/21.
//

import UIKit
import MessageKit
import InputBarAccessoryView

class ChatViewController: MessagesViewController {
    
    private let viewModel: ChatViewModel
    
    init(viewModel: ChatViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DispatchQueue.background(background: {[weak self] in
            self?.viewModel.getUserInfoForChat {[weak self] success in
                guard let strongSelf = self else {
                    return
                }
                DispatchQueue.main.async {
                    strongSelf.title = strongSelf.viewModel.memberModel?.firstName
                }
            }
            self?.viewModel.markLastMsgAsReadIfNeeded()
            self?.addObserverOnMessages()
        })
        
        setUpMessageKitStuff()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.removeMessagesObserver()
    }
}

//MARK: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate
extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate, MessageCellDelegate {
    func currentSender() -> SenderType {
        return viewModel.selfSender
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return viewModel.messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return viewModel.messages.count
    }
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        let msg = viewModel.messages[indexPath.section]
        let incomingMsgColor = UIColor(named: "incomingMsgBackground") ?? .white
        return msg.isSenderLoggedIn() ? .systemBlue : incomingMsgColor
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let msg = message as? Message else {
            return
        }
        avatarView.set(avatar: Avatar(image: nil, initials: msg.getSenderInitials()))
        guard let sender = message.sender as? Sender
        else {
            return
        }
        avatarView.sd_setImage(with: URL(string: sender.imageURL), completed: nil)
    }
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let msg = message as? Message else {
            return
        }
        switch msg.kind {
        case .photo(let media):
            guard let url = media.url else {
                return
            }
            imageView.sd_setImage(with: url)
            break
        default:
            return
        }
    }
    
    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else { return }
        let msg = viewModel.messages[indexPath.section]
        switch msg.kind {
        case .photo(let media):
            guard let mediaObj = media as? MediaModel,
                  let imageURL = mediaObj.url
            else {
                return
            }
            let title = Utils.hrMinOnDateDateFormatter.string(from: Date())
            let vc = ImageViewerViewController(url: imageURL, title: title)
            let nav = UINavigationController(rootViewController: vc)
            nav.navigationItem.largeTitleDisplayMode = .always
            present(nav, animated: true)
            break
        default:
            break
        }
    }
    
    private func setUpMessageKitStuff() {
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        messageInputBar.delegate = self
        
        //This is the compose option selector
        let composeOptionBtn = InputBarButtonItem()
        composeOptionBtn.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        composeOptionBtn.setSize(CGSize(width: 35, height: 35), animated: false)
        composeOptionBtn.addTarget(self, action: #selector(composeOptionsBtnTapped), for: .touchUpInside)
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([composeOptionBtn], forStack: .left, animated: false)
        
        //Custom Send button
        messageInputBar.sendButton.title = ""
        messageInputBar.sendButton.image = UIImage(systemName: "arrowtriangle.forward.fill")
        messageInputBar.sendButton.setSize(CGSize(width: 35, height: 35), animated: false)
        messageInputBar.inputTextView.placeholder = "Type a message..."
    }
}

//MARK: InputBarAccessoryViewDelegate
extension ChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            print("ChatViewController: Trying to send empty message")
            return
        }
        
        viewModel.sendTextMessage(with: text) {[weak self] success, isNewConvo in
            if success {
                print("ChatViewController: Text message Send Success")
                if isNewConvo {
                    self?.addObserverOnMessages()
                }
                inputBar.inputTextView.text = ""
            }
            else {
                print("ChatViewController: Text message Send Failed")
            }
        }
    }
}

//MARK: Utils & Helpers
extension ChatViewController {
    private func updateViewForMessages() {
        messagesCollectionView.reloadData()
        // Opens the Message View on the last Message
        messagesCollectionView.scrollToItem(at: IndexPath(row: 0, section: viewModel.messages.count - 1), at: .top, animated: false)
    }
    
    private func addObserverOnMessages() {
        self.viewModel.getMessages(completion: { [weak self] success in
            guard let strongSelf = self else {
                return
            }
            DispatchQueue.main.async {
                strongSelf.updateViewForMessages()
            }
        })
    }
    
    @objc private func composeOptionsBtnTapped() {
        let actionSheet = UIAlertController(title: "Attach Media",
                                            message: "What should you like to attach",
                                            preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Photo", style: .default, handler: {[weak self] _ in
            self?.presentPhotoInputActionSheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Video", style: .default, handler: {[weak self] _ in
            self?.presentVideoInputActionSheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Location", style: .default, handler: { [weak self] _ in
            self?.presentPhotoInputActionSheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(actionSheet, animated: true)
    }
}

//MARK: UIImagePickerControllerDelegate
extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        if let selectedImage = info[.editedImage] as? UIImage {
            viewModel.sendPhotoMessage(with: selectedImage.pngData()) {[weak self] success, isNewConvo in
                if success {
                    print("ChatViewController: Image Send Success")
                    if isNewConvo {
                        self?.addObserverOnMessages()
                    }
                }
                else {
                    print("ChatViewController: Image Send Failed")
                }
            }
        }
        else if let vid = info[.referenceURL] as? URL {
            print(vid)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    private func presentPhotoInputActionSheet() {
        let actionSheet = UIAlertController(title: "Send Image",
                                            message: "What image would you like to attach?",
                                            preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Take Now",style: .default,handler: {[weak self] _ in
            self?.presentCamera()
        }))
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: {[weak self] _ in
            self?.presentPhotoPicker()
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    private func presentVideoInputActionSheet() {
        let actionSheet = UIAlertController(title: "Send Video",
                                            message: "What video would you like to attach?",
                                            preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Take Now",style: .default,handler: {[weak self] _ in
            self?.presentCamera(onlyVideo: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: {[weak self] _ in
            self?.presentPhotoPicker(onlyVideo: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    private func presentCamera(onlyVideo: Bool = false) {
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = self
        vc.allowsEditing = true
        if onlyVideo {
            vc.mediaTypes = ["public.movie"]
            vc.videoQuality = .typeMedium
        }
        present(vc, animated: true)
    }
    
    private func presentPhotoPicker(onlyVideo: Bool = false) {
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        vc.allowsEditing = true
        if onlyVideo {
            vc.mediaTypes = ["public.movie"]
            vc.videoQuality = .typeMedium
        }
        present(vc, animated: false)
    }
}
