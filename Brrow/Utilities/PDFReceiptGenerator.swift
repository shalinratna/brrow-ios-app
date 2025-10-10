//
//  PDFReceiptGenerator.swift
//  Brrow
//
//  Generate PDF receipts for purchases
//

import UIKit
import PDFKit

class PDFReceiptGenerator {

    static func generateReceipt(for purchase: Purchase) -> URL? {
        let pdfMetaData = [
            kCGPDFContextCreator: "Brrow",
            kCGPDFContextAuthor: "Brrow Inc.",
            kCGPDFContextTitle: "Purchase Receipt - \(purchase.id)"
        ]

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageWidth = 8.5 * 72.0  // Letter size width in points
        let pageHeight = 11 * 72.0  // Letter size height in points
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("receipt_\(purchase.id).pdf")

        do {
            try renderer.writePDF(to: tempURL) { context in
                context.beginPage()

                // Draw receipt content
                drawReceiptContent(in: pageRect, for: purchase, context: context)
            }
            return tempURL
        } catch {
            print("❌ Failed to create PDF: \(error)")
            return nil
        }
    }

    private static func drawReceiptContent(in rect: CGRect, for purchase: Purchase, context: UIGraphicsPDFRendererContext) {
        let margin: CGFloat = 40
        var yPosition: CGFloat = margin

        // Header - Brrow Logo and Title
        let titleFont = UIFont.systemFont(ofSize: 32, weight: .bold)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor(red: 0.165, green: 0.749, blue: 0.353, alpha: 1.0) // Brrow green
        ]
        let title = "BRROW"
        let titleSize = title.size(withAttributes: titleAttributes)
        let titleX = (rect.width - titleSize.width) / 2
        title.draw(at: CGPoint(x: titleX, y: yPosition), withAttributes: titleAttributes)
        yPosition += titleSize.height + 10

        // Subtitle
        let subtitleFont = UIFont.systemFont(ofSize: 14, weight: .regular)
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: subtitleFont,
            .foregroundColor: UIColor.darkGray
        ]
        let subtitle = "Purchase Receipt"
        let subtitleSize = subtitle.size(withAttributes: subtitleAttributes)
        let subtitleX = (rect.width - subtitleSize.width) / 2
        subtitle.draw(at: CGPoint(x: subtitleX, y: yPosition), withAttributes: subtitleAttributes)
        yPosition += subtitleSize.height + 30

        // Success checkmark icon (using Unicode)
        let checkmarkFont = UIFont.systemFont(ofSize: 48, weight: .bold)
        let checkmarkAttributes: [NSAttributedString.Key: Any] = [
            .font: checkmarkFont,
            .foregroundColor: UIColor.systemGreen
        ]
        let checkmark = "✓"
        let checkmarkSize = checkmark.size(withAttributes: checkmarkAttributes)
        let checkmarkX = (rect.width - checkmarkSize.width) / 2
        checkmark.draw(at: CGPoint(x: checkmarkX, y: yPosition), withAttributes: checkmarkAttributes)
        yPosition += checkmarkSize.height + 20

        // Purchase Confirmed text
        let confirmedFont = UIFont.systemFont(ofSize: 20, weight: .bold)
        let confirmedAttributes: [NSAttributedString.Key: Any] = [
            .font: confirmedFont,
            .foregroundColor: UIColor.black
        ]
        let confirmedText = "Purchase Confirmed"
        let confirmedSize = confirmedText.size(withAttributes: confirmedAttributes)
        let confirmedX = (rect.width - confirmedSize.width) / 2
        confirmedText.draw(at: CGPoint(x: confirmedX, y: yPosition), withAttributes: confirmedAttributes)
        yPosition += confirmedSize.height + 40

        // Separator line
        drawLine(from: CGPoint(x: margin, y: yPosition), to: CGPoint(x: rect.width - margin, y: yPosition), color: .lightGray)
        yPosition += 20

        // Transaction Details Section
        yPosition = drawSection(title: "Transaction Details", yPosition: yPosition, margin: margin, rect: rect)

        let detailFont = UIFont.systemFont(ofSize: 12, weight: .regular)
        let labelFont = UIFont.systemFont(ofSize: 12, weight: .semibold)

        yPosition = drawDetailRow(label: "Transaction ID:", value: String(purchase.id.prefix(12).uppercased()), yPosition: yPosition, margin: margin, rect: rect, labelFont: labelFont, detailFont: detailFont)
        yPosition = drawDetailRow(label: "Purchase Type:", value: purchase.purchaseType == .buyNow ? "Buy Now" : "Accepted Offer", yPosition: yPosition, margin: margin, rect: rect, labelFont: labelFont, detailFont: detailFont)
        yPosition = drawDetailRow(label: "Payment Status:", value: "Held in Escrow", yPosition: yPosition, margin: margin, rect: rect, labelFont: labelFont, detailFont: detailFont)
        yPosition = drawDetailRow(label: "Purchase Date:", value: formatDate(purchase.createdAt), yPosition: yPosition, margin: margin, rect: rect, labelFont: labelFont, detailFont: detailFont)
        yPosition += 20

        // Item Details Section
        if let listing = purchase.listing {
            yPosition = drawSection(title: "Item Details", yPosition: yPosition, margin: margin, rect: rect)
            yPosition = drawDetailRow(label: "Item:", value: listing.title, yPosition: yPosition, margin: margin, rect: rect, labelFont: labelFont, detailFont: detailFont)
            yPosition += 20
        }

        // Seller Information
        if let seller = purchase.seller {
            yPosition = drawSection(title: "Seller Information", yPosition: yPosition, margin: margin, rect: rect)
            yPosition = drawDetailRow(label: "Seller:", value: seller.username, yPosition: yPosition, margin: margin, rect: rect, labelFont: labelFont, detailFont: detailFont)
            yPosition += 20
        }

        // Price Breakdown Section
        yPosition = drawSection(title: "Price Breakdown", yPosition: yPosition, margin: margin, rect: rect)
        yPosition = drawDetailRow(label: "Item Price:", value: "$\(String(format: "%.2f", purchase.amount))", yPosition: yPosition, margin: margin, rect: rect, labelFont: labelFont, detailFont: detailFont)
        yPosition = drawDetailRow(label: "Service Fee:", value: "$0.00", yPosition: yPosition, margin: margin, rect: rect, labelFont: labelFont, detailFont: detailFont)
        yPosition += 10

        // Total line
        drawLine(from: CGPoint(x: margin, y: yPosition), to: CGPoint(x: rect.width - margin, y: yPosition), color: .lightGray)
        yPosition += 10

        let totalFont = UIFont.systemFont(ofSize: 14, weight: .bold)
        yPosition = drawDetailRow(label: "Total Paid:", value: "$\(String(format: "%.2f", purchase.amount))", yPosition: yPosition, margin: margin, rect: rect, labelFont: totalFont, detailFont: totalFont)
        yPosition += 30

        // Escrow Notice
        yPosition = drawNoticeBox(
            title: "Payment Held in Escrow",
            message: "Your payment of $\(String(format: "%.2f", purchase.amount)) is securely held until you verify receipt of the item. Meet the seller by \(formatDate(purchase.deadline)) to complete verification.",
            yPosition: yPosition,
            margin: margin,
            rect: rect,
            backgroundColor: UIColor.systemGreen.withAlphaComponent(0.1),
            borderColor: UIColor.systemGreen
        )

        yPosition += 20

        // Deadline Notice
        yPosition = drawNoticeBox(
            title: "3-Day Verification Deadline",
            message: "You must meet the seller and verify the item by \(formatDate(purchase.deadline)). If not completed, your payment will be automatically refunded.",
            yPosition: yPosition,
            margin: margin,
            rect: rect,
            backgroundColor: UIColor.systemOrange.withAlphaComponent(0.1),
            borderColor: UIColor.systemOrange
        )

        // Footer
        yPosition = rect.height - 80
        let footerFont = UIFont.systemFont(ofSize: 10, weight: .regular)
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: footerFont,
            .foregroundColor: UIColor.gray
        ]
        let footerText = "Thank you for using Brrow!\nFor support, visit brrowapp.com or email support@brrowapp.com"
        let footerParagraphStyle = NSMutableParagraphStyle()
        footerParagraphStyle.alignment = .center
        footerParagraphStyle.lineSpacing = 4
        let footerAttributedString = NSAttributedString(string: footerText, attributes: [
            .font: footerFont,
            .foregroundColor: UIColor.gray,
            .paragraphStyle: footerParagraphStyle
        ])
        let footerRect = CGRect(x: margin, y: yPosition, width: rect.width - (margin * 2), height: 60)
        footerAttributedString.draw(in: footerRect)
    }

    private static func drawSection(title: String, yPosition: CGFloat, margin: CGFloat, rect: CGRect) -> CGFloat {
        let sectionFont = UIFont.systemFont(ofSize: 14, weight: .bold)
        let sectionAttributes: [NSAttributedString.Key: Any] = [
            .font: sectionFont,
            .foregroundColor: UIColor.black
        ]
        title.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: sectionAttributes)
        let titleSize = title.size(withAttributes: sectionAttributes)
        return yPosition + titleSize.height + 10
    }

    private static func drawDetailRow(label: String, value: String, yPosition: CGFloat, margin: CGFloat, rect: CGRect, labelFont: UIFont, detailFont: UIFont) -> CGFloat {
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: labelFont,
            .foregroundColor: UIColor.darkGray
        ]
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: detailFont,
            .foregroundColor: UIColor.black
        ]

        label.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: labelAttributes)
        let valueSize = value.size(withAttributes: valueAttributes)
        value.draw(at: CGPoint(x: rect.width - margin - valueSize.width, y: yPosition), withAttributes: valueAttributes)

        let labelSize = label.size(withAttributes: labelAttributes)
        return yPosition + max(labelSize.height, valueSize.height) + 8
    }

    private static func drawNoticeBox(title: String, message: String, yPosition: CGFloat, margin: CGFloat, rect: CGRect, backgroundColor: UIColor, borderColor: UIColor) -> CGFloat {
        let boxPadding: CGFloat = 12
        let boxWidth = rect.width - (margin * 2)

        let titleFont = UIFont.systemFont(ofSize: 12, weight: .bold)
        let messageFont = UIFont.systemFont(ofSize: 10, weight: .regular)

        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.black
        ]

        let messageParagraphStyle = NSMutableParagraphStyle()
        messageParagraphStyle.lineSpacing = 2
        let messageAttributes: [NSAttributedString.Key: Any] = [
            .font: messageFont,
            .foregroundColor: UIColor.darkGray,
            .paragraphStyle: messageParagraphStyle
        ]

        let titleSize = title.size(withAttributes: titleAttributes)
        let messageWidth = boxWidth - (boxPadding * 2)
        let messageRect = message.boundingRect(with: CGSize(width: messageWidth, height: .greatestFiniteMagnitude), options: .usesLineFragmentOrigin, attributes: messageAttributes, context: nil)

        let boxHeight = titleSize.height + messageRect.height + (boxPadding * 3) + 4

        // Draw background
        let boxRect = CGRect(x: margin, y: yPosition, width: boxWidth, height: boxHeight)
        let boxPath = UIBezierPath(roundedRect: boxRect, cornerRadius: 8)
        backgroundColor.setFill()
        boxPath.fill()

        // Draw border
        borderColor.setStroke()
        boxPath.lineWidth = 1.5
        boxPath.stroke()

        // Draw title
        title.draw(at: CGPoint(x: margin + boxPadding, y: yPosition + boxPadding), withAttributes: titleAttributes)

        // Draw message
        message.draw(in: CGRect(x: margin + boxPadding, y: yPosition + boxPadding + titleSize.height + 4, width: messageWidth, height: messageRect.height), withAttributes: messageAttributes)

        return yPosition + boxHeight
    }

    private static func drawLine(from start: CGPoint, to end: CGPoint, color: UIColor) {
        let path = UIBezierPath()
        path.move(to: start)
        path.addLine(to: end)
        color.setStroke()
        path.lineWidth = 0.5
        path.stroke()
    }

    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
