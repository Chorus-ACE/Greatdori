//===---*- Greatdori! -*---------------------------------------------------===//
//
// UIBasic.metal
//
// This source file is part of the Greatdori! open source project
//
// Copyright (c) 2025 the Greatdori! project authors
// Licensed under Apache License v2.0
//
// See https://greatdori.com/LICENSE.txt for license information
// See https://greatdori.com/CONTRIBUTORS.txt for the list of Greatdori! project authors
//
//===----------------------------------------------------------------------===//

#include <metal_stdlib>
using namespace metal;

[[ stitchable ]]
half4 upscaledImageFix(float2 position, half4 color, texture2d<half> sourceTex, float4 rect) {
    auto s = sampler();
    float2 normalizedPos = position / rect.zw;
    half4 src = sourceTex.sample(s, normalizedPos);
    half4 result = color;
    result.a = src.a;
    return result;
}
