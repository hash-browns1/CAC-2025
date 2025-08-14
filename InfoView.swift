
import SwiftUI

struct InfoView: View {
    var body: some View {
        ZStack {
            Color.appbackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - General Burn Information Card
                    VStack(alignment: .leading, spacing: 10) {
                        Text("General Burn Information")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        Divider()

                        Text("Always contact your local fire department to find out if burning is authorized on a particular day.")
                        Text("Most burn lines are updated daily at 9 am.")
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(15)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)

                    // MARK: - Backyard Burning Card
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Backyard Burning")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        Divider()
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Is the burning of debris in an outdoor fireplace, burn barrel, backyard incinerator, or piles of yard debris.")
                                .padding(.bottom, 5)

                            Text("Backyard Burning Seasons:")
                                .fontWeight(.bold)
                            Text("SPRING – March 1 through June 15")
                            Text("FALL – October 1 through December 15")
                                .padding(.bottom, 5)

                            Text("Backyard Burning Safety – Burn Responsibly:")
                                .fontWeight(.bold)
                            Text("• Fires must be attended until the fire is completely burned out or extinguished")
                            Text("• Keep the space around the burn area clear (3 feet of non-combustible materials)")
                            Text("• Do not locate the fire under overhead lines, overhanging trees, near fences or structures")
                            Text("• Always have a hand tool and/or water at the burn area to control the fire")
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(15)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                    
                    // MARK: - Allowed and Prohibited Materials Card
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Allowed and Prohibited Materials")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Divider()

                        VStack(alignment: .leading, spacing: 5) {
                            Text("Allowed Materials:")
                                .fontWeight(.bold)
                            Text("You may burn dry yard debris: wood, needles, or leaves from plants grown and burned on the property of origin.")
                                .padding(.bottom, 5)

                            Text("Prohibited Materials:")
                                .fontWeight(.bold)
                            Text("Tires, plastics, decomposable garbage (organic material, paper), petroleum and petroleum-treated materials, asphalt and asphalt materials, chemicals (pesticides, cleaners, detergents), or any material that produces black or dense smoke.")
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(15)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)

                    // MARK: - Agricultural Burning Card
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Agricultural Burning")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        Divider()
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Agricultural burning is the burning of any agriculture waste generated by an agricultural operation that uses, or intends to use, land primarily for the purpose of obtaining a profit by raising, harvesting, and selling crops or raising or selling animals (including poultry) or the products of animal husbandry.")
                                .padding(.bottom, 5)

                            Text("Prohibited materials, such as tires, may not be burned even in an agricultural setting.")
                                .fontWeight(.medium)
                                .padding(.bottom, 5)

                            Text("Open burning for agricultural purposes is usually allowed anywhere in the state, unless fire safety concerns restrict or prohibit burning on a given day. Agricultural open field burning... is regulated... under a separate program operated by the Oregon Department of Agriculture. Questions about field burning should be directed to the Oregon Department of Agriculture.")
                                .padding(.bottom, 5)

                            Text("DEQ approval is not required for agricultural permits. Contact your local fire department to inquire if an agricultural burn permit is otherwise needed. Individual fire districts may issue fire permits and may prohibit open burning based on local fire safety or air quality concerns. Always contact the burn information line to find out if agricultural burning is authorized on a particular day.")
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(15)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)

                    // MARK: - Reporting Violations Card
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Reporting Violations")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        Divider()

                        Text("To report violations of a person burning when burning is not allowed, please contact the Oregon Department of Environmental Quality at 888-997-7888.")
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(15)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)

                    // MARK: - DEQ Advisory Card
                    VStack(alignment: .leading, spacing: 10) {
                        Text("DEQ Advisory")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        Divider()

                        Text("Each Day, DEQ analyzes air quality and weather data to determine if ventilation is sufficient to allow open burning in the Willamette Valley. Before burning, one must still call their local fire department.")
                        Text("Individual fire districts may issue fire permits and may prohibit burning based on local fire safety or air quality concerns. Always contact your local fire department to find out if burning is authorized on a particular day.")
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(15)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                }
                .padding(.top, 20)
            }
        }
        .navigationTitle("Burn Information")
    }
}
