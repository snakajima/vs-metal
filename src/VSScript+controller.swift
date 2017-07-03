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
        return append(node: ["name":"fork"])
    }

    func swap() -> VSScript {
        return append(node: ["name":"swap"])
    }

    func discard() -> VSScript {
        return append(node: ["name":"discard"])
    }

    func shift() -> VSScript {
        return append(node: ["name":"shift"])
    }

    func previous() -> VSScript {
        return append(node: ["name":"previous"])
    }
}
