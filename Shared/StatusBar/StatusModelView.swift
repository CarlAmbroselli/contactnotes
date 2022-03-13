//
//  StatusModelVIew.swift
//  Crew (iOS)
//
//  Created by dev on 13.03.22.
//

import SwiftUI

struct StatusModelView: View {
    @ObservedObject var model = StatusModel.shared
    
    var body: some View {
        if (model.level != StatusLevel.NONE && !model.status.isEmpty) {
            Text(model.status)
                .font(.footnote)
                .padding(.bottom, 5)
                .frame(maxWidth: .infinity)
                .background(model.statusColor().opacity(0.3))
        }
    }
}

struct StatusModelVIew_Previews: PreviewProvider {
    static var previews: some View {
        StatusModelView()
    }
}
