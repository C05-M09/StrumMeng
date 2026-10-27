//
//  RecordsView.swift
//  StrumMeng
//
//  Created by rasyel on 26/10/26.
//

import SwiftUI
 
/// `.task` runs every time the pattern list appears (including when coming back
/// from Summary) and is cancelled automatically when the view disappears.
struct RecordsView: View {
    let viewModel: RecordsViewModel
 
    var body: some View {
        RecordsContentView(state: viewModel.state)
            .task { await viewModel.load() }
    }
}
 
