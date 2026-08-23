# 🎨 CashWay — Design Recommendation

**Untuk:** Wahyu Ahmad Cahyadi — Videografer & Editor  
**Konsep:** Dark, Premium, Minimal — seperti tools kreatif profesional

---

## 🎯 Filosofi Design

Kamu bekerja di bidang kreatif visual — terbiasa dengan Premiere Pro, DaVinci Resolve, Final Cut Pro yang semuanya **dark interface**. CashWay dirancang dengan filosofi yang sama:

> **"Finance app yang terasa seperti creative tool, bukan spreadsheet."**

- **Dark First** — mata tidak lelah, cocok untuk kerja malam/editing session
- **Data Dense tapi Clean** — info penting langsung terlihat, tidak perlu scroll
- **Teal/Emerald Accent** — modern, tech-forward, tidak terasa "bank" yang kaku
- **Card-based layout** — seperti timeline panel atau project board

---

## 🎨 Color Palette

```
BACKGROUND HIERARCHY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
■ #0F0F14  Background Utama      → Hitam kebiruan (seperti DaVinci background)
■ #1A1A2E  Surface / Card        → Sedikit lebih terang
■ #242438  Elevated Card         → Untuk modal/sheet
■ #2A2A3E  Border                → Garis pemisah subtle

ACCENT & STATUS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
■ #00C9A7  Accent Teal           → CTA, active tab, highlight
■ #4CAF82  Income Green          → Pemasukan (positif)
■ #FF6B6B  Expense Coral         → Pengeluaran (negatif)
■ #F4A261  Warning Amber         → Budget mendekati limit

TEXT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
○ #FFFFFF  Primary Text          → Jumlah besar, heading
○ #8B8FA8  Secondary Text        → Label, tanggal, subtitle
○ #4A4A6A  Disabled/Placeholder  → Placeholder text
```

---

## 📱 Layout Screens

### 1. Dashboard (Home)
```
┌─────────────────────────────┐
│  CashWay        [🔔] [👤]   │  ← Header
│  Hei, Way 👋                │  ← Greeting
│  Sabtu, 23 Agustus 2026     │
├─────────────────────────────┤
│  ┌─────────────────────┐    │
│  │  SALDO TOTAL        │    │  ← Glassmorphism card
│  │  Rp 12.450.000      │    │    dengan gradient teal
│  │  ▲ +5.2% vs bulan lalu │  │
│  └─────────────────────┘    │
├─────────────────────────────┤
│  ┌──────────┐ ┌──────────┐  │
│  │ ↑ Masuk  │ │ ↓ Keluar │  │  ← Twin stats
│  │ Rp 8.2Jt │ │ Rp 3.7Jt│  │
│  └──────────┘ └──────────┘  │
├─────────────────────────────┤
│  Pengeluaran Bulan Ini       │
│  ████▌█▌██░░░░░░░░░░░░░░    │  ← Bar chart 30 hari
├─────────────────────────────┤
│  Transaksi Terakhir          │
│  🍽️ Makan    Rp -45.000     │
│  🚗 Grab     Rp -25.000     │
│  💰 Gaji   Rp +12.000.000   │
└─────────────────────────────┘
│  🏠 Home │ 📋 Transaksi │ 🎯 Budget │ 📊 Laporan │ ⚙️ │
```

### 2. Add Transaction (Bottom Sheet)
```
┌─────────────────────────────┐
│         ━━━━━━              │  ← Drag handle
│  Pengeluaran  |  Pemasukan  │  ← Toggle segmented
├─────────────────────────────┤
│                             │
│       Rp 0                  │  ← Big number input
│                             │
│  ┌──────────────────────┐   │
│  │ 🍽️ Pilih Kategori >  │   │
│  └──────────────────────┘   │
│  ┌──────────────────────┐   │
│  │ 💳 GoPay          >  │   │
│  └──────────────────────┘   │
│  ┌──────────────────────┐   │
│  │ 📅 Hari ini        > │   │
│  └──────────────────────┘   │
│  Catatan...                 │
│                             │
│  ┌──────────────────────┐   │
│  │     Simpan           │   │  ← Teal CTA button
│  └──────────────────────┘   │
│  1  2  3  4  5  6  7  8  9  │  ← Custom numpad
│        0     .    ⌫         │
└─────────────────────────────┘
```

### 3. Budget Screen
```
┌─────────────────────────────┐
│  Budget Agustus 2026  ⚙️    │
├─────────────────────────────┤
│  🍽️ Makan & Minum           │
│  Rp 800.000 / Rp 1.000.000  │
│  ████████████████░░  80%    │  ← Warning amber
├─────────────────────────────┤
│  🚗 Transportasi            │
│  Rp 150.000 / Rp 500.000    │
│  ██████░░░░░░░░░░░░  30%    │  ← Normal teal
├─────────────────────────────┤
│  🎬 Equipment               │
│  Rp 2.500.000 / Rp 2.000.000│
│  ████████████████████ 125%  │  ← Over budget coral
└─────────────────────────────┘
```

---

## 🖥️ MacBook Layout

Di Mac, gunakan **NavigationSplitView** (sidebar + detail):

```
┌────────────────────────────────────────────────────────┐
│  CashWay                                  Rp 12.450.000│
├──────────────┬─────────────────────────────────────────┤
│  🏠 Dashboard│                                         │
│  📋 Transaksi│         Dashboard Content               │
│  💳 Wallet   │         (lebih lebar, lebih banyak info)│
│  🎯 Budget   │                                         │
│  📊 Laporan  │                                         │
│  ─────────── │                                         │
│  ⚙️ Settings │                                         │
└──────────────┴─────────────────────────────────────────┘
```

---

## ✨ Interaction & Animation

- **Haptic feedback** saat simpan transaksi (sukses / error)
- **Spring animation** saat card muncul (`.spring(response: 0.4, dampingFraction: 0.8)`)
- **Smooth chart** loading dengan animasi dari 0
- **Swipe to delete** di list transaksi
- **Konfirmasi hapus** dengan ActionSheet / Alert

---

## 🔤 Typography Highlights

| Elemen | Style | Contoh |
|--------|-------|--------|
| Saldo utama | SF Pro Rounded Bold, 40pt | `Rp 12.450.000` |
| Section title | SF Pro Display Semibold, 18pt | `Pengeluaran Bulan Ini` |
| Transaction amount | SF Pro Rounded Semibold, 16pt | `-Rp 45.000` |
| Label/Caption | SF Pro Text Regular, 13pt | `Makan & Minum` |

---

## 💡 Inspirasi Design

Tools dengan estetika serupa yang mungkin familiar:
- **DaVinci Resolve** → dark panel, colored indicators
- **Linear** (project management) → clean dark, smooth animations
- **Craft** (notes app) → card-based, excellent typography
- **Klack** (finance app) → dark finance, clear hierarchy

---

*Semua spesifikasi ini akan diimplementasikan langsung ke dalam kode SwiftUI.*
