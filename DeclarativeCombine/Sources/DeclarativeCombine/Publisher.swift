//
//  Copyright (c) Samuel Défago. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import Combine

public extension Publisher {
    /**
     *  Make the upstream publisher wait until a second signal publisher emits some value.
     */
    func wait<S>(untilOutputFrom signal: S) -> AnyPublisher<Self.Output, Self.Failure> where S: Publisher, S.Failure == Never {
        return prepend(
            Empty(completeImmediately: false)
                .prefix(untilOutputFrom: signal)
        )
        .eraseToAnyPublisher()
    }
}
