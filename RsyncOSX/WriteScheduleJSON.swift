//
//  WriteScheduleJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 27/04/2021.
//

import Combine
import Foundation

class WriteScheduleJSON: NamesandPaths {
    var subscriptons = Set<AnyCancellable>()
    // Filename for JSON file
    var filenamejson = SharedReference.shared.fileschedulesjson

    private func writeJSONToPersistentStore(_ data: String?) {
        if var atpath = fullpathmacserial {
            do {
                if profile != nil {
                    atpath += "/" + (profile ?? "")
                }
                let folder = try Folder(path: atpath)
                let file = try folder.createFile(named: filenamejson)
                if let data = data {
                    try file.write(data)
                }
            } catch let e {
                let error = e as NSError
                self.error(errordescription: error.description, errortype: .readerror)
            }
        }
    }

    // We have to remove UUID and computed properties ahead of writing JSON file
    // done in the .map operator
    @discardableResult
    init(_ profile: String?, _ schedules: [ConfigurationSchedule]?) {
        super.init(.configurations)
        // print("WriteScheduleJSON")
        // Set profile and filename ahead of encoding an write
        self.profile = profile
        schedules.publisher
            .map { schedules -> [DecodeSchedule] in
                var data = [DecodeSchedule]()
                for i in 0 ..< schedules.count where schedules[i].delete ?? false == false {
                    data.append(DecodeSchedule(schedules[i]))
                }
                return data
            }
            .encode(encoder: JSONEncoder())
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    // print("The publisher finished normally.")
                    return
                case let .failure(error):
                    let error = error as NSError
                    self.error(errordescription: error.description, errortype: .readerror)
                }
            }, receiveValue: { [unowned self] result in
                let jsonfile = String(data: result, encoding: .utf8)
                writeJSONToPersistentStore(jsonfile)
                subscriptons.removeAll()
            })
            .store(in: &subscriptons)
    }
}
