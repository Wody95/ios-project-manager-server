//
//  ProjectItemController.swift
//  
//
//  Created by Wody, Kane, Ryan-Son on 2021/07/02.
//

import Fluent
import Vapor

struct ProjectItemController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let projectItems = routes.grouped("projectItems")
        projectItems.group(":progress") { projectItem in
            projectItem.get(use: read)
        }
        let projectItem = routes.grouped("projectItem")
        projectItem.post(use: create)
        projectItem.patch(use: update)
        projectItem.delete(use: delete)
    }
    
    func read(req: Request) throws -> EventLoopFuture<[ProjectItem]> {
        guard let pathParameter = req.parameters.get("progress"),
              let progress = ProjectItem.Progress(rawValue: pathParameter) else {
            throw HTTPError.invalidProgressInURL
        }
        
        return ProjectItem.query(on: req.db).filter(\.$progress ==  progress).all()
    }
    
    func create(req: Request) throws -> EventLoopFuture<[ProjectItem]> {
        guard req.headers.contentType == .json else {
            throw HTTPError.invalidContentType
        }
        
//        do {
//            try NestedPostProjectItem.validate(content: req)
//        } catch {
//            throw HTTPError.validationFailedWhileCreating
//        }
        
        let exist = try req.content.decode([PostProjectItem].self)
        
        
        let newProjectItems: [ProjectItem] = exist.map { ProjectItem($0) }
        
        return newProjectItems.map { $0.create(on: req.db) }.flatten(on: req.eventLoop).map { (result) -> [ProjectItem] in
            return newProjectItems
        }
    }
    
    func update(req: Request) throws -> EventLoopFuture<[ProjectItem]> {
        guard req.headers.contentType == .json else {
            throw HTTPError.invalidContentType
        }
        
//        do {
//            try PatchProjectItem.validate(content: req)
//        } catch {
//            throw HTTPError.validationFailedWhileUpdating
//        }
        
        let exist = try req.content.decode([PatchProjectItem].self)
        
        return exist.map { updated -> EventLoopFuture<ProjectItem> in
            ProjectItem.find(updated.id, on: req.db)
            .unwrap(or: HTTPError.invalidID)
            .flatMap { item -> EventLoopFuture<ProjectItem> in
                if let title = updated.title { item.title = title }
                if let content = updated.content { item.content = content }
                if let progress = updated.progress { item.progress = progress }
                if let deadlineDate = updated.deadlineDate { item.deadlineDate = deadlineDate }
                if let index = updated.index { item.index = index }
                
                return item.update(on: req.db).map { item }
            }
        }.flatten(on: req.eventLoop)
    }
    
    func delete(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        guard req.headers.contentType == .json else {
            throw HTTPError.invalidContentType
        }
        
        let exist = try req.content.decode([DeleteProjectItem].self)
        
        return exist.map {
            ProjectItem.find($0.id, on: req.db)
                .unwrap(or: HTTPError.invalidID)
                .flatMap { $0.delete(on: req.db) }
        }.flatten(on: req.eventLoop)
        .transform(to: .ok)
    }
}
