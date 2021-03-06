//
//  ClassPeriodView.swift
//  TerpScheduler
//
//  Created by Ben Hall on 12/18/14.
//  Copyright (c) 2014 Tampa Preparatory School. All rights reserved.
//

import UIKit

protocol ClassPeriodDataSource {
  func getClassData(period: Int)->SchoolClass
  func setClassData(data:SchoolClass, forIndex index:Int)
  func openWebView(url: NSURL)
  func shouldShadeRow(_: Bool, forPeriod: Int)
}

@IBDesignable
class ClassPeriodViewController: UIViewController {
  @IBAction func openWebView(sender: UILabel){
    let v = self.view as ClassPopupView
    let url_string = v.HaikuURLInput!.text
    var url: NSURL
    if url_string == "" {
      url = NSURL(string: "http://tampaprep.haikulearning.com")!
    } else if v.HaikuURLInput!.text.hasPrefix("http://"){
      url = NSURL(string: url_string)!
    } else if url_string.hasPrefix("https://"){
      //web view has real hard time with https. this is a hack.
      let real_url_string = url_string.stringByReplacingOccurrencesOfString("https", withString: "http", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)
      url = NSURL(string: real_url_string)!
    }
    else{
      url = NSURL(string: "http://"+url_string)!
    }
    saveData()
    self.dismissViewControllerAnimated(false, completion: nil)
    delegate!.openWebView(url)
  }
  var receivedClassData : SchoolClass?
  var delegate : ClassPeriodDataSource?
  var _index: Int = -1
  var index : Int {
    get { return _index }
    set(value) {
      _index = value
      receivedClassData = delegate!.getClassData(index)
    }
  }
  
  func saveData(){
    let v = self.view as ClassPopupView
    let outputClassData = v.getContent()
    delegate!.setClassData(outputClassData, forIndex: index)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    let v = self.view as ClassPopupView
    v.setContent(receivedClassData!)
    if receivedClassData!.isStudyHall {
      delegate!.shouldShadeRow(true, forPeriod: index+1)
    }
  }
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
  }
  
  override func viewWillDisappear(animated: Bool) {
    super.viewWillDisappear(animated)
    saveData()
  }
  
}
