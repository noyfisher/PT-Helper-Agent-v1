import Foundation
import SwiftUI

import SwiftUI

struct TimerView: View {
    @ObservedObject var viewModel: TimerViewModel

    var body: some View {
        VStack {
            Text(viewModel.timeString)
                .font(.largeTitle)
                .padding()
            HStack {
                Button(action: { viewModel.start() }) {
                    Text("Start")
                }
                Button(action: { viewModel.stop() }) {
                    Text("Stop")
                }
                Button(action: { viewModel.reset() }) {
                    Text("Reset")
                }
            }
        }
    }
}

struct TimerView_Previews: PreviewProvider {
    static var previews: some View {
        TimerView(viewModel: TimerViewModel())
    }
}