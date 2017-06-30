//
//  VSNode.swift
//  vs-metal
//
//  Created by SATOSHI NAKAJIMA on 6/22/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//

import Foundation
import MetalPerformanceShaders

protocol VSNode {
    func encode(commandBuffer:MTLCommandBuffer, destination:VSTexture, context:VSContext) throws
}

class VSNodes {
    private static let nodes:[String:[String:Any]] = {
        let url = Bundle.main.url(forResource: "VSNodes", withExtension: "js")!
        let data = try! Data(contentsOf: url)
        let json = try! JSONSerialization.jsonObject(with: data)
        return json as! [String:[String:Any]]
    }()
    
    static func getNodeInfo(name:String) -> [String:Any]? {
        return VSNodes.nodes[name]
    }
}

