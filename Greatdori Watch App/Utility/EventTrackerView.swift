//===---*- Greatdori! -*---------------------------------------------------===//
//
// EventTrackerView.swift
//
// This source file is part of the Greatdori! open source project
//
// Copyright (c) 2025 the Greatdori! project authors
// Licensed under Apache License v2.0
//
// See https://greatdori.memz.top/LICENSE.txt for license information
// See https://greatdori.memz.top/CONTRIBUTORS.txt for the list of Greatdori! project authors
//
//===----------------------------------------------------------------------===//

import Charts
import SwiftUI
import DoriKit
import SDWebImageSwiftUI

struct EventTrackerView: View {
    @State private var eventList: [PreviewEvent]?
    @State private var eventListAvailability = true
    @State private var selectedEvent: PreviewEvent?
    @State private var tier = 1000
    @State private var trackerData: TrackerData?
    @State private var trackerAvailability = true
    var body: some View {
        Form {
            if let eventList {
                Section {
                    Picker("活动", selection: $selectedEvent) {
                        ForEach(eventList) { event in
                            Text(event.eventName.forPreferredLocale() ?? "").tag(event)
                        }
                    }
                    .onChange(of: selectedEvent) {
                        Task {
                            await updateTrackerData()
                        }
                        UserDefaults.standard.set(selectedEvent?.id, forKey: "EventTrackerSelectedEventID")
                    }
                    if let selectedEvent {
                        NavigationLink(destination: { EventDetailView(id: selectedEvent.id) }) {
                            EventCardView(selectedEvent, inLocale: nil)
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                    }
                    Picker("排名", selection: $tier) {
                        ForEach([10, 20, 30, 40, 50, 100, 200, 300, 400, 500, 1000, 2000, 3000, 4000, 5000, 10000, 20000, 30000], id: \.self) { t in
                            Text(verbatim: "T\(t)").tag(t)
                        }
                    }
                    .onChange(of: tier) {
                        Task {
                            await updateTrackerData()
                        }
                    }
                }
                if let selectedEvent, let trackerData {
                    switch trackerData {
                    case .tracker(let trackerData):
                        Section {
                            Group {
                                if let startDate = selectedEvent.startAt.forPreferredLocale(),
                                   let endDate = selectedEvent.endAt.forPreferredLocale() {
                                    VStack(alignment: .leading) {
                                        Text("状态")
                                            .font(.system(size: 16, weight: .medium))
                                        Group {
                                            if startDate > .now {
                                                Text("未开始")
                                            } else if endDate > .now {
                                                Text("\(Int((Date.now.timeIntervalSince1970 - startDate.timeIntervalSince1970) / (endDate.timeIntervalSince1970 - startDate.timeIntervalSince1970) * 100))% 完成率")
                                                Text("\(Text(endDate, style: .relative))后结束")
                                            } else {
                                                Text("已完结")
                                            }
                                        }
                                        .font(.system(size: 14))
                                        .opacity(0.6)
                                    }
                                }
                                if let latestCutoff = trackerData.cutoffs.last?.ep {
                                    VStack(alignment: .leading) {
                                        Text("最新分数线")
                                            .font(.system(size: 16, weight: .medium))
                                        Text(String(latestCutoff))
                                            .font(.system(size: 14))
                                            .opacity(0.6)
                                    }
                                }
                                if let latestPrediction = trackerData.predictions.last?.ep {
                                    VStack(alignment: .leading) {
                                        Text("最新预测")
                                            .font(.system(size: 16, weight: .medium))
                                        Text(String(latestPrediction))
                                            .font(.system(size: 14))
                                            .opacity(0.6)
                                    }
                                }
                                if let latestUpdateTime = trackerData.cutoffs.last?.time {
                                    VStack(alignment: .leading) {
                                        Text("更新时间")
                                            .font(.system(size: 16, weight: .medium))
                                        Text("\(Text(latestUpdateTime, style: .relative))前")
                                            .font(.system(size: 14))
                                            .opacity(0.6)
                                    }
                                }
                            }
                            .listRowBackground(Color.clear)
                            VStack(alignment: .leading) {
                                Chart {
                                    ForEach(trackerData.cutoffs, id: \.time) { cutoff in
                                        if let ep = cutoff.ep {
                                            AreaMark(
                                                x: .value("Date", cutoff.time),
                                                y: .value("Ep", ep)
                                            )
                                            .foregroundStyle(.blue.opacity(0.7))
                                            LineMark(
                                                x: .value("Date", cutoff.time),
                                                y: .value("Ep", ep)
                                            )
                                            .foregroundStyle(by: .value("Type", String(localized: "目前分数线")))
                                        }
                                    }
                                    ForEach(trackerData.predictions, id: \.time) { prediction in
                                        if let ep = prediction.ep {
                                            LineMark(
                                                x: .value("Date", prediction.time),
                                                y: .value("Ep", ep)
                                            )
                                            .lineStyle(.init(lineWidth: 2, dash: [5, 3]))
                                            .foregroundStyle(by: .value("Type", String(localized: "预测最终分数线")))
                                        }
                                    }
                                }
                                .chartForegroundStyleScale([
                                    String(localized: "目前分数线"): .blue,
                                    String(localized: "预测最终分数线"): .blue
                                ])
                                .chartLegend(.hidden)
                                .chartScrollableAxes(.horizontal)
                                .chartXVisibleDomain(length: 60 * 60 * 24 * 3)
                                .chartXAxis {
                                    AxisMarks(values: .stride(by: .day)) { value in
                                        AxisGridLine()
                                        AxisTick()
                                        AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                                    }
                                }
                                .chartYAxis {
                                    AxisMarks(position: .leading, values: .stride(by: stride(of: trackerData))) { value in
                                        AxisGridLine()
                                        AxisTick()
                                        AxisValueLabel {
                                            if let number = value.as(Double.self) {
                                                Text(formatNumber(number))
                                            }
                                        }
                                    }
                                }
                                .frame(height: 150)
                                HStack {
                                    Rectangle()
                                        .fill(Color.blue.opacity(0.7))
                                        .strokeBorder(Color.blue, lineWidth: 2)
                                        .frame(width: 20, height: 10)
                                    Text("目前分数线")
                                        .font(.system(size: 8))
                                    Rectangle()
                                        .stroke(style: .init(lineWidth: 2, dash: [5, 3]))
                                        .fill(Color.blue)
                                        .frame(width: 20, height: 10)
                                    Text("预测最终分数线")
                                        .font(.system(size: 8))
                                }
                            }
                        }
                    case .top(let topData):
                        Section {
                            Group {
                                if let startDate = selectedEvent.startAt.forPreferredLocale(),
                                   let endDate = selectedEvent.endAt.forPreferredLocale() {
                                    VStack(alignment: .leading) {
                                        Text("状态")
                                            .font(.system(size: 16, weight: .medium))
                                        Group {
                                            if startDate > .now {
                                                Text("未开始")
                                            } else if endDate > .now {
                                                Text("\(Int((Date.now.timeIntervalSince1970 - startDate.timeIntervalSince1970) / (endDate.timeIntervalSince1970 - startDate.timeIntervalSince1970) * 100))% 完成率")
                                                Text("\(Text(endDate, style: .relative))后结束")
                                            } else {
                                                Text("已完结")
                                            }
                                        }
                                        .font(.system(size: 14))
                                        .opacity(0.6)
                                    }
                                }
                                if let latestUpdateTime = topData.last?.points.last?.time {
                                    VStack(alignment: .leading) {
                                        Text("更新时间")
                                            .font(.system(size: 16, weight: .medium))
                                        Text("\(Text(latestUpdateTime, style: .relative))前")
                                            .font(.system(size: 14))
                                            .opacity(0.6)
                                    }
                                }
                            }
                            .listRowBackground(Color.clear)
                            Chart {
                                ForEach(topData, id: \.uid) { data in
                                    ForEach(data.points, id: \.time) { point in
                                        LineMark(
                                            x: .value("Date", point.time),
                                            y: .value("Point", point.value)
                                        )
                                        .foregroundStyle(by: .value("Name", data.name))
                                    }
                                }
                            }
                            .chartScrollableAxes(.horizontal)
                            .chartXVisibleDomain(length: 60 * 60 * 24 * 3)
                            .chartXAxis {
                                AxisMarks(values: .stride(by: .day)) { value in
                                    AxisGridLine()
                                    AxisTick()
                                    AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                                }
                            }
                            .chartYAxis {
                                AxisMarks(position: .leading, values: .stride(by: stride(of: topData))) { value in
                                    AxisGridLine()
                                    AxisTick()
                                    AxisValueLabel {
                                        if let number = value.as(Double.self) {
                                            Text(formatNumber(number))
                                        }
                                    }
                                }
                            }
                            .frame(height: 1000)
                        }
                        Section {
                            ForEach(Array(topData.prefix(10).enumerated()), id: \.element.uid) { index, data in
                                VStack(alignment: .leading) {
                                    if 1...3 ~= index + 1 {
                                        Image("tier_\(DoriAPI.preferredLocale.rawValue)_\(index + 1)")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 20)
                                    } else {
                                        Text(verbatim: "#\(index + 1)")
                                            .font(.headline)
                                    }
                                    HStack {
                                        CardIconView(data.card)
                                        VStack(alignment: .leading) {
                                            Text(data.name)
                                                .font(.system(size: 14))
                                            Text(data.introduction)
                                                .font(.system(size: 11))
                                                .opacity(0.6)
                                        }
                                    }
                                    if let score = data.points.last?.value {
                                        Text("\(score) 分")
                                    }
                                }
                            }
                        }
                    }
                } else {
                    if trackerAvailability {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else {
                        HStack {
                            Spacer()
                            Text("不可用")
                            Spacer()
                        }
                    }
                }
            } else {
                if eventListAvailability {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else {
                    UnavailableView("载入活动时出错", systemImage: "star.hexagon.fill", retryHandler: getEvents)
                }
            }
        }
        .navigationTitle("活动Pt&排名追踪器")
        .task {
            await getEvents()
        }
    }
    
    func getEvents() async {
        eventListAvailability = true
        withDoriCache(id: "EventList") {
            await PreviewEvent.all()
        }.onUpdate {
            if let events = $0 {
                self.eventList = events.reversed()
                let storedEventID = UserDefaults.standard.integer(forKey: "EventTrackerSelectedEventID")
                if storedEventID > 0, let event = events.first(where: { $0.id == storedEventID }) {
                    self.selectedEvent = event
                } else {
                    self.selectedEvent = events.last
                }
                Task {
                    await updateTrackerData()
                }
            } else {
                eventListAvailability = false
            }
        }
    }
    func updateTrackerData() async {
        if let event = selectedEvent {
            trackerData = nil
            trackerAvailability = true
            if tier > 10 {
                if let trackerData = await DoriFrontend.Events.trackerData(for: event, in: DoriAPI.preferredLocale, tier: tier, smooth: true) {
                    self.trackerData = .tracker(trackerData)
                } else {
                    trackerAvailability = false
                }
            } else {
                if let topData = await DoriFrontend.Events.topData(of: event.id, in: DoriAPI.preferredLocale) {
                    self.trackerData = .top(topData)
                } else {
                    trackerAvailability = false
                }
            }
        }
    }
    
    func stride(of trackerData: DoriFrontend.Events.TrackerData) -> Double {
        let cutoffs = trackerData.cutoffs
        let predictions = trackerData.predictions
        var maxValue = 0.0
        for cutoff in cutoffs where Double(cutoff.ep ?? 0) > maxValue {
            maxValue = Double(cutoff.ep ?? 0)
        }
        for prediction in predictions where Double(prediction.ep ?? 0) > maxValue {
            maxValue = Double(prediction.ep ?? 0)
        }
        let count = String(Int(maxValue)).count
        let result = "1" + String(repeating: "0", count: count - 1)
        return Double(result)!
    }
    func stride(of topData: [DoriFrontend.Events.TopData]) -> Double {
        var maxValue = 0.0
        for data in topData {
            for point in data.points where Double(point.value) > maxValue {
                maxValue = Double(point.value)
            }
        }
        let count = String(Int(maxValue)).count
        let result = "1" + String(repeating: "0", count: count - 1)
        return Double(result)!
    }
}

private func formatNumber(_ number: Double) -> String {
    switch number {
    case 1_000_000_000...:
        return unsafe String(format: "%.0fB", number / 1_000_000_000)
    case 1_000_000...:
        return unsafe String(format: "%.0fM", number / 1_000_000)
    case 1_000...:
        return unsafe String(format: "%.0fK", number / 1_000)
    default:
        return unsafe String(format: "%.0f", number)
    }
}

private enum TrackerData {
    case tracker(DoriFrontend.Events.TrackerData)
    case top([DoriFrontend.Events.TopData])
}
