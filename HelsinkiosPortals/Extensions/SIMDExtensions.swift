//
//  SIMDExtensions.swift
//  HelsinkiosPortals
//
//  Created by Matti Dahlbom on 15.3.2024.
//

import ARKit

extension SIMD4 {
    var xyz: SIMD3<Scalar> {
        self[SIMD3(0, 1, 2)]
    }
}

extension simd_float4x4 {
    var position: SIMD3<Float> {
        return self.columns.3.xyz
    }
    
    var up: SIMD3<Float> {
        return self.columns.1.xyz
    }
}
