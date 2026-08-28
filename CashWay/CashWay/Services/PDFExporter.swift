import SwiftUI
import Combine

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

        let pageSize = nsImage.size
        let pdfData  = NSMutableData()

        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData) else { return nil }

        var mediaBox = CGRect(origin: .zero, size: pageSize)
        guard let pdfCtx = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else { return nil }

        pdfCtx.beginPDFPage(nil)

        // Perbaikan: Sistem koordinat PDF di macOS dimulai dari kiri-bawah (Y-up), 
        // sedangkan NSImage digambar dari kiri-atas jika dikonversi biasa.
        // Cukup translate Y sebesar tinggi, dan scale Y dengan -1.
        if let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            pdfCtx.saveGState()
            pdfCtx.translateBy(x: 0, y: pageSize.height)
            pdfCtx.scaleBy(x: 1.0, y: -1.0)
            pdfCtx.draw(cgImage, in: CGRect(origin: .zero, size: pageSize))
            pdfCtx.restoreGState()
        }

        pdfCtx.endPDFPage()
        pdfCtx.closePDF()

        do {
            try (pdfData as Data).write(to: tempURL)
            return tempURL
        } catch {
            print("PDFExporter: Gagal tulis file — \(error)")
            return nil
        }
        #endif
    }
}
