//
//  ViewControllerCopyFiles.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 12/09/2016.
//  Copyright © 2016 Thomas Evensen. All rights reserved.
//
//  swiftlint:disable line_length type_body_length function_body_length

import Cocoa
import Foundation

protocol GetSource: AnyObject {
    func getSourceindex(index: Int)
}

protocol Updateremotefilelist: AnyObject {
    func updateremotefilelist()
}

class ViewControllerRestore: NSViewController, SetConfigurations, Delay, Connected, VcMain, Checkforrsync, Setcolor {
    var restorefilestask: RestorefilesTask?
    var fullrestoretask: FullrestoreTask?
    var remotefilelist: Remotefilelist?
    var index: Int?
    var restoretabledata: [String]?
    var diddissappear: Bool = false
    var outputprocess: OutputProcess?
    var maxcount: Int = 0
    weak var outputeverythingDelegate: ViewOutputDetails?

    @IBOutlet var info: NSTextField!
    @IBOutlet var restoretableView: NSTableView!
    @IBOutlet var rsynctableView: NSTableView!
    @IBOutlet var remotefiles: NSTextField!
    // @IBOutlet var restorecatalog: NSTextField!
    @IBOutlet var working: NSProgressIndicator!
    @IBOutlet var search: NSSearchField!
    @IBOutlet var estimatefilesbutton: NSButton!
    @IBOutlet var restorefilesbutton: NSButton!
    // Full restore part
    @IBOutlet var restorebutton: NSButton!
    @IBOutlet var tmprestorepath: NSTextField!
    @IBOutlet var selecttmptorestore: NSButton!
    @IBOutlet var estimatebutton: NSButton!

    @IBAction func totinfo(_: NSButton) {
        guard self.checkforrsync() == false else { return }
        globalMainQueue.async { () -> Void in
            self.presentAsSheet(self.viewControllerRemoteInfo!)
        }
    }

    @IBAction func quickbackup(_: NSButton) {
        guard self.checkforrsync() == false else { return }
        self.openquickbackup()
    }

    @IBAction func automaticbackup(_: NSButton) {
        self.presentAsSheet(self.viewControllerEstimating!)
    }

    // Selecting profiles
    @IBAction func profiles(_: NSButton) {
        globalMainQueue.async { () -> Void in
            self.presentAsSheet(self.viewControllerProfile!)
        }
    }

    // Userconfiguration button
    @IBAction func userconfiguration(_: NSButton) {
        globalMainQueue.async { () -> Void in
            self.presentAsSheet(self.viewControllerUserconfiguration!)
        }
    }

    // Abort button
    @IBAction func abort(_: NSButton) {
        self.working.stopAnimation(nil)
        self.restorefilestask?.abort()
        self.fullrestoretask?.abort()
        self.reset()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        ViewControllerReference.shared.setvcref(viewcontroller: .vcrestore, nsviewcontroller: self)
        self.outputeverythingDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vctabmain) as? ViewControllerMain
        self.restoretableView.delegate = self
        self.restoretableView.dataSource = self
        self.rsynctableView.delegate = self
        self.rsynctableView.dataSource = self
        self.working.usesThreadedAnimation = true
        self.search.delegate = self
        self.tmprestorepath.delegate = self
        self.remotefiles.delegate = self
        self.restoretableView.doubleAction = #selector(self.tableViewDoubleClick(sender:))
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        guard self.diddissappear == false else {
            globalMainQueue.async { () -> Void in
                self.rsynctableView.reloadData()
            }
            return
        }
        globalMainQueue.async { () -> Void in
            self.rsynctableView.reloadData()
        }
        self.reset()
        self.settmprestorepathfromuserconfig()
        // self.verifytmprestorepath()
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        self.diddissappear = true
    }

    // Restore files
    @IBAction func executerestorefiles(_: NSButton) {
        guard self.checkforrestorefiles() == true else { return }
        self.estimatefilesbutton.isEnabled = false
        self.presentAsSheet(self.viewControllerProgress!)
        self.restorefilestask?.executecopyfiles(remotefile: self.remotefiles!.stringValue, localCatalog: self.tmprestorepath!.stringValue, dryrun: false, updateprogress: self)
        self.outputprocess = self.restorefilestask?.outputprocess
    }

    @IBAction func estimaterestorefiles(_: NSButton) {
        guard self.restorefilestask != nil else {
            self.reset()
            return
        }
        guard self.verifytmprestorepath() == true else { return }
        self.working.startAnimation(nil)
        self.restorefilestask?.executecopyfiles(remotefile: self.remotefiles!.stringValue, localCatalog: self.tmprestorepath!.stringValue, dryrun: true, updateprogress: self)
        self.outputprocess = self.restorefilestask?.outputprocess
    }

    private func checkforrestorefiles() -> Bool {
        self.fullrestoretask = nil
        guard self.checkforrsync() == false else { return false }
        guard self.remotefiles.stringValue.isEmpty == false, self.tmprestorepath.stringValue.isEmpty == false else {
            self.info.textColor = setcolor(nsviewcontroller: self, color: .red)
            self.info.stringValue = Infocopyfiles().info(num: 3)
            return false
        }
        guard self.restorefilestask != nil else { return false }
        return true
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        let myTableViewFromNotification = (notification.object as? NSTableView)!
        if myTableViewFromNotification == self.restoretableView {
            self.info.textColor = setcolor(nsviewcontroller: self, color: .red)
            self.info.stringValue = Infocopyfiles().info(num: 0)
            let indexes = myTableViewFromNotification.selectedRowIndexes
            if let index = indexes.first {
                guard self.restoretabledata != nil else { return }
                self.remotefiles.stringValue = self.restoretabledata![index]
                guard self.remotefiles.stringValue.isEmpty == false, self.tmprestorepath.stringValue.isEmpty == false else {
                    self.info.stringValue = Infocopyfiles().info(num: 3)
                    return
                }
                self.estimatefilesbutton.isEnabled = true
                self.restorefilesbutton.isEnabled = false
                self.estimatebutton.isEnabled = false
                self.restorebutton.isEnabled = false
            }
        } else {
            let indexes = myTableViewFromNotification.selectedRowIndexes
            if let index = indexes.first {
                self.index = index
                self.restorefilestask = nil
                guard self.checkforgetremotefiles() == true else { return }
                self.info.stringValue = Infocopyfiles().info(num: 0)
                self.remotefiles.stringValue = ""
                let hiddenID = self.configurations!.getConfigurationsDataSourceSynchronize()![index].value(forKey: "hiddenID") as? Int ?? -1
                if self.configurations!.getConfigurationsDataSourceSynchronize()![index].value(forKey: "taskCellID") as? String ?? "" != ViewControllerReference.shared.snapshot {
                    self.restorefilestask = RestorefilesTask(hiddenID: hiddenID)
                    self.remotefilelist = Remotefilelist(hiddenID: hiddenID)
                    self.working.startAnimation(nil)
                } else {
                    let question: String = NSLocalizedString("Filelist for snapshot tasks might be huge?", comment: "Restore")
                    let text: String = NSLocalizedString("Start getting files?", comment: "Restore")
                    let dialog: String = NSLocalizedString("Start", comment: "Restore")
                    let answer = Alerts.dialogOrCancel(question: question, text: text, dialog: dialog)
                    if answer {
                        self.restorefilestask = RestorefilesTask(hiddenID: hiddenID)
                        self.remotefilelist = Remotefilelist(hiddenID: hiddenID)
                        self.working.startAnimation(nil)
                    } else {
                        self.reset()
                    }
                }
            } else {
                self.reset()
                globalMainQueue.async { () -> Void in
                    self.restoretableView.reloadData()
                }
            }
        }
    }

    @objc(tableViewDoubleClick:) func tableViewDoubleClick(sender _: AnyObject) {
        guard self.remotefiles.stringValue.isEmpty == false else { return }
        guard self.tmprestorepath.stringValue.isEmpty == false else { return }
        let question: String = NSLocalizedString("Copy single files or directory?", comment: "Restore")
        let text: String = NSLocalizedString("Start restore?", comment: "Restore")
        let dialog: String = NSLocalizedString("Restore", comment: "Restore")
        let answer = Alerts.dialogOrCancel(question: question, text: text, dialog: dialog)
        if answer {
            self.estimatefilesbutton.isEnabled = false
            self.working.startAnimation(nil)
            self.restorefilestask!.executecopyfiles(remotefile: remotefiles!.stringValue, localCatalog: tmprestorepath!.stringValue, dryrun: false, updateprogress: self)
        }
    }

    func reset() {
        self.index = nil
        self.restoretabledata = nil
        self.restorefilestask = nil
        self.fullrestoretask = nil
        self.info.stringValue = ""
        self.estimatefilesbutton.isEnabled = false
        self.restorefilesbutton.isEnabled = false
        self.restorebutton.isEnabled = false
        self.estimatebutton.isEnabled = false
    }

    func checkforgetremotefiles() -> Bool {
        if let index = self.index {
            guard self.connected(config: self.configurations!.getConfigurations()[index]) == true else {
                self.info.stringValue = Infocopyfiles().info(num: 4)
                self.info.textColor = self.setcolor(nsviewcontroller: self, color: .red)
                self.info.isHidden = false
                return false
            }
            guard self.configurations!.getConfigurations()[index].task != ViewControllerReference.shared.syncremote else {
                self.estimatebutton.isEnabled = false
                self.estimatefilesbutton.isEnabled = false
                self.info.stringValue = Infocopyfiles().info(num: 5)
                self.info.textColor = self.setcolor(nsviewcontroller: self, color: .red)
                self.info.isHidden = false
                self.restoretabledata = nil
                globalMainQueue.async { () -> Void in
                    self.restoretableView.reloadData()
                }
                return false
            }
            return true
        }
        return false
    }

    func checkforfullrestore() -> Bool {
        self.restorefilestask = nil
        if let index = self.index {
            guard self.connected(config: self.configurations!.getConfigurations()[index]) == true else {
                self.info.stringValue = Infocopyfiles().info(num: 4)
                self.info.textColor = self.setcolor(nsviewcontroller: self, color: .red)
                self.info.isHidden = false
                return false
            }
            guard self.configurations!.getConfigurations()[index].task != ViewControllerReference.shared.syncremote else {
                self.estimatebutton.isEnabled = false
                self.estimatefilesbutton.isEnabled = false
                self.info.stringValue = Infocopyfiles().info(num: 5)
                self.info.textColor = self.setcolor(nsviewcontroller: self, color: .red)
                self.info.isHidden = false
                return false
            }
            guard self.verifytmprestorepath() == true else { return false }
        }
        return true
    }

    // Full restore
    @IBAction func prepareforfullrestore(_: NSButton) {
        guard self.checkforrsync() == false else { return }
        guard self.checkforfullrestore() == true else { return }
        if let index = self.index {
            self.info.textColor = setcolor(nsviewcontroller: self, color: .green)
            let gotit: String = NSLocalizedString("Getting info, please wait...", comment: "Restore")
            self.info.stringValue = gotit
            self.info.isHidden = false
            self.estimatebutton.isEnabled = false
            self.working.startAnimation(nil)
            if ViewControllerReference.shared.restorepath != nil, self.selecttmptorestore.state == .on {
                self.fullrestoretask = FullrestoreTask(index: index, dryrun: true, tmprestore: true, updateprogress: self)
                self.outputprocess = self.fullrestoretask?.outputprocess
            } else {
                self.selecttmptorestore.state = .off
                self.fullrestoretask = FullrestoreTask(index: index, dryrun: true, tmprestore: false, updateprogress: self)
                self.outputprocess = self.fullrestoretask?.outputprocess
            }
        }
    }

    @IBAction func executefullrestore(_: NSButton) {
        guard self.checkforrsync() == false else { return }
        guard self.checkforfullrestore() == true else { return }
        let question: String = NSLocalizedString("Do you REALLY want to start a RESTORE ?", comment: "Restore")
        let text: String = NSLocalizedString("Cancel or Restore", comment: "Restore")
        let dialog: String = NSLocalizedString("Restore", comment: "Restore")
        let answer = Alerts.dialogOrCancel(question: question, text: text, dialog: dialog)
        if answer {
            if let index = self.index {
                self.info.textColor = setcolor(nsviewcontroller: self, color: .white)
                let gotit: String = NSLocalizedString("Executing restore...", comment: "Restore")
                self.info.stringValue = gotit
                self.info.isHidden = false
                self.estimatefilesbutton.isEnabled = false
                globalMainQueue.async { () -> Void in
                    self.presentAsSheet(self.viewControllerProgress!)
                }
                switch self.selecttmptorestore.state {
                case .on:
                    self.fullrestoretask = FullrestoreTask(index: index, dryrun: false, tmprestore: true, updateprogress: self)
                    self.outputprocess = self.fullrestoretask?.outputprocess
                case .off:
                    self.fullrestoretask = FullrestoreTask(index: index, dryrun: false, tmprestore: false, updateprogress: self)
                    self.outputprocess = self.fullrestoretask?.outputprocess
                default:
                    return
                }
            }
        }
    }

    func settmprestorepathfromuserconfig() {
        let setuserconfig: String = NSLocalizedString(" ... set in User configuration ...", comment: "Restore")
        self.tmprestorepath.stringValue = ViewControllerReference.shared.restorepath ?? setuserconfig
        if (ViewControllerReference.shared.restorepath ?? "").isEmpty == true {
            self.selecttmptorestore.state = .off
        } else {
            guard self.verifytmprestorepath() == true else { return }
            self.selecttmptorestore.state = .on
        }
    }

    func verifytmprestorepath() -> Bool {
        let fileManager = FileManager.default
        self.info.textColor = setcolor(nsviewcontroller: self, color: .red)
        if fileManager.fileExists(atPath: self.tmprestorepath.stringValue) == false {
            self.info.stringValue = Infocopyfiles().info(num: 1)
            return false
        } else {
            self.info.stringValue = Infocopyfiles().info(num: 0)
            return true
        }
    }

    @IBAction func toggletmprestore(_: NSButton) {
        guard self.verifytmprestorepath() == true else {
            self.selecttmptorestore.state = .off
            return
        }
        self.estimatebutton.isEnabled = true
        self.restorebutton.isEnabled = false
    }
}
