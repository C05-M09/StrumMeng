//
//  RecordsViewState.swift
//  StrumMeng
//
//  Created by rasyel on 26/10/26.
//

enum RecordsViewState: Equatable, Sendable {
    case loading
    case empty
    case loaded([RecordRowModel])
    case failed
}
 
