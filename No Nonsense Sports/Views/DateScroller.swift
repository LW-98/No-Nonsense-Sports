//
//  DateScroller.swift
//  No Nonsense Sports
//
//  Horizontally-scrollable strip of selectable calendar days.
//  Today is anchored in the centre; users can scroll to past or future dates.
//

import SwiftUI

struct DateScroller: View {
    @Binding var selection: Date

    /// Number of days to render either side of today.
    var pastDays: Int = 14
    var futureDays: Int = 14

    private let calendar = Calendar.current

    private var today: Date { calendar.startOfDay(for: .now) }

    private var dates: [Date] {
        (-pastDays...futureDays).compactMap {
            calendar.date(byAdding: .day, value: $0, to: today)
        }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(dates, id: \.self) { date in
                        DateChip(date: date, isSelected: isSelected(date), isToday: isToday(date))
                            .id(date)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    selection = calendar.startOfDay(for: date)
                                    proxy.scrollTo(calendar.startOfDay(for: date), anchor: .center)
                                }
                            }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .onAppear {
                proxy.scrollTo(calendar.startOfDay(for: selection), anchor: .center)
            }
            .onChange(of: selection) { _, newValue in
                withAnimation(.easeInOut(duration: 0.2)) {
                    proxy.scrollTo(calendar.startOfDay(for: newValue), anchor: .center)
                }
            }
        }
        .background(.bar)
    }

    private func isSelected(_ date: Date) -> Bool {
        calendar.isDate(date, inSameDayAs: selection)
    }

    private func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }
}

private struct DateChip: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool

    var body: some View {
        VStack(spacing: 2) {
            Text(weekday)
                .font(.caption2.weight(.semibold))
                .textCase(.uppercase)
            Text(day)
                .font(.title3.weight(.bold).monospacedDigit())
            Text(isToday ? "Today" : month)
                .font(.caption2)
        }
        .frame(width: 56, height: 64)
        .foregroundStyle(isSelected ? Color.white : .primary)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(isToday && !isSelected ? Color.accentColor : .clear, lineWidth: 1.5)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(date, style: .date))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var weekday: String { date.formatted(.dateTime.weekday(.abbreviated)) }
    private var day: String     { date.formatted(.dateTime.day()) }
    private var month: String   { date.formatted(.dateTime.month(.abbreviated)) }
}

#Preview {
    @Previewable @State var date: Date = .now
    return DateScroller(selection: $date)
}
