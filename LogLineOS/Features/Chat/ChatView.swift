import SwiftUI

struct ChatView: View {
    @ObservedObject var vm: ChatViewModel
    
    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(vm.messages) { msg in
                            HStack {
                                if msg.role == .bot { Spacer(minLength: 0) }
                                Text(msg.text)
                                    .padding(12)
                                    .background(msg.role == .user ? Color.blue.opacity(0.15) : Color.gray.opacity(0.15))
                                    .cornerRadius(12)
                                if msg.role == .user { Spacer(minLength: 0) }
                            }
                        }
                    }.padding()
                }
                .onChange(of: vm.messages.count) { _ in
                    withAnimation { proxy.scrollTo(vm.messages.last?.id, anchor: .bottom) }
                }
            }
            HStack {
                TextField("Diga o que aconteceu…", text: $vm.input)
                    .textFieldStyle(.roundedBorder)
                Button("Enviar") { vm.send() }.buttonStyle(.borderedProminent)
            }.padding()
        }
        .navigationTitle("LogLineOS")
    }
}
