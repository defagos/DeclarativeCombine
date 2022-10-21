//
//  Copyright (c) Samuel Défago. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine

public extension Publishers {
    /**
     *  Make the upstream publisher publish each time a second signal publisher emits some value.
     */
    static func Publish<S, P>(onOutputFrom signal: S, _ publisher: @escaping () -> P) -> AnyPublisher<P.Output, P.Failure> where S: Publisher, P: Publisher, S.Failure == Never {
        return signal
            .map { _ in }
            .setFailureType(to: P.Failure.self)          // Required for iOS 13, can be removed for iOS 14+
            .map { _ in
                return publisher()
            }
            .switchToLatest()
            .eraseToAnyPublisher()
    }
    
    /**
     *  Make the upstream publisher execute once and repeat each time a second signal publisher emits some value.
     */
    static func PublishAndRepeat<S, P>(onOutputFrom signal: S, _ publisher: @escaping () -> P) -> AnyPublisher<P.Output, P.Failure> where S: Publisher, P: Publisher, S.Failure == Never {
        return signal
            .map { _ in }
            .prepend(())
            .setFailureType(to: P.Failure.self)          // Required for iOS 13, can be removed for iOS 14+
            .map { _ in
                return publisher()
            }
            .switchToLatest()
            .eraseToAnyPublisher()
    }
    
    /**
     *  Accumulate the latest values emitted by several publishers into an array. All the publishers must emit a
     *  value before `AccumulateLatestMany` emits a value, as for `CombineLatest`.
     */
    static func AccumulateLatestMany<Upstream>(_ publishers: Upstream...) -> AnyPublisher<[Upstream.Output], Upstream.Failure> where Upstream: Publisher {
        return AccumulateLatestMany(publishers)
    }
    
    /**
     *  Accumulate the latest values emitted by a sequence of publishers into an array. All the publishers must
     *  emit a value before `AccumulateLatestMany` emits a value, as for `CombineLatest`.
     */
    static func AccumulateLatestMany<Upstream, S>(_ publishers: S) -> AnyPublisher<[Upstream.Output], Upstream.Failure> where Upstream: Publisher, S: Swift.Sequence, S.Element == Upstream {
        let publishersArray = Array(publishers)
        switch publishersArray.count {
        case 0:
            return Just([])
                .setFailureType(to: Upstream.Failure.self)
                .eraseToAnyPublisher()
        case 1:
            return publishersArray[0]
                .map { [$0] }
                .eraseToAnyPublisher()
        case 2:
            return Publishers.CombineLatest(publishersArray[0], publishersArray[1])
                .map { t1, t2 in
                    return [t1, t2]
                }
                .eraseToAnyPublisher()
        case 3:
            return Publishers.CombineLatest3(publishersArray[0], publishersArray[1], publishersArray[2])
                .map { t1, t2, t3 in
                    return [t1, t2, t3]
                }
                .eraseToAnyPublisher()
        default:
            let half = publishersArray.count / 2
            return Publishers.CombineLatest(
                AccumulateLatestMany(Array(publishersArray[0..<half])),
                AccumulateLatestMany(Array(publishersArray[half..<publishersArray.count]))
            )
            .map { array1, array2 in
                return array1 + array2
            }
            .eraseToAnyPublisher()
        }
    }
}
