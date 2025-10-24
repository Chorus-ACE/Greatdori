//===---*- Greatdori! -*---------------------------------------------------===//
//
// StyleEditorView.swift
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

import SwiftUI
@_private(sourceFile: "FrontendSong.swift") import DoriKit

struct StyleEditorView: View {
    var update: (Lyrics.Style) -> Void
    @State var style: Lyrics.Style
    @State var previewText = ""
    
    init(style: Lyrics.Style, update: @escaping (Lyrics.Style) -> Void) {
        self.update = update
        self._style = .init(initialValue: style)
    }
    
    var body: some View {
        HSplitView {
            Form {
                Section {
                    ColorPicker("Color", selection: .init {
                        style.color ?? .primary
                    } set: {
                        style.color = $0
                    })
                    Picker("Font", selection: $style.fontOverride) {
                        Text("Default").tag(Optional<String>.none)
                        ForEach(NSFontManager.shared.availableFontFamilies, id: \.self) { name in
                            Text(name)
                                .font(.custom(name, size: 14))
                                .tag(name)
                        }
                    }
                }
                Section {
                    Picker("Stroke", selection: .init {
                        style.stroke != nil
                    } set: {
                        if $0 && style.stroke == nil {
                            style.stroke = .init(color: .cyan, width: 1, radius: 0)
                        } else if !$0 && style.stroke != nil {
                            style.stroke = nil
                        }
                    }) {
                        Text("Disabled").tag(false)
                        Text("Enabled").tag(true)
                    }
                    if let stroke = style.stroke {
                        ColorPicker("Color", selection: .init {
                            stroke.color
                        } set: {
                            style.stroke?.color = $0
                        })
                        HStack {
                            Text("Width")
                            Spacer()
                            Text(unsafe String(format: "%.1f", stroke.width))
                            Stepper(value: .init {
                                stroke.width
                            } set: {
                                style.stroke?.width = $0
                            }, in: 0...50, step: 0.1) {}
                                
                        }
                        HStack {
                            Text("Radius")
                            Spacer()
                            Text(unsafe String(format: "%.1f", stroke.radius))
                            Stepper(value: .init {
                                stroke.radius
                            } set: {
                                style.stroke?.radius = $0
                            }, in: 0...50, step: 0.5) {}
                        }
                    }
                } header: {
                    Text("Stroke")
                }
                Section {
                    Picker("Shadow", selection: .init {
                        style.shadow != nil
                    } set: {
                        if $0 && style.shadow == nil {
                            style.shadow = .init(color: .gray, x: 1, y: 1, blur: 0)
                        } else if !$0 && style.shadow != nil {
                            style.shadow = nil
                        }
                    }) {
                        Text("Disabled").tag(false)
                        Text("Enabled").tag(true)
                    }
                    if let shadow = style.shadow {
                        ColorPicker("Color", selection: .init {
                            shadow.color
                        } set: {
                            style.shadow?.color = $0
                        })
                        HStack {
                            Text("X")
                            Spacer()
                            Text(unsafe String(format: "%.1f", shadow.x))
                            Stepper(value: .init {
                                shadow.x
                            } set: {
                                style.shadow?.x = $0
                            }, step: 0.1) {}
                        }
                        HStack {
                            Text("Y")
                            Spacer()
                            Text(unsafe String(format: "%.1f", shadow.y))
                            Stepper(value: .init {
                                shadow.y
                            } set: {
                                style.shadow?.y = $0
                            }, step: 0.1) {}
                        }
                        HStack {
                            Text("Blur")
                            Spacer()
                            Text(unsafe String(format: "%.1f", shadow.blur))
                            Stepper(value: .init {
                                shadow.blur
                            } set: {
                                style.shadow?.blur = $0
                            }, in: 0...50, step: 0.5) {}
                        }
                    }
                } header: {
                    Text("Shadow")
                }
                Section {
                    ForEach(Array(style.maskLines.enumerated()), id: \.element.self) { (index, maskLine) in
                        VStack {
                            ColorPicker("Color", selection: .init {
                                maskLine.color
                            } set: {
                                style.maskLines[index].color = $0
                            })
                            HStack {
                                Text("Width")
                                Spacer()
                                Text(unsafe String(format: "%.1f", maskLine.width))
                                Stepper(value: .init {
                                    maskLine.width
                                } set: {
                                    style.maskLines[index].width = $0
                                }, in: 0...50, step: 0.1) {}
                            }
                            HStack {
                                LabeledSlider(text: "Start X", value: $style.maskLines[index].start.x)
                                Spacer(minLength: 0)
                                LabeledSlider(text: "Start Y", value: $style.maskLines[index].start.y)
                            }
                            HStack {
                                LabeledSlider(text: "End X", value: $style.maskLines[index].end.x)
                                Spacer(minLength: 0)
                                LabeledSlider(text: "End Y", value: $style.maskLines[index].end.y)
                            }
                            HStack {
                                Spacer()
                                Button("Remove", role: .destructive) {
                                    style.maskLines.remove(at: index)
                                }
                                .tint(.red)
                            }
                        }
                    }
                    HStack {
                        Button {
                            style.maskLines.append(.init(color: .orange, width: 1, start: .init(x: 0, y: 0), end: .init(x: 1, y: 1)))
                        } label: {
                            Image(systemName: "plus")
                                .foregroundStyle(Color.primary)
                        }
                    }
                    .buttonStyle(.borderless)
                    .listRowInsets(.init())
                } header: {
                    Text("Mask Line")
                }
            }
            .formStyle(.grouped)
            .frame(minWidth: 200)
            HStack {
                Spacer()
                VStack {
                    TextField("Type to preview...", text: $previewText)
                    Spacer()
                    TextStyleRender(text: previewText.isEmpty ? "迷い星のうた" : previewText, style: style)
                        .font(.system(size: 30))
                    Spacer()
                }
                Spacer()
            }
        }
        .navigationSubtitle("Style Editor")
        .onDisappear {
            update(style)
        }
    }
}

private struct LabeledSlider: View {
    var text: LocalizedStringKey
    @Binding var value: CGFloat
    @State var sliderValue: CGFloat
    
    init(text: LocalizedStringKey, value: Binding<CGFloat>) {
        self.text = text
        self._value = value
        self._sliderValue = .init(initialValue: value.wrappedValue)
    }
    
    var body: some View {
        HStack {
            Text(text)
            Slider(value: $sliderValue, in: 0.0...1.0) {
                if !$0 {
                    value = sliderValue
                }
            }
        }
    }
}
