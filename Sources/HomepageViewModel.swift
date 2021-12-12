//
//  Copyright (c) Samuel Défago. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import DeclarativeCombine
import Foundation

// MARK: View model

final class HomepageViewModel: ObservableObject {
    @Published private(set) var state: State = .loading
    
    private let trigger = Trigger()
    
    init() {
        Publishers.PublishAndRepeat(onOutputFrom: trigger.signal(activatedBy: TriggerId.reload)) { [weak self, trigger] in
            DataSource.topics()
                .map { topics in
                    return Publishers.AccumulateLatestMany(topics.map { topic in
                        return DataSource.medias(forTopicId: topic.id, paginatedBy: trigger.signal(activatedBy: TriggerId.loadMore(topicId: topic.id)))
                            .scan([]) { $0 + $1 }
                            .map { medias in
                                return Row(topic: topic, items: medias.map { Item.media($0) })
                            }
                            .replaceError(with: Self.placeholderRow(for: topic, state: self?.state))
                            .prepend(Self.placeholderRow(for: topic, state: self?.state))
                            .eraseToAnyPublisher()
                    })
                }
                .switchToLatest()
                .map { State.loaded(rows: $0) }
                .catch { error in
                    return Just(State.failure(error: error))
                }
        }
        .receive(on: DispatchQueue.main)
        .assign(to: &$state)
    }
    
    func reload() {
        trigger.activate(for: TriggerId.reload)
    }
    
    func loadMore(for media: Media, in row: Row) {
        let medias = row.items.compactMap { item -> Media? in
            if case let .media(media) = item {
                return media
            }
            else {
                return nil
            }
        }
        if media == medias.last {
            trigger.activate(for: TriggerId.loadMore(topicId: row.topic.id))
        }
    }
    
    private static func placeholderRow(for topic: Topic, state: State?) -> Row {
        if let row = state?.rows.first(where: { $0.topic == topic }) {
            return row
        }
        else {
            let items = (1...10).map { Item.mediaPlaceholder(index: $0) }
            return Row(topic: topic, items: items)
        }
    }
}

// MARK: Types

extension HomepageViewModel {
    enum State {
        case loading
        case loaded(rows: [Row])
        case failure(error: Error)
        
        fileprivate var rows: [Row] {
            if case let .loaded(rows: rows) = self {
                return rows
            }
            else {
                return []
            }
        }
    }
    
    enum Item: Hashable {
        case media(_ media: Media)
        case mediaPlaceholder(index: Int)
    }
    
    struct Row: Identifiable {
        var id: String {
            return topic.id
        }
        
        let topic: Topic
        let items: [Item]
    }
    
    private enum TriggerId: Hashable {
        case reload
        case loadMore(topicId: String)
    }
}
