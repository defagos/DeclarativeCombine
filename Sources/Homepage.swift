//
//  Copyright (c) Samuel Défago. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: View

struct Homepage: View {
    @StateObject var model = HomepageViewModel()
    
    var body: some View {
        switch model.state {
        case .loading:
            ProgressView()
        case let .loaded(rows: rows):
            List(rows) { row in
                TopicRow(row: row) { item, row in
                    if case let .media(media) = item {
                        model.loadMore(for: media, in: row)
                    }
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            }
            .listStyle(.plain)
            .listSectionSeparator(.hidden)
            .refreshable {
                model.reload()
            }
        case let .failure(error: error):
            Text(error.localizedDescription)
        }
    }
}

// MARK: Content views

private struct ItemCell: View {
    let item: HomepageViewModel.Item
    
    var body: some View {
        Group {
            switch item {
            case let .media(media):
                Text(media.title)
                    .padding()
            case .mediaPlaceholder:
                Color.clear
            }
        }
        .frame(width: 320, height: 180)
        .background(Color.gray)
    }
}

private struct TopicRow: View {
    let row: HomepageViewModel.Row
    let loadMore: (HomepageViewModel.Item, HomepageViewModel.Row) -> Void
    
    var body: some View {
        VStack {
            Text(row.topic.title)
                .padding()
            ScrollView(.horizontal) {
                LazyHStack {
                    ForEach(row.items, id: \.self) { item in
                        ItemCell(item: item)
                            .onAppear {
                                loadMore(item, row)
                            }
                    }
                }
            }
        }
    }
}

// MARK: Preview

struct Homepage_Previews: PreviewProvider {
    static var previews: some View {
        Homepage()
    }
}
