//
//  ConferenceViewController.swift
//  NewConferenceSample
//
//  Created by HoangDuoc on 8/10/20.
//  Copyright © 2020 HoangDuoc. All rights reserved.
//

import UIKit

class ConferenceViewController: UIViewController {
    @IBOutlet weak var listVideoView: ListVideoView!
    @IBOutlet weak var btMute: UIButton!
    @IBOutlet weak var btCamera: UIButton!

    var mute = false;
    var enableLocalVideo = true;
    var room: StringeeVideoRoom?
    var localTrack: StringeeVideoTrack?
    lazy var remoteTracks = [String: StringeeVideoTrack]()

    override func viewDidLoad() {
        super.viewDidLoad()

        UIApplication.shared.isStatusBarHidden = true
        UIApplication.shared.isIdleTimerDisabled = true
        self.listVideoView.videoViewDelegate = self

        if !StringeeImplement.shared.roomToken.isEmpty {
            StringeeVideo.joinRoom(StringeeImplement.shared.stringeeClient, roomToken: StringeeImplement.shared.roomToken, completion: { [weak self] (status, code, message, room, trackInfos, roomUserInfos) in
                guard let self = self else { return }

                if !status {
                    // That bai
                    self.dismissViewController()
                    return
                }

                self.room = room
                self.room?.delegate = self

                // Publish local track
                self.localTrack = StringeeVideo.createLocalVideoTrack(StringeeImplement.shared.stringeeClient, options: StringeeVideoTrackOption(), delegate: self)
                self.room?.publish(self.localTrack, completion: { (status, code, message) in
                    print("Publish... \(String(describing: message))")
                })

                // Subscribe remote tracks
                for trackInfo in trackInfos {
                    self.room?.subscribe(trackInfo, options: StringeeVideoTrackOption(), delegate: self, completion: { (status, code, message, track) in
                        print("Subscribe... \(String(describing: message))")
                        if status, let track = track {
                            self.remoteTracks[track.serverId] = track
                        }
                    })
                }

            })
        } else {
            self.dismissViewController()
        }
    }

    // MARK: - Private Actions

    private func dismissViewController() {
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
            UIApplication.shared.isStatusBarHidden = false
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }


    // MARK: - Outlet Actions

    @IBAction func endTapped(_ sender: Any) {
        guard let room = room else {
            return
        }

        room.leave(true) { (status, code, message) in
            print("Leave Room... \(String(describing: message))")
            StringeeAudioManager.instance()?.setLoudspeaker(false)
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.dismissViewController()
            }
        }
    }

    @IBAction func muteTapped(_ sender: Any) {
        guard let localTrack = self.localTrack else {
            return
        }

        if localTrack.mute(!mute) {
            mute = !mute
            let imageName = mute ? "call_mute" : "call_unmute"
            btMute.setBackgroundImage(UIImage(named: imageName), for: .normal)
        }
    }

    @IBAction func cameraTapped(_ sender: Any) {
        guard let localTrack = self.localTrack else {
            return
        }

        if localTrack.enableLocalVideo(!enableLocalVideo) {
            enableLocalVideo = !enableLocalVideo
            let imageName = enableLocalVideo ? "video_enable" : "video_disable"
            btCamera.setBackgroundImage(UIImage(named: imageName), for: .normal)
        }
    }

    @IBAction func switchCameraTapped(_ sender: Any) {
        guard let localTrack = self.localTrack else {
            return
        }
        localTrack.switchCamera()
    }
}

extension ConferenceViewController: StringeeVideoRoomDelegate {
    func join(_ room: StringeeVideoRoom!, userInfo: StringeeRoomUserInfo!) {
        print("Event Join... \(String(describing: userInfo))")
    }

    func leave(_ room: StringeeVideoRoom!, userInfo: StringeeRoomUserInfo!) {
        print("Event Leave... \(String(describing: userInfo))")
    }

    func addTrack(_ room: StringeeVideoRoom!, trackInfo: StringeeVideoTrackInfo!) {
        print("Add Track... \(String(describing: trackInfo))")
        self.room?.subscribe(trackInfo, options: StringeeVideoTrackOption(), delegate: self, completion: { (status, code, message, track) in
            print("Subscribe... \(String(describing: message))")
            if status, let track = track {
                self.remoteTracks[track.serverId] = track
            }
        })
    }

    func removeTrack(_ room: StringeeVideoRoom!, trackInfo: StringeeVideoTrackInfo!) {
        print("Remove Track... \(String(describing: trackInfo))")
        if let track = remoteTracks[trackInfo.serverId] {
            let videoViews = track.detach()
            if let videoView = videoViews?.first {
                self.listVideoView.remove(videoView: videoView)
            }
        }
    }

    func newMessage(_ room: StringeeVideoRoom!, msg: [AnyHashable : Any]!, fromUser: StringeeRoomUserInfo!) {
        print("Event New Message... \(String(describing: msg))")
    }
}

extension ConferenceViewController: StringeeVideoTrackDelegate {
    func ready(_ track: StringeeVideoTrack!) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let videoView = track.attach() else { return }
            StringeeAudioManager.instance()?.setLoudspeaker(true)
            if track.isLocal {
                videoView.frame = CGRect(origin: .zero, size: self.view.frame.size)
                self.view.insertSubview(videoView, at: 0)
            } else {
                self.listVideoView.add(videoView: videoView)
            }
        }
    }
}

extension ConferenceViewController: ListVideoViewDelegate {
    func videoViewTapped(videoView: StringeeVideoView) {
        if let mainVideoView = self.view.subviews[0] as? StringeeVideoView {
            mainVideoView.removeFromSuperview()
            mainVideoView.frame = CGRect(origin: .zero, size: CGSize(width: 120, height: 180))
            self.listVideoView.add(videoView: mainVideoView)
        }

        self.listVideoView.remove(videoView: videoView)
        DispatchQueue.main.async {
            videoView.frame = CGRect(origin: .zero, size: self.view.frame.size)
            self.view.insertSubview(videoView, at: 0)
        }
    }
}


