//
//  Copyright (c) Samuel Défago. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine
import DeclarativeCombine
import Foundation

// MARK: Models

/// Model for medias
struct Media: Codable, Identifiable, Hashable {
    var id: String
    var title: String
}

private struct MediaPage: Codable {
    var mediaList: [Media]
    var next: URL?
}

/// Model for topics
struct Topic: Codable, Identifiable, Hashable {
    var id: String
    var title: String
}

private struct TopicList: Codable {
    var topicList: [Topic]
}

// MARK: Public data emitters

public enum DataSource {
    public static let serviceUrl = URL(string: "https://il.srgssr.ch/integrationlayer/2.0/rts")!
    
    static func topics() -> AnyPublisher<[Topic], Error> {
        return URLSession.shared.dataTaskPublisher(for: url(forResourcePath: "topicList/tv"))
            .map { $0.data }
            .decode(type: TopicList.self, decoder: JSONDecoder())
            .map { $0.topicList }
            .eraseToAnyPublisher()
    }
    
    static func medias(forTopicId topicId: String, paginatedBy paginator: Trigger.Signal? = nil) -> AnyPublisher<[Media], Error> {
        return medias(forTopicId: topicId, at: nil, paginatedBy: paginator)
            .map { $0.mediaList }
            .eraseToAnyPublisher()
    }
    
    private static func url(forResourcePath resourcePath: String) -> URL {
        return serviceUrl.appendingPathComponent(resourcePath)
    }
}

// MARK: Pagination implementation

private extension DataSource {
    typealias Page = URL                // The service used as example returns pages as URLs directly
    
    static func medias(forTopicId topicId: String, at page: Page?) -> AnyPublisher<MediaPage, Error> {
        return URLSession.shared.dataTaskPublisher(for: page ?? url(forResourcePath: "mediaList/video/latestByTopic/\(topicId)"))
            .map { $0.data }
            .decode(type: MediaPage.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
    
    static func medias(forTopicId topicId: String, at page: Page?, paginatedBy paginator: Trigger.Signal?) -> AnyPublisher<MediaPage, Error> {
        return medias(forTopicId: topicId, at: page)
            .map { result -> AnyPublisher<MediaPage, Error> in
                if let paginator = paginator, let next = result.next {
                    return medias(forTopicId: topicId, at: next, paginatedBy: paginator)
                        .wait(untilOutputFrom: paginator)
                        .retry(.max)
                        .prepend(result)
                        .eraseToAnyPublisher()
                }
                else {
                    return Just(result)
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }
            }
            .switchToLatest()
            .eraseToAnyPublisher()
    }
}
