//
//  ReadScheduleJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 19/04/2021.
//

import Combine
import Foundation

class ReadScheduleJSON: NamesandPaths {
    var schedules: [ConfigurationSchedule]?
    var filenamedatastore = [SharedReference.shared.fileschedulesjson]
    var subscriptons = Set<AnyCancellable>()

    init(_ profile: String?, _ validhiddenID: Set<Int>?) {
        super.init(.configurations)
        // print("ReadScheduleJSON")
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
            .decode(type: [DecodeSchedule].self, decoder: JSONDecoder())
            .sink { completion in
                switch completion {
                case .finished:
                    // print("The publisher finished normally.")
                    return
                case let .failure(error):
                    let error = error as NSError
                    self.error(errordescription: error.description, errortype: .readerror)
                }
            } receiveValue: { [unowned self] data in
                var schedules = [ConfigurationSchedule]()
                for i in 0 ..< data.count {
                    var schedule = ConfigurationSchedule(data[i])
                    schedule.profilename = profile
                    // Validate that the hidden ID is OK,
                    // schedule != Scheduletype.stopped.rawValue, logs count > 0
                    if let validhiddenID = validhiddenID {
                        if validhiddenID.contains(schedule.hiddenID) {
                            schedules.append(schedule)
                        }
                    }
                }
                self.schedules = schedules
                subscriptons.removeAll()
            }.store(in: &subscriptons)
    }
}
