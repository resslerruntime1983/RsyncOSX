//
//  Snapshotlogsandcatalogs.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 22.01.2018.
//  Copyright © 2018 Thomas Evensen. All rights reserved.
//

import Foundation

final class Snapshotlogsandcatalogs {
    var logrecordssnapshot: [Logrecordsschedules]?
    var config: Configuration?
    var snapshotcatalogstodelete: [String]?
    typealias Catalogsanddates = (String, Date)
    var catalogsanddates: [Catalogsanddates]?
    var firstsnapshotctalognodelete: String?

    @MainActor
    private func getremotecataloginfo() async {
        let arguments = RestorefilesArguments(task: .snapshotcatalogs,
                                              config: config,
                                              remoteFile: nil,
                                              localCatalog: nil,
                                              drynrun: nil)
        let command = RsyncAsync(arguments: arguments.getArguments(),
                                 processtermination: processtermination)
        await command.executeProcess()
    }

    // Getting, from process, remote snapshotcatalogs
    // sort snapshotcatalogs
    private func prepareremotesnapshotcatalogs(data: [String]?) {
        // Check for split lines and merge lines if true
        let data = PrepareOutput(data ?? [])
        if data.splitlines { data.alignsplitlines() }
        var catalogs = TrimOne(data.trimmeddata).trimmeddata
        var datescatalogs = TrimFour(data.trimmeddata).trimmeddata
        // drop index where row = "./."
        if let index = catalogs.firstIndex(where: { $0 == "./." }) {
            catalogs.remove(at: index)
            datescatalogs.remove(at: index)
        }
        catalogsanddates = [Catalogsanddates]()
        let dateformatter = DateFormatter()
        dateformatter.dateFormat = "YYYY/mm/dd"
        for i in 0 ..< catalogs.count {
            if let date = dateformatter.date(from: datescatalogs[i]) {
                catalogsanddates?.append((catalogs[i], date))
            }
        }
        catalogsanddates = catalogsanddates?.sorted { cat1, cat2 in
            (Int(cat1.0.dropFirst(2)) ?? 0) > (Int(cat2.0.dropFirst(2)) ?? 0)
        }
    }

    // Calculating days since snaphot was executed
    private func calculateddayssincesynchronize() {
        for i in 0 ..< (logrecordssnapshot?.count ?? 0) {
            if let dateRun = logrecordssnapshot?[i].dateExecuted {
                if let secondssince = calculatedays(datestringlocalized: dateRun) {
                    logrecordssnapshot?[i].days = String(format: "%.2f", secondssince / (60 * 60 * 24))
                    logrecordssnapshot?[i].seconds = Int(secondssince)
                }
            }
        }
    }

    // Merging remote snaphotcatalogs and existing logs
    private func mergeremotecatalogsandlogs() {
        var adjustedlogrecords = [Logrecordsschedules]()
        let mycatalogs = catalogsanddates
        let mylogrecords = logrecordssnapshot
        // Loop through all real catalogs, find the corresponding logrecord if any
        // and add the adjusted record
        for i in 0 ..< (mycatalogs?.count ?? 0) {
            // Real snapshotcatalog collected from remote and
            // drop the "./" and add "(" and ")" before filter
            let realsnapshotcatalog = "(" + (mycatalogs?[i].0 ?? "").dropFirst(2) + ")"
            let record = mylogrecords?.filter { $0.resultExecuted.contains(realsnapshotcatalog) }
            // Found one record
            if record?.count ?? 0 > 0 {
                if var record = record?[0] {
                    let catalogelementlog = record.resultExecuted.split(separator: " ")[0]
                    let snapshotcatalogfromschedulelog = "./" + catalogelementlog.dropFirst().dropLast()
                    record.period = "... not yet tagged ..."
                    record.snapshotCatalog = snapshotcatalogfromschedulelog
                    adjustedlogrecords.append(record)
                }
            }
        }
        logrecordssnapshot = adjustedlogrecords.sorted { cat1, cat2 -> Bool in
            if let cat1 = cat1.snapshotCatalog,
               let cat2 = cat2.snapshotCatalog
            {
                return (Int(cat1.dropFirst(2)) ?? 0) > (Int(cat2.dropFirst(2)) ?? 0)
            }
            return false
        }
        guard logrecordssnapshot?.count ?? 0 > 0 else { return }
        firstsnapshotctalognodelete = logrecordssnapshot?[(logrecordssnapshot?.count ?? 0) - 1].snapshotCatalog
    }

    func calculatedays(datestringlocalized: String) -> Double? {
        guard datestringlocalized != "" else { return nil }
        let lastbackup = datestringlocalized.localized_date_from_string()
        let seconds: TimeInterval = lastbackup.timeIntervalSinceNow
        return seconds * -1
    }

    func preparesnapshotcatalogsfordelete() {
        for i in 0 ..< (logrecordssnapshot?.count ?? 0) where logrecordssnapshot?[i].selectCellID == 1 {
            if self.snapshotcatalogstodelete == nil { self.snapshotcatalogstodelete = [] }
            let snaproot = self.config?.offsiteCatalog
            let snapcatalog = self.logrecordssnapshot?[i].snapshotCatalog
            if snapcatalog != firstsnapshotctalognodelete {
                self.snapshotcatalogstodelete?.append((snaproot ?? "") + (snapcatalog ?? "").dropFirst(2))
            }
            if self.snapshotcatalogstodelete?.count ?? 0 == 0 { self.snapshotcatalogstodelete = nil }
        }
    }

    func countbydays(num: Double) -> Int {
        guard logrecordssnapshot?.count ?? 0 > 0 else { return 0 }
        var j = 0
        for i in 0 ..< (logrecordssnapshot?.count ?? 0) - 1 {
            if let days: String = logrecordssnapshot?[i].days {
                if Double(days) ?? 0 >= num {
                    j += 1
                }
            }
        }
        return j - 1
    }

    init(config: Configuration) {
        guard config.task == SharedReference.shared.snapshot else { return }
        self.config = config
        logrecordssnapshot = ScheduleLoggData(hiddenID: config.hiddenID).loggrecords
        Task {
            await getremotecataloginfo()
        }
    }
}

extension Snapshotlogsandcatalogs {
    func processtermination(data: [String]?) {
        prepareremotesnapshotcatalogs(data: data)
        calculateddayssincesynchronize()
        mergeremotecatalogsandlogs()
        weak var reloadsnapshots: Reloadandrefresh?
        reloadsnapshots = SharedReference.shared.getvcref(viewcontroller: .vcsnapshot) as? ViewControllerSnapshots
        reloadsnapshots?.reloadtabledata()
    }
}
