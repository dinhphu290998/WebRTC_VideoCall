//
//  LoginViewModel.swift
//  Apprtc
//
//  Created by vmio69 on 12/13/17.
//  Copyright © 2017 Dhilip. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SocketRocket

class LoginViewModel {
    let validateUsername: Observable<Bool>
    let validatePassword: Observable<Bool>
    let loginEnable: Observable<Bool>
    let loginObservable: Observable<(NSDictionary?, Error?)>
    //swiftlint:disable large_tuple
    init(input: (socket: Observable<SRWebSocket>, username: Observable<String>, password: Observable<String>, loginTap: Observable<Void>)) {
        validateUsername = input.username.map {
            $0.count >= 3
        }.share(replay: 1, scope: SubjectLifetimeScope.forever)
        validatePassword = input.password.map {
            $0.count >= 3
            }.share(replay: 1, scope: SubjectLifetimeScope.forever)

        loginEnable = Observable.combineLatest(validateUsername, validatePassword) {$0 && $1}

        let usernameAndPassword = Observable.combineLatest(input.socket, input.username, input.password) {($0, $1, $2)}

        loginObservable = input.loginTap.withLatestFrom(usernameAndPassword).flatMapLatest { (socket, username, password) in
            return LoginViewModel.login(socket: socket, username: username, password: password).observeOn(MainScheduler.instance)
        }
    }

    private class func login(socket: SRWebSocket, username: String?, password: String?) -> Observable<(NSDictionary?, Error?)> {
        return Observable.create { (observer) -> Disposable in
            if let username = username, let password = password {
                socket.login(name: username, password: password) { (socketError, message) in

                }
                NotificationCenter.default.addObserver(forName: NSNotification.Name("notiLogin"), object: nil, queue: nil, using: { (noti) in

                })
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+4, execute: {
                    observer.onNext((nil, nil))
                })
            }
            return Disposables.create()
        }
    }
}
