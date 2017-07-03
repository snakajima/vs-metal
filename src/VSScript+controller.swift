//
//  VSScript+filter.swift
//  vs-metal
//
//  Created by satoshi on 7/2/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//

import Foundation

extension VSScript {
    func fork() -> VSScript {
        append(node: ["name":"fork"])
        return self
    }

    func swap() -> VSScript {
        append(node: ["name":"swap"])
        return self
    }

    func discard() -> VSScript {
        append(node: ["name":"discard"])
        return self
    }

    func shift() -> VSScript {
        append(node: ["name":"shift"])
        return self
    }

    func previous() -> VSScript {
        append(node: ["name":"previous"])
        return self
    }
}
