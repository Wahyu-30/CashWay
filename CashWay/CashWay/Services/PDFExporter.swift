import SwiftUI
import Combine
import PDFKit

// ============================================================
// MARK: - PDFExporter
// Mengkonversi SwiftUI view menjadi file PDF.
// Menggunakan ImageRenderer (iOS 16+ / macOS 13+) — tanpa
// library tambahan, 100% native Apple framework.
// ============================================================

@MainActor
struct PDFExporter {

    /// Generate PDF dari SwiftUI view dan simpan ke temporary directory.
    /// Mengembalikan URL file PDF, atau nil jika gagal.
    static func generateURL(for content: some View, filename: String) async -> URL? {
        let renderer = ImageRenderer(content: content)
        renderer.scale = 2.0   // Resolusi tinggi (retina)

        let safeFilename = filename
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(safeFilename).pdf")

        #if os(iOS)
        guard let uiImage = renderer.uiImage else {
            print("PDFExporter: Gagal render UIImage")
            return nil
        }

        let pageSize = CGSize(
            width: uiImage.size.width,
            height: uiImage.size.height
        )

        let pdfRenderer = UIGraphicsPDFRenderer(
            bounds: CGRect(origin: .zero, size: pageSize)
        )

        let data = pdfRenderer.pdfData { ctx in
            ctx.beginPage()
            uiImage.draw(at: .zero)
        }

        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            print("PDFExporter: Gagal tulis file — \(error)")
            return nil
        }

        #elseif os(macOS)
        guard let nsImage = renderer.nsImage else {
            print("PDFExporter: Gagal render NSImage")
            return nil
        }

        // Menggunakan PDFKit yang otomatis mengatur koordinat PDF 
        // sehingga NSImage tidak terbalik / upside-down.
        guard let pdfPage = PDFPage(image: nsImage) else { return nil }
        let pdfDoc = PDFDocument()
        pdfDoc.insert(pdfPage, at: 0)

        guard let data = pdfDoc.dataRepresentation() else { return nil }

        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            print("PDFExporter: Gagal tulis file — \(error)")
            return nil
        }
        #endif
    }
}
