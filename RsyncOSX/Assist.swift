//
//  Assist.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 03/10/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//
// swiftlint:disable line_length

import Foundation

final class Assist {
    var catalogs = Set<String>()
    var localhome = Set<String>()
    var remoteservers = Set<String>()
    var remoteusers = Set<String>()
    var nameandpaths: NamesandPaths?

    func setserversandlogins(_ configurations: [Configuration]?) {
        guard configurations != nil else { return }
        var configurations = configurations?.filter {
            SharedReference.shared.synctasks.contains($0.task)
        }
        for i in 0 ..< (configurations?.count ?? 0) {
            if let config = configurations?[i] {
                let remoteserver = config.offsiteServer
                let remoteuser = config.offsiteUsername
                if remoteservers.contains(remoteserver) == false {
                    remoteservers.insert(remoteserver)
                }
                if remoteusers.contains(remoteuser) == false {
                    remoteusers.insert(remoteuser)
                }
            }
        }
    }

    func setcatalogs() -> Set<String>? {
        if let atpath = nameandpaths?.userHomeDirectoryPath {
            var catalogs = Set<String>()
            do {
                for folders in try Folder(path: atpath).subfolders {
                    catalogs.insert(folders.name)
                }
                return catalogs.filter { $0.isEmpty == false }
            } catch {
                return nil
            }
        }
        return nil
    }

    func setlocalhome() -> Set<String> {
        var home = Set<String>()
        home.insert(nameandpaths?.userHomeDirectoryPath ?? "")
        return home
    }

    init(configurations: [Configuration]?) {
        nameandpaths = NamesandPaths(.configurations)
        localhome = setlocalhome()
        if let catalogs = setcatalogs() {
            self.catalogs = catalogs
        }
        setserversandlogins(configurations)
    }
}
