import SwiftUI

struct SplashScreenView: View {
    var body: some View {
        ZStack {
            Color.appbackground
                .ignoresSafeArea()
            
            VStack {

                Spacer()
                    .frame(height: 100) 
                
                VStack(spacing: -130) {
                    VStack(spacing: 5) {
                        Text("ROB𝓲")
                            .font(.system(size: 70))
                            .fontWeight(.bold)
                        Text("Rural Open Burning 𝓲nformation")
                            .bold()
                    }
                    .padding(.bottom, 5)

                    Image("appBackgroundPattern")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 900, height: 870)
                }
                
                Spacer()
            }
        }
    }
}
