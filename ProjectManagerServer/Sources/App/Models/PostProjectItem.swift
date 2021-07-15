//
//  PostProjectItem.swift
//  
//
//  Created by Ryan-Son on 2021/07/08.
//

import Vapor

struct PostProjectItem: Content {
    let id: UUID?
    let title: String
    let content: String
    let deadlineDate: Date
    let progress: ProjectItem.Progress
    let index: Int
}

extension PostProjectItem: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("title", as: String.self, required: true)
        validations.add("content", as: String.self, is: .count(...1000), required: true)
        validations.add("progress", as: String.self, is: .in("todo", "doing", "done"), required: true)
        validations.add("index", as: Int.self, required: true)
        validations.add("deadlineDate", as: Date.self, required: true)
    }
}

struct NestedPostProjectItem: Content {
    let postProjectItems: [PostProjectItem]
    
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        self.postProjectItems = try container.decode([PostProjectItem].self)
    }
}

extension NestedPostProjectItem: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("postProjectItems") { item in
            item.add("title", as: String.self, required: true)
            item.add("content", as: String.self, is: .count(...1000), required: true)
            item.add("progress", as: String.self, is: .in("todo", "doing", "done"), required: true)
            item.add("index", as: Int.self, required: true)
            item.add("deadlineDate", as: Date.self, required: true)
        }
    }
}
