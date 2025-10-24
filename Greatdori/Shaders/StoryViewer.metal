//===---*- Greatdori! -*---------------------------------------------------===//
//
// StoryViewer.metal
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
half4 continuableMark(float2 position, half4 color, float2 size) {
    if (color.a == 0) // iOS fix
        return half4(0);
    float2 normalizedPosition = position / size;
    float2 reversedPos = 1 - normalizedPosition;
    return half4(color.r + reversedPos.y / 2.5,
                 color.g + reversedPos.y / 2.5,
                 color.b + reversedPos.y / 2.5,
                 color.a);
}
