//
//  GenericRepository.swift
//  TerpScheduler
//
//  Created by Ben Hall on 1/21/15.
//  Copyright (c) 2015 Tampa Preparatory School. All rights reserved.
//

import UIKit
import CoreData

func dateRange(start: NSDate, stop: NSDate)->[NSDate]{
  var dates: [NSDate] = []
  var currentDate = start
  while currentDate.compare(stop) != NSComparisonResult.OrderedDescending{
    dates.append(currentDate)
    currentDate = NSCalendar.currentCalendar().dateByAddingUnit(NSCalendarUnit.CalendarUnitDay, value: 1, toDate: currentDate, options: NSCalendarOptions.allZeros)!
  }
  return dates
}

enum RepositoryFilterType {
  case byDate
  case byPeriod
  case byID
  case byDateAndPeriod
  case byDateAndPeriodAndID
  case byDateBetween
  case byTitleIsEmpty
}

struct FilterValues: Filterable {
  var date: NSDate
  var period: Int
  var id: NSManagedObjectID?
  var stopDate: NSDate?
  var shortTitle: String
}

extension FilterValues {
  init(fromFilterable: Filterable){
    self.date = fromFilterable.date
    self.id = fromFilterable.id
    self.period = fromFilterable.period
    self.shortTitle = fromFilterable.shortTitle
  }
  
  init(optDate: NSDate?, optID: NSManagedObjectID?, optPeriod: Int?, optTitle: String?){
    self.date = optDate ?? NSDate()
    self.id = optID ?? NSManagedObjectID()
    self.period = optPeriod ?? -1
    self.shortTitle = optTitle ?? "_"
  }
}

protocol Filterable {
  var date: NSDate { get }
  var period: Int { get }
  var id: NSManagedObjectID? { get }
  var shortTitle: String { get }
}

protocol DataObject {
  init(entity: NSManagedObject)
  func toEntity(inContext context: NSManagedObjectContext)->NSManagedObject
}

class Repository<T: protocol<Filterable, DataObject>, U: NSManagedObject> {
  init(entityName: String, withContext context: NSManagedObjectContext){
    self.entityName = entityName
    self.context = context
  }
  
  private func newFetchRequest()->NSFetchRequest{
    return NSFetchRequest(entityName: entityName)
  }
  
  private func dataFromEntities(entities: [U])->[T]{
    var answer = [T]()
    for item in entities{
      answer.append(T(entity: item))
    }
    return answer
  }
  
  private let entityName: String
  private var context: NSManagedObjectContext?
  private func predicateByType(type: RepositoryFilterType, value: FilterValues)->NSPredicate {
    var p: NSPredicate?
    switch(type){
    case .byDate:
      p = NSPredicate(format: "dateDue = %@", value.date)
      break
    case .byID:
      p = NSPredicate(format: "id = %@", value.id!)
      break
    case .byPeriod:
      p = NSPredicate(format: "forPeriod = %i", value.period)
      break
    case .byDateAndPeriod:
      let p1 = NSPredicate(format: "dateDue = %@", value.date)
      let p2 = NSPredicate(format: "forPeriod = %i", value.period)
      p = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [p1!, p2!])
      break
    case .byDateAndPeriodAndID:
      let p1 = NSPredicate(format: "dateDue = %@", value.date)
      let p2 = NSPredicate(format: "forPeriod = %i", value.period)
      let p3 = NSPredicate(format: "id = %@", value.id!)
      p = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [p1!, p2!, p3!])
      break
    case .byDateBetween:
      p = NSPredicate(format: "date > %@ and date < %@", argumentArray: [value.date, value.stopDate!])
    case .byTitleIsEmpty:
      p = NSPredicate(format: "shortTitle = %@", String())
    }
    return p!
  }
  private func fetchAll()->[T]{
    let fetchRequest = newFetchRequest()
    fetchRequest.predicate = NSPredicate(value: true)
    let results = context!.executeFetchRequest(fetchRequest, error: nil) as [U]
    let data = dataFromEntities(results)
    return data
  }
  
  private func save(){
    var error: NSError?
    context!.save(&error)
    if error != nil {
      NSLog("%@", error!)
    }
  }

  ///fetches all stored items matching the values given when filtered by type
  ///
  ///:param: type RepositoryFilterType value on which to filter.
  ///:param: values Set of values to match against. Only the one matching the filter type will be used.
  ///:returns: list of values matching filter criteria
  func fetchBy(type: RepositoryFilterType, values: FilterValues)->[T]{
      let fetchRequest = newFetchRequest()
      fetchRequest.predicate = predicateByType(type, value: values)
      if let results = context!.executeFetchRequest(fetchRequest, error: nil) as? [U]{
        let data = dataFromEntities(results)
        return data
      }
    return [T]()
  }
  
  func deleteItemMatching(values filter: protocol<Filterable, DataObject>){
    var toDelete: NSManagedObject?
    if filter.id != nil {
      toDelete = context!.existingObjectWithID(filter.id!, error: nil)
    } else {
      NSLog("%@", "Cannot delete object with nil id")
    }
    if toDelete != nil {
      context!.deleteObject(toDelete!)
    }
    save()
  }
  
  func add(item: T){
    let entity = item.toEntity(inContext: context!)
    save()
  }
}