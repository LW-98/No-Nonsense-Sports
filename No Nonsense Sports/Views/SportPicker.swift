//
//  SportPicker.swift
//  No Nonsense Sports
//

import SwiftUI

struct SportPicker: View {
    @Binding var selection: Sport

    var body: some View {
        Menu {
            Picker("Sport", selection: $selection) {
                ForEach(Sport.all) { sport in
                    Label(sport.displayName, systemImage: sport.symbolName).tag(sport)
                }
            }
        } label: {
            Label(selection.displayName, systemImage: selection.symbolName)
        }
    }
}
