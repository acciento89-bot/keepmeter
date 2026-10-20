package de.kamilunavo.keepmeter.domain

import java.text.Normalizer
import java.util.Locale

object PurchaseFilter {
    fun matches(name: String, merchant: String, category: String, daysRemaining: Int,
                query: String, categoryFilter: String, dueSoon: Boolean): Boolean {
        if (categoryFilter != "all" && categoryFilter != category) return false
        if (dueSoon && daysRemaining !in 0..7) return false
        fun fold(s: String) = Normalizer.normalize(s, Normalizer.Form.NFD).replace(Regex("\\p{M}+"), "").lowercase(Locale.ROOT)
        return query.isBlank() || fold("$name $merchant").contains(fold(query.trim()))
    }
}

object PurchaseCSV {
    data class Row(val name: String, val merchant: String, val price: Double, val currency: String,
                   val purchaseDate: String, val returnDate: String, val outcome: String,
                   val uses: Int, val category: String)
    fun encode(rows: List<Row>, german: Boolean): String {
        val headers = if (german) listOf("Kauf", "Händler", "Preis", "Währung", "Kaufdatum", "Rückgabedatum", "Status", "Nutzungen", "Kosten pro Nutzung", "Kategorie")
            else listOf("Purchase", "Merchant", "Price", "Currency", "Purchase date", "Return date", "Status", "Uses", "Cost per use", "Category")
        fun number(n: Double) = String.format(Locale.ROOT, "%.2f", n)
        fun cell(s: String): String {
            val safe = if (s.trimStart().firstOrNull() in listOf('=', '+', '-', '@')) "'$s" else s
            return "\"${safe.replace("\"", "\"\"")}\""
        }
        val lines = mutableListOf(headers)
        rows.forEach { r ->
            val state = when (r.outcome) { "kept" -> if (german) "Behalten" else "Kept"; "returned" -> if (german) "Zurückgegeben" else "Returned"; else -> if (german) "Aktiv" else "Active" }
            lines += listOf(r.name, r.merchant, number(r.price), r.currency, r.purchaseDate, r.returnDate, state, r.uses.toString(), if (r.uses > 0) number(r.price / r.uses) else "", r.category)
        }
        return "\uFEFF" + lines.joinToString("\r\n") { row -> row.joinToString(",", transform = ::cell) } + "\r\n"
    }
}
