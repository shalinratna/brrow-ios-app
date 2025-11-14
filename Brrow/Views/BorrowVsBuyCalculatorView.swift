import SwiftUI

struct BorrowVsBuyCalculatorView: View {
    let listing: Listing
    @StateObject private var viewModel: BorrowVsBuyViewModel
    @State private var showingFullBreakdown = false
    @State private var meterAngle: Double = 0
    @State private var pulseAnimation = false
    @State private var selectedUsageDays = 7
    @State private var selectedFrequency = "occasional"
    @Environment(\.dismiss) var dismiss
    
    init(listing: Listing) {
        self.listing = listing
        self._viewModel = StateObject(wrappedValue: BorrowVsBuyViewModel(listing: listing))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Animated gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Theme.Colors.background,
                        Theme.Colors.primary.opacity(0.05)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        // Header with item info
                        itemHeader
                        
                        // Usage Input Section
                        usageInputSection
                        
                        if viewModel.isCalculating {
                            ProgressView()
                                .scaleEffect(1.5)
                                .padding(.vertical, 50)
                        } else if let calculation = viewModel.calculation {
                            // Animated Meter
                            animatedMeter(calculation: calculation)
                            
                            // Quick Summary
                            quickSummary(calculation: calculation)
                            
                            // Insights
                            if let insights = viewModel.insights {
                                insightsSection(insights: insights)
                            }
                            
                            // Detailed Breakdown Button
                            detailedBreakdownButton
                            
                            // Market Comparison
                            if let marketData = calculation["market_comparison"] as? [String: Any] {
                                marketComparisonSection(marketData: marketData)
                            }
                        }
                        
                        Spacer(minLength: 50)
                    }
                    .padding()
                }
            }
            .navigationTitle("Borrow vs Buy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Theme.Colors.primary)
                }
            }
            .sheet(isPresented: $showingFullBreakdown) {
                if let calculation = viewModel.calculation {
                    DetailedBreakdownView(calculation: calculation, listing: listing)
                }
            }
        }
        .onAppear {
            viewModel.calculate(days: selectedUsageDays, frequency: selectedFrequency)
        }
    }
    
    private var itemHeader: some View {
        HStack(spacing: Theme.Spacing.md) {
            if let imageUrl = listing.imageUrls.first {
                BrrowAsyncImage(url: imageUrl) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(listing.title)
                    .font(.headline)
                    .lineLimit(2)
                
                HStack {
                    Label("$\(String(format: "%.2f", listing.price))/day", systemImage: "tag.fill")
                        .font(.subheadline)
                        .foregroundColor(Theme.Colors.primary)
                    
                    if false { // buyoutValue not available in new model
                        Text("•")
                            .foregroundColor(.gray)
                        Label("$\(String(format: "%.0f", listing.price * 10)) to buy", systemImage: "cart.fill")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10)
    }
    
    private var usageInputSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("How long do you need it?")
                .font(.headline)
            
            // Usage days slider (limited to 1-30 days)
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(selectedUsageDays)")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(Theme.Colors.primary)
                        Text(selectedUsageDays == 1 ? "day" : "days")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("$\(String(format: "%.2f", listing.price * Double(selectedUsageDays)))")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        Text("total cost")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Slider with range 1-30 days
                Slider(value: Binding(
                    get: { Double(selectedUsageDays) },
                    set: { selectedUsageDays = Int($0) }
                ), in: 1...30, step: 1)
                .accentColor(Theme.Colors.primary)
                .onChange(of: selectedUsageDays) { _ in
                    viewModel.calculate(days: selectedUsageDays, frequency: selectedFrequency)
                }

                // Quick selection buttons
                HStack(spacing: 8) {
                    ForEach([1, 3, 7, 14, 30], id: \.self) { days in
                        Button(action: {
                            selectedUsageDays = days
                            viewModel.calculate(days: selectedUsageDays, frequency: selectedFrequency)
                        }) {
                            Text("\(days)d")
                                .font(.caption)
                                .fontWeight(selectedUsageDays == days ? .bold : .regular)
                                .foregroundColor(selectedUsageDays == days ? .white : .secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(selectedUsageDays == days ? Theme.Colors.primary : Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
            }
            
            // Usage frequency picker
            Text("How often will you use it?")
                .font(.headline)
                .padding(.top)
            
            HStack(spacing: 8) {
                ForEach(["daily", "weekly", "monthly", "occasional"], id: \.self) { frequency in
                    Button(action: {
                        selectedFrequency = frequency
                        viewModel.calculate(days: selectedUsageDays, frequency: selectedFrequency)
                    }) {
                        Text(frequency.capitalized)
                            .font(.subheadline)
                            .fontWeight(selectedFrequency == frequency ? .semibold : .regular)
                            .foregroundColor(selectedFrequency == frequency ? .white : Theme.Colors.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                selectedFrequency == frequency ?
                                Theme.Colors.primary : Color.clear
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Theme.Colors.primary, lineWidth: 1)
                            )
                            .cornerRadius(20)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10)
    }
    
    private func animatedMeter(calculation: [String: Any]) -> some View {
        VStack(spacing: Theme.Spacing.md) {
            Text("Recommendation")
                .font(.headline)
            
            ZStack {
                // Background arc
                Circle()
                    .trim(from: 0.2, to: 0.8)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(144))
                
                // Colored segments
                Circle()
                    .trim(from: 0.2, to: 0.4)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.green, .mint]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 20
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(144))
                
                Circle()
                    .trim(from: 0.4, to: 0.6)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.yellow, .orange]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 20
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(144))
                
                Circle()
                    .trim(from: 0.6, to: 0.8)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.orange, .red]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 20
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(144))
                
                // Pointer
                VStack(spacing: 0) {
                    Circle()
                        .fill(Theme.Colors.primary)
                        .frame(width: 16, height: 16)
                        .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                    
                    Rectangle()
                        .fill(Theme.Colors.primary)
                        .frame(width: 4, height: 80)
                }
                .offset(y: -40)
                .rotationEffect(.degrees(meterAngle))
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: meterAngle)
                
                // Center recommendation
                VStack(spacing: 4) {
                    Image(systemName: getRecommendationIcon(calculation))
                        .font(.largeTitle)
                        .foregroundColor(getRecommendationColor(calculation))
                    
                    Text(getRecommendationText(calculation))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(getRecommendationColor(calculation))
                }
            }
            .frame(height: 220)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5)) {
                    meterAngle = getMeterAngle(calculation)
                }
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    pulseAnimation = true
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10)
    }
    
    private func quickSummary(calculation: [String: Any]) -> some View {
        HStack(spacing: Theme.Spacing.lg) {
            summaryCard(
                title: "Rental Cost",
                value: "$\(String(format: "%.2f", calculation["rental_total"] as? Double ?? 0))",
                subtitle: "for \(selectedUsageDays) days",
                color: .green
            )
            
            summaryCard(
                title: "Purchase Cost",
                value: "$\(String(format: "%.0f", calculation["purchase_price"] as? Double ?? 0))",
                subtitle: "one-time",
                color: .orange
            )
            
            summaryCard(
                title: "You Save",
                value: "$\(String(format: "%.2f", calculation["savings"] as? Double ?? 0))",
                subtitle: getRecommendationText(calculation) == "Borrow" ? "by renting" : "by buying",
                color: Theme.Colors.primary
            )
        }
    }
    
    private func summaryCard(title: String, value: String, subtitle: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func insightsSection(insights: [[String: Any]]) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Insights")
                .font(.headline)
            
            ForEach(insights.indices, id: \.self) { index in
                if let insight = insights[index] as? [String: Any],
                   let message = insight["message"] as? String,
                   let impact = insight["impact"] as? String {
                    HStack(spacing: 12) {
                        Image(systemName: getInsightIcon(impact))
                            .foregroundColor(getInsightColor(impact))
                            .font(.title3)
                        
                        Text(message)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    .padding()
                    .background(getInsightColor(impact).opacity(0.1))
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10)
    }
    
    private var detailedBreakdownButton: some View {
        Button(action: { showingFullBreakdown = true }) {
            HStack {
                Text("View Detailed Breakdown")
                    .fontWeight(.medium)
                
                Spacer()
                
                Image(systemName: "chart.bar.fill")
                    .font(.title3)
            }
            .foregroundColor(.white)
            .padding()
            .background(Theme.Colors.primary)
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }
    
    private func marketComparisonSection(marketData: [String: Any]) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Market Comparison")
                .font(.headline)
            
            if let avgRental = marketData["avg_rental_price"] as? Double {
                HStack {
                    Text("Average rental price")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("$\(String(format: "%.2f", avgRental))/day")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            
            if let avgPurchase = marketData["avg_purchase_price"] as? Double {
                HStack {
                    Text("Average purchase price")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("$\(String(format: "%.0f", avgPurchase))")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            
            if let availability = marketData["availability_score"] as? Int {
                HStack {
                    Text("Local availability")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    availabilityIndicator(score: availability)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10)
    }
    
    private func availabilityIndicator(score: Int) -> some View {
        HStack(spacing: 4) {
            ForEach(0..<5) { index in
                Circle()
                    .fill(index < score / 20 ? Theme.Colors.primary : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
            Text(score >= 80 ? "High" : score >= 40 ? "Medium" : "Low")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // Helper functions
    private func getMeterAngle(_ calculation: [String: Any]) -> Double {
        guard let score = calculation["recommendation_score"] as? Double else { return 0 }
        // Map 0-100 to -108 to 108 degrees (216 degree arc)
        return (score / 100) * 216 - 108
    }
    
    private func getRecommendationText(_ calculation: [String: Any]) -> String {
        guard let recommendation = calculation["recommendation"] as? String else { return "Calculate" }
        return recommendation.capitalized
    }
    
    private func getRecommendationIcon(_ calculation: [String: Any]) -> String {
        guard let recommendation = calculation["recommendation"] as? String else { return "questionmark.circle" }
        switch recommendation {
        case "borrow": return "arrow.down.circle.fill"
        case "buy": return "cart.fill"
        default: return "equal.circle.fill"
        }
    }
    
    private func getRecommendationColor(_ calculation: [String: Any]) -> Color {
        guard let recommendation = calculation["recommendation"] as? String else { return .gray }
        switch recommendation {
        case "borrow": return .green
        case "buy": return .orange
        default: return .yellow
        }
    }
    
    private func getInsightIcon(_ impact: String) -> String {
        switch impact {
        case "positive": return "checkmark.circle.fill"
        case "negative": return "exclamationmark.triangle.fill"
        default: return "info.circle.fill"
        }
    }
    
    private func getInsightColor(_ impact: String) -> Color {
        switch impact {
        case "positive": return .green
        case "negative": return .orange
        default: return .blue
        }
    }
}

// Detailed Breakdown View
struct DetailedBreakdownView: View {
    let calculation: [String: Any]
    let listing: Listing
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    // Cost Breakdown
                    costBreakdownSection
                    
                    // Break-even Analysis
                    breakEvenSection
                    
                    // Usage Scenarios
                    usageScenariosSection
                    
                    // Environmental Impact
                    environmentalImpactSection
                }
                .padding()
            }
            .navigationTitle("Detailed Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Theme.Colors.primary)
                }
            }
        }
    }
    
    private var costBreakdownSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Cost Breakdown")
                .font(.headline)
            
            VStack(spacing: 12) {
                breakdownRow(
                    label: "Daily rental rate",
                    value: "$\(String(format: "%.2f", listing.price))"
                )
                
                if let rentalTotal = calculation["rental_total"] as? Double {
                    breakdownRow(
                        label: "Total rental cost",
                        value: "$\(String(format: "%.2f", rentalTotal))",
                        isHighlighted: true
                    )
                }
                
                Divider()
                
                if let purchasePrice = calculation["purchase_price"] as? Double {
                    breakdownRow(
                        label: "Purchase price",
                        value: "$\(String(format: "%.0f", purchasePrice))"
                    )
                }
                
                if let depreciationCost = calculation["depreciation_cost"] as? Double {
                    breakdownRow(
                        label: "Depreciation cost",
                        value: "-$\(String(format: "%.2f", depreciationCost))",
                        color: .red
                    )
                }
                
                if let maintenanceCost = calculation["maintenance_cost"] as? Double {
                    breakdownRow(
                        label: "Maintenance cost",
                        value: "-$\(String(format: "%.2f", maintenanceCost))",
                        color: .red
                    )
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10)
    }
    
    private var breakEvenSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Break-even Analysis")
                .font(.headline)
            
            if let breakEvenDays = calculation["break_even_days"] as? Int {
                VStack(spacing: 8) {
                    Text("\(breakEvenDays)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(Theme.Colors.primary)
                    
                    Text("days to break even")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // Visual representation
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 40)
                            
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Theme.Colors.primary.opacity(0.8))
                                .frame(
                                    width: geometry.size.width * min(1.0, Double(7) / Double(breakEvenDays)),
                                    height: 40
                                )
                        }
                    }
                    .frame(height: 40)
                    .padding(.top)
                    
                    HStack {
                        Text("Your usage")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("Break-even")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10)
    }
    
    private var usageScenariosSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Usage Scenarios")
                .font(.headline)
            
            VStack(spacing: 12) {
                scenarioRow(days: 1, label: "Weekend project")
                scenarioRow(days: 7, label: "Week-long use")
                scenarioRow(days: 30, label: "Monthly rental")
                scenarioRow(days: 90, label: "Season-long")
                scenarioRow(days: 365, label: "Full year")
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10)
    }
    
    private var environmentalImpactSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Environmental Impact")
                .font(.headline)
            
            HStack(spacing: Theme.Spacing.lg) {
                VStack {
                    Image(systemName: "leaf.fill")
                        .font(.largeTitle)
                        .foregroundColor(.green)
                    Text("CO₂ Saved")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("~5 kg")
                        .font(.headline)
                        .foregroundColor(.green)
                }
                .frame(maxWidth: .infinity)
                
                VStack {
                    Image(systemName: "trash.slash.fill")
                        .font(.largeTitle)
                        .foregroundColor(.blue)
                    Text("Waste Reduced")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("1 item")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity)
                
                VStack {
                    Image(systemName: "person.2.fill")
                        .font(.largeTitle)
                        .foregroundColor(.purple)
                    Text("Community")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Connected")
                        .font(.headline)
                        .foregroundColor(.purple)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10)
    }
    
    private func breakdownRow(label: String, value: String, color: Color = .primary, isHighlighted: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(isHighlighted ? .subheadline.weight(.medium) : .subheadline)
                .foregroundColor(isHighlighted ? .primary : .secondary)
            Spacer()
            Text(value)
                .font(isHighlighted ? .subheadline.weight(.bold) : .subheadline)
                .foregroundColor(color)
        }
        .padding(.vertical, isHighlighted ? 8 : 4)
        .background(isHighlighted ? Theme.Colors.primary.opacity(0.05) : Color.clear)
        .cornerRadius(8)
    }
    
    private func scenarioRow(days: Int, label: String) -> some View {
        let rentalCost = listing.price * Double(days)
        let purchasePrice = nil ?? listing.price * 100
        let recommendation = rentalCost < purchasePrice * 0.3 ? "Rent" : "Buy"
        let color = recommendation == "Rent" ? Color.green : Color.orange
        
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Text("\(days) days")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("$\(String(format: "%.2f", rentalCost))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(recommendation)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(color)
            }
        }
    }
}

// ViewModel
class BorrowVsBuyViewModel: ObservableObject {
    @Published var calculation: [String: Any]?
    @Published var insights: [[String: Any]]?
    @Published var isCalculating = false
    @Published var error: String?
    
    private let listing: Listing
    private let apiClient = APIClient.shared
    
    init(listing: Listing) {
        self.listing = listing
    }
    
    func calculate(days: Int, frequency: String) {
        isCalculating = true
        error = nil

        let purchasePrice = listing.buyoutPrice ?? (listing.price * 100) // Use real buyout price or estimate
        
        apiClient.borrowVsBuyCalculation(
            listingId: Int(listing.id) ?? 0,
            category: listing.category?.name ?? "Unknown",
            purchasePrice: purchasePrice,
            rentalPriceDaily: listing.price,
            usageDays: days,
            usageFrequency: frequency
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isCalculating = false
                
                switch result {
                case .success(let response):
                    if let data = response["calculation"] as? [String: Any] {
                        self?.calculation = data
                    }
                    if let insights = response["insights"] as? [[String: Any]] {
                        self?.insights = insights
                    }
                case .failure(let error):
                    self?.error = error.localizedDescription
                }
            }
        }
    }
}