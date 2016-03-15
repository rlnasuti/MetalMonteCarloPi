//
//  AppDelegate.swift
//  MetalMonteCarlo
//
//  Created by Robert Nasuti on 11/24/15.
//  Copyright © 2015 Robert Nasuti. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    var masterViewController: MasterViewController!

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        masterViewController = MasterViewController()
        window.contentView?.addSubview(masterViewController.view)
        masterViewController.view.frame = (window.contentView)!.bounds
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool {
        return true
    }
}

