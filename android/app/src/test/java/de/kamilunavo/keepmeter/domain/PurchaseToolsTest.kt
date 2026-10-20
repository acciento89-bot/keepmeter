package de.kamilunavo.keepmeter.domain
import org.junit.Assert.*
import org.junit.Test
class PurchaseToolsTest {
 @Test fun csvEscapesUnicodeQuotesAndPreventsFormulas() {
  val row = PurchaseCSV.Row("Kopfhörer, \"Pro\"\nNeu", " =1+1", 179.9, "EUR", "2026-10-01", "2026-10-30", "active", 2, "Technik")
  val csv = PurchaseCSV.encode(listOf(row), true)
  assertTrue(csv.startsWith("\uFEFF\"Kauf\",\"Händler\""))
  assertTrue(csv.contains("\"Kopfhörer, \"\"Pro\"\"\nNeu\""))
  assertTrue(csv.contains("\"' =1+1\""))
  assertTrue(csv.contains("\"179.90\",\"EUR\""))
  assertTrue(csv.contains("\"Aktiv\",\"2\",\"89.95\",\"Technik\"\r\n"))
 }
 @Test fun emptyAndUnusedExportsNeverDivideByZero() {
  assertEquals(2, PurchaseCSV.encode(emptyList(), false).split("\r\n").size)
  val row = PurchaseCSV.Row("=1+1", "", 1.0, "EUR", "", "", "returned", 0, "Other")
  val csv = PurchaseCSV.encode(listOf(row), false)
  assertTrue(csv.contains("\"'=1+1\""));assertTrue(csv.contains("\"Returned\",\"0\",\"\",\"Other\"\r\n"))
 }
 @Test fun searchFoldsAccentsAndCombinesCategoryAndDueDate() {
  assertTrue(PurchaseFilter.matches("Kopfhörer", "Läden", "tech", 7, "laden", "tech", true))
  for(days in listOf(-1,8)) assertFalse(PurchaseFilter.matches("A", "", "tech", days, "", "all", true))
  assertFalse(PurchaseFilter.matches("A", "", "tech", 2, "", "home", false))
  assertFalse(PurchaseFilter.matches("A", "", "tech", 2, "missing", "all", false))
 }
}
