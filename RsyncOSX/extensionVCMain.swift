//
//  extensionsViewControllertabMain.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 31.05.2018.
//  Copyright © 2018 Thomas Evensen. All rights reserved.
//

import Cocoa
import Foundation

// Get output from rsync command
extension ViewControllerMain: GetOutput {
    // Get information from rsync output.
    func getoutput() -> [String] {
        return TrimTwo(outputprocess?.getOutput() ?? []).trimmeddata
    }
}

// Scheduled task are changed, read schedule again og redraw table
extension ViewControllerMain: Reloadandrefresh {
    // Refresh tableView in main
    func reloadtabledata() {
        globalMainQueue.async { () in
            self.mainTableView.reloadData()
        }
    }
}

// Get index of selected row
extension ViewControllerMain: GetSelecetedIndex {
    func getindex() -> Int? {
        return localindex
    }
}

// New profile is loaded.
extension ViewControllerMain: NewProfile {
    // Function is called from profiles when new or default profiles is seleceted
    func newprofile(profile: String?, selectedindex: Int?) {
        if let index = selectedindex {
            profilepopupbutton.selectItem(at: index)
        } else {
            initpopupbutton()
        }
        reset()
        singletask = nil
        deselect()
        // Read configurations
        configurations = createconfigurationsobject(profile: profile)
        // Make sure loading profile
        displayProfile()
        reloadtabledata()
    }

    func reloadprofilepopupbutton() {
        globalMainQueue.async { () in
            self.displayProfile()
        }
    }

    func createconfigurationsobject(profile: String?) -> Configurations? {
        configurations = nil
        configurations = Configurations(profile: profile)
        return configurations
    }
}

// Check for remote connections, reload table when completed.
extension ViewControllerMain: Connections {
    func displayConnections() {
        globalMainQueue.async { () in
            self.mainTableView.reloadData()
        }
    }
}

extension ViewControllerMain: NewVersionDiscovered {
    func notifyNewVersion() {
        globalMainQueue.async { () in
            self.info.stringValue = Infoexecute().info(num: 9)
        }
    }
}

extension ViewControllerMain: DismissViewController {
    func dismiss_view(viewcontroller: NSViewController) {
        dismiss(viewcontroller)
        globalMainQueue.async { () in
            self.mainTableView.reloadData()
            self.displayProfile()
        }
    }
}

// Deselect a row
extension ViewControllerMain: DeselectRowTable {
    // deselect a row after row is deleted
    func deselect() {
        if let index = localindex {
            SharedReference.shared.process = nil
            localindex = nil
            mainTableView.deselectRow(index)
        }
    }
}

// If rsync throws any error
extension ViewControllerMain: RsyncError {
    func rsyncerror() {
        // Set on or off in user configuration
        globalMainQueue.async { () in
            self.info.stringValue = "Rsync error, see logfile..."
            self.info.textColor = self.setcolor(nsviewcontroller: self, color: .red)
            self.info.isHidden = false
            guard SharedReference.shared.haltonerror == true else { return }
            self.deselect()
            _ = InterruptProcess()
            self.singletask?.error()
        }
    }
}

// If, for any reason, handling files or directory throws an error
extension ViewControllerMain: ErrorMessage {
    func errormessage(errorstr: String, error errortype: RsyncOSXTypeErrors) {
        globalMainQueue.async { () in
            if errortype == .logfilesize {
                self.info.stringValue = "Reduce size logfile, filesize is: " + errorstr
                self.info.textColor = self.setcolor(nsviewcontroller: self, color: .red)
                self.info.isHidden = false
            } else {
                self.outputprocess?.addlinefromoutput(str: errorstr + "\n" + errorstr)
                self.info.stringValue = "Some error: see logfile."
                self.info.textColor = self.setcolor(nsviewcontroller: self, color: .red)
                self.info.isHidden = false
            }
            var message = [String]()
            message.append(errorstr)
            _ = Logfile(message, error: true)
        }
    }
}

// Abort task from progressview
extension ViewControllerMain: Abort {
    // Abort the task
    func abortOperations() {
        _ = InterruptProcess()
        working.stopAnimation(nil)
        localindex = nil
        info.stringValue = ""
    }
}

// Extensions from here are used in newSingleTask
extension ViewControllerMain: StartStopProgressIndicatorSingleTask {
    func startIndicatorExecuteTaskNow() {
        working.startAnimation(nil)
    }

    func startIndicator() {
        working.startAnimation(nil)
    }

    func stopIndicator() {
        working.stopAnimation(nil)
    }
}

extension ViewControllerMain: GetConfigurationsObject {
    func getconfigurationsobject() -> Configurations? {
        guard configurations != nil else { return nil }
        return configurations
    }
}

extension ViewControllerMain: ErrorOutput {
    func erroroutput() {
        info.stringValue = Infoexecute().info(num: 2)
    }
}

extension ViewControllerMain: SendOutputProcessreference {
    func sendoutputprocessreference(outputprocess: OutputfromProcess?) {
        self.outputprocess = outputprocess
    }
}

extension ViewControllerMain: OpenQuickBackup {
    func openquickbackup() {
        globalMainQueue.async { () in
            self.presentAsSheet(self.viewControllerQuickBackup!)
        }
    }
}

extension ViewControllerMain: Count {
    func maxCount() -> Int {
        return TrimTwo(outputprocess?.getOutput() ?? []).maxnumber
    }

    func inprogressCount() -> Int {
        return outputprocess?.getOutput()?.count ?? 0
    }
}

extension ViewControllerMain: ViewOutputDetails {
    func getalloutput() -> [String] {
        return outputprocess?.getOutput() ?? []
    }

    func reloadtable() {
        weak var localreloadDelegate: Reloadandrefresh?
        localreloadDelegate = SharedReference.shared.getvcref(viewcontroller: .vcalloutput) as? ViewControllerAllOutput
        localreloadDelegate?.reloadtabledata()
    }

    func appendnow() -> Bool {
        if SharedReference.shared.getvcref(viewcontroller: .vcalloutput) != nil {
            return true
        } else {
            return false
        }
    }

    func outputfromrsync(data: [String]?) {
        if outputprocess == nil {
            outputprocess = OutputfromProcess()
        }
        if let data = data {
            for i in 0 ..< data.count {
                outputprocess?.addlinefromoutput(str: data[i])
            }
        }
    }
}

enum Color {
    case red
    case white
    case green
    case black
}

protocol Setcolor: AnyObject {
    func setcolor(nsviewcontroller: NSViewController, color: Color) -> NSColor
}

extension Setcolor {
    private func isDarkMode(view: NSView) -> Bool {
        return view.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }

    func setcolor(nsviewcontroller: NSViewController, color: Color) -> NSColor {
        let darkmode = isDarkMode(view: nsviewcontroller.view)
        switch color {
        case .red:
            return .red
        case .white:
            if darkmode {
                return .white
            } else {
                return .black
            }
        case .green:
            if darkmode {
                return .green
            } else {
                return .blue
            }
        case .black:
            if darkmode {
                return .white
            } else {
                return .black
            }
        }
    }
}

protocol Checkforrsync: AnyObject {
    func checkforrsync() -> Bool
}

extension Checkforrsync {
    func checkforrsync() -> Bool {
        if SharedReference.shared.norsync == true {
            _ = Norsync()
            return true
        } else {
            return false
        }
    }
}

// Protocol for start,stop, complete progressviewindicator
protocol StartStopProgressIndicator: AnyObject {
    func start()
    func stop()
}

// Protocol for either completion of work or update progress when Process discovers a
// process termination and when filehandler discover data
protocol UpdateProgress: AnyObject {
    func processTermination()
    func fileHandler()
}

protocol ViewOutputDetails: AnyObject {
    func reloadtable()
    func appendnow() -> Bool
    func getalloutput() -> [String]
    func outputfromrsync(data: [String]?)
}

// Get multiple selected indexes
protocol GetMultipleSelectedIndexes: AnyObject {
    func getindexes() -> [Int]
    func multipleselection() -> Bool
}

extension ViewControllerMain: GetMultipleSelectedIndexes {
    func multipleselection() -> Bool {
        return multipeselection
    }

    func getindexes() -> [Int] {
        if let indexes = indexset {
            return indexes.map { $0 }
        } else {
            return []
        }
    }
}

extension ViewControllerMain: DeinitExecuteTaskNow {
    func deinitexecutetasknow() {
        executetasknow = nil
        info.stringValue = Infoexecute().info(num: 0)
    }
}

extension ViewControllerMain: DisableEnablePopupSelectProfile {
    func enableselectpopupprofile() {
        profilepopupbutton.isEnabled = true
    }

    func disableselectpopupprofile() {
        profilepopupbutton.isEnabled = false
    }
}

extension ViewControllerMain: Sidebarbuttonactions {
    func sidebarbuttonactions(action: Sidebaractionsmessages) {
        switch action {
        case .Delete:
            delete()
        default:
            return
        }
    }
}
