//
//  ReadConfigurationJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 19/04/2021.
//

import Combine
import Foundation

struct UniqueserversandLogins: Hashable {
    var offsiteUsername: String?
    var offsiteServer: String?

    init(_ username: String,
         _ servername: String)
    {
        offsiteServer = servername
        offsiteUsername = username
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(offsiteUsername)
        hasher.combine(offsiteServer)
    }
}

class ReadConfigurationJSON: NamesandPaths {
    var configurations: [Configuration]?
    var filenamedatastore = [SharedReference.shared.fileconfigurationsjson]
    var subscriptons = Set<AnyCancellable>()
    var validhiddenIDs = Set<Int>()

    func setuniqueserversandlogins() -> [UniqueserversandLogins]? {
        let configs = configurations?.filter {
            SharedReference.shared.synctasks.contains($0.task)
        }
        guard configs?.count ?? 0 > 0 else { return nil }
        var uniqueserversandlogins = [UniqueserversandLogins]()
        for i in 0 ..< (configs?.count ?? 0) {
            if let config = configs?[i] {
                if config.offsiteUsername.isEmpty == false, config.offsiteServer.isEmpty == false {
                    let record = UniqueserversandLogins(config.offsiteUsername, config.offsiteServer)
                    if uniqueserversandlogins.filter({ ($0.offsiteUsername == record.offsiteUsername) &&
                            ($0.offsiteServer == record.offsiteServer)
                    }).count == 0 {
                        uniqueserversandlogins.append(record)
                    }
                }
            }
        }
        return uniqueserversandlogins
    }

    init(_ profile: String?) {
        super.init(.configurations)
        filenamedatastore.publisher
            .compactMap { filenamejson -> URL in
                var filename = ""
                if let profile = profile, let path = fullpathmacserial {
                    filename = path + "/" + profile + "/" + filenamejson
                } else {
                    if let path = fullpathmacserial {
                        filename = path + "/" + filenamejson
                    }
                }
                return URL(fileURLWithPath: filename)
            }
            .tryMap { url -> Data in
                try Data(contentsOf: url)
            }
            .decode(type: [DecodeConfiguration].self, decoder: JSONDecoder())
            .sink { completion in
                switch completion {
                case .finished:
                    return
                case let .failure(error):
                    // Mark first time used, only for default profile
                    if profile == nil {
                        SharedReference.shared.firsttime = true
                    }
                    let error = error as NSError
                    self.error(errordescription: error.description, errortype: .readerror)
                }
                // print("completion with \(completion)")
            } receiveValue: { [unowned self] data in
                var configurations = [Configuration]()
                for i in 0 ..< data.count {
                    let configuration = Configuration(data[i])
                    // Validate sync task
                    if SharedReference.shared.synctasks.contains(configuration.task) {
                        if validhiddenIDs.contains(configuration.hiddenID) == false {
                            configurations.append(configuration)
                            // Create set of validated hidden IDs, used when
                            // loading schedules and logs
                            validhiddenIDs.insert(configuration.hiddenID)
                        }
                    }
                }
                self.configurations = configurations
                subscriptons.removeAll()
            }.store(in: &subscriptons)
    }
}
