package de.kamilunavo.keepmeter

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.media.ExifInterface
import android.net.Uri
import java.io.File
import java.util.UUID

/** Private, downsampled copies; no photo-library permission or network upload. */
object ReceiptStorage {
    fun save(context: Context, uri: Uri): String {
        val folder = File(context.filesDir, "receipts").apply { mkdirs() }
        val source = File(folder, "${UUID.randomUUID()}.source")
        val output = File(folder, "${UUID.randomUUID()}.jpg")
        try {
            val input = context.contentResolver.openInputStream(uri) ?: error("Missing image")
            input.use { stream -> source.outputStream().use { out ->
                val buffer = ByteArray(8192); var total = 0
                while (true) { val size = stream.read(buffer); if (size < 0) break; total += size
                    check(total <= 35_000_000) { "Image too large" }; out.write(buffer, 0, size) }
            } }
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(source.path, bounds)
            check(bounds.outWidth > 0 && bounds.outHeight > 0)
            var sample = 1
            while (maxOf(bounds.outWidth, bounds.outHeight) / sample > 1600) sample *= 2
            val bitmap = BitmapFactory.decodeFile(source.path, BitmapFactory.Options().apply { inSampleSize = sample }) ?: error("Unsupported image")
            val matrix = Matrix()
            when (ExifInterface(source.path).getAttributeInt(ExifInterface.TAG_ORIENTATION, 1)) {
                2 -> matrix.setScale(-1f, 1f)
                3 -> matrix.setRotate(180f)
                4 -> matrix.setScale(1f, -1f)
                5 -> { matrix.setRotate(90f); matrix.postScale(-1f, 1f) }
                6 -> matrix.setRotate(90f)
                7 -> { matrix.setRotate(270f); matrix.postScale(-1f, 1f) }
                8 -> matrix.setRotate(270f)
            }
            val rotated = Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
            try { output.outputStream().use { check(rotated.compress(Bitmap.CompressFormat.JPEG, 80, it)) } }
            finally { if (rotated !== bitmap) rotated.recycle(); bitmap.recycle() }
            return output.path
        } catch (e: Exception) { output.delete(); throw e }
        finally { source.delete() }
    }
    fun delete(context: Context, path: String?) {
        if (path == null) return
        val folder = File(context.filesDir, "receipts").canonicalFile
        val file = File(path).canonicalFile
        if (file.parentFile == folder) file.delete()
    }
}
