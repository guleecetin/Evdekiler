using System.Globalization;
using System.Text.RegularExpressions;

namespace Evdekiler.Pantry.Api.Receipts;

public record ParsedReceiptLine(string Raw, string Text, decimal? Quantity, string? Unit);

public static partial class ReceiptParser
{
    // Ürün olmayan satırlar: toplamlar, ödeme, adres, mağaza bilgisi, iptal başlığı.
    // TEL sadece "TEL:" olarak (telefon numarası); "TEL SEHRIYE" bir ürün.
    [GeneratedRegex(@"\b(TOPLAM|TOPKDV|ARATOP|TOP|KDV|NAKIT|KREDI|KART|P\.?\s?USTU|PARA USTU|ODEME|INDIRIM|TARIH|SAAT|FIS|FATURA|VERGI|V\.D|MERSIS|TEL\s*:|KASIYER|TESEKKUR|BANKA|ONAY|POS|EKU|Z NO|PROVIZYON|NO\s*:|A\.S|LTD|STI|TIC|MAGAZA\w*|MARKET|CAD|MAH|SOK|HATA)")]
    private static partial Regex IgnoredRegex();

    // "2 X", "2 X 1.0 AD", "3 X 1.0 KG" gibi adet satırları
    [GeneratedRegex(@"^\s*(\d+)\s*X\b(?:\s*(\d+[.,]\d+)\s*(AD|ADET|KG))?")]
    private static partial Regex CountLineRegex();

    // İptal edilen ürün satırı: eksi fiyat ("-395,000C")
    [GeneratedRegex(@"-\s*\d+[.,]\d+")]
    private static partial Regex NegativePriceRegex();

    [GeneratedRegex(@"(\d+[.,]\d+|\d+)\s*KG\b|KG\s*(\d+[.,]\d+)")]
    private static partial Regex KilogramRegex();

    [GeneratedRegex(@"(\d+)\s*(?:G|GR)\b")]
    private static partial Regex GramRegex();

    [GeneratedRegex(@"(\d+[.,]?\d*)\s*(?:LT|L)\b")]
    private static partial Regex LiterRegex();

    [GeneratedRegex(@"(\d+)\s*ML\b")]
    private static partial Regex MilliliterRegex();

    // Süt şişelerindeki "1/1" (1 litre), "1/2" (yarım litre)
    [GeneratedRegex(@"\b(\d)/(\d)\b")]
    private static partial Regex FractionLiterRegex();

    [GeneratedRegex(@"(\d+)\s*'?(?:LI|LU)\b")]
    private static partial Regex PieceRegex();

    [GeneratedRegex(@"[A-Z]{2,}")]
    private static partial Regex HasWordRegex();

    // Adresin ilçe/il satırı: "KADIKOY / ISTANBUL", "CANKAYA/ANKARA" (rakam içermez)
    [GeneratedRegex(@"^[A-Z.\s]+/\s*[A-Z.\s]+$")]
    private static partial Regex DistrictCityRegex();

    // Satırda fiyat var mı: "*19,90", "42,50"
    [GeneratedRegex(@"\d+[.,]\d{2}\b")]
    private static partial Regex PriceRegex();

    [GeneratedRegex(@"\*?-?\d+[.,]\d+(?:[.,]\d+)*[A-Z]?\b|%\s*\d+|\bX\b|\b\d+[.,]?\d*\s*(?:KG|GR|G|LT|L|ML|'?LI|'?LU)?\b|\bKG\b|[^A-Z\s]")]
    private static partial Regex NoiseRegex();

    [GeneratedRegex(@"\s+")]
    private static partial Regex SpacesRegex();

    public static List<ParsedReceiptLine> Parse(IEnumerable<string> lines)
    {
        var result = new List<ParsedReceiptLine>();
        int? pendingCount = null;
        decimal? pendingKg = null;

        foreach (var raw in lines)
        {
            var line = Fold(raw);
            if (line.Length < 3) continue;

            // 1. Adet satırı: bir sonraki ürüne uygulanmak üzere hatırla
            var count = CountLineRegex().Match(line);
            if (count.Success)
            {
                pendingCount = int.Parse(count.Groups[1].Value);
                pendingKg = count.Groups[3].Value == "KG" ? ParseNumber(count.Groups[2].Value) : null;
                continue;
            }

            // 2. Barkod gibi harfsiz satırlar ve bilinen ürün dışı satırlar
            if (!HasWordRegex().IsMatch(line)) continue;
            if (IgnoredRegex().IsMatch(line)) continue;
            if (DistrictCityRegex().IsMatch(line)) continue;

            var text = SpacesRegex().Replace(NoiseRegex().Replace(line, " "), " ").Trim();

            // "SU 5 L *19,90" gibi iki harfli ürünler: sadece yanında fiyat varsa ürün say,
            // yoksa OCR'ın ürettiği kırıntı ("TL", "AD") olma ihtimali yüksek
            if (text.Length < 2) continue;
            if (text.Length == 2 && !PriceRegex().IsMatch(line)) continue;

            // 3. İptal satırı: aynı üründen en son ekleneni listeden çıkar
            if (NegativePriceRegex().IsMatch(line))
            {
                var last = result.FindLastIndex(r => r.Text == text);
                if (last >= 0) result.RemoveAt(last);
                pendingCount = null;
                pendingKg = null;
                continue;
            }

            // 4. Miktar: satırın kendisinden, varsa üstteki adet satırıyla birleştir
            var (quantity, unit) = ExtractQuantity(line);
            if (pendingKg is not null && pendingCount is not null)
            {
                quantity = pendingCount.Value * pendingKg.Value;
                unit = "Kilogram";
            }
            else if (pendingCount is > 1)
            {
                quantity = (quantity ?? 1) * pendingCount.Value;
                unit ??= "Piece";
            }
            pendingCount = null;
            pendingKg = null;

            result.Add(new ParsedReceiptLine(raw, text, quantity, unit));
        }

        return result;
    }

    private static (decimal? Quantity, string? Unit) ExtractQuantity(string line)
    {
        var m = KilogramRegex().Match(line);
        if (m.Success)
        {
            var value = m.Groups[1].Success ? m.Groups[1].Value : m.Groups[2].Value;
            return (ParseNumber(value), "Kilogram");
        }

        if ((m = MilliliterRegex().Match(line)).Success) return (ParseNumber(m.Groups[1].Value), "Milliliter");
        if ((m = LiterRegex().Match(line)).Success) return (ParseNumber(m.Groups[1].Value), "Liter");
        if ((m = GramRegex().Match(line)).Success) return (ParseNumber(m.Groups[1].Value), "Gram");
        if ((m = PieceRegex().Match(line)).Success) return (ParseNumber(m.Groups[1].Value), "Piece");

        if ((m = FractionLiterRegex().Match(line)).Success)
        {
            var den = int.Parse(m.Groups[2].Value);
            if (den > 0) return (decimal.Parse(m.Groups[1].Value) / den, "Liter");
        }

        return (null, null);
    }

    private static decimal ParseNumber(string value) =>
        decimal.Parse(value.Replace(',', '.'), CultureInfo.InvariantCulture);

    public static string Fold(string text)
    {
        var mapped = text
            .Replace('ç', 'c').Replace('Ç', 'C').Replace('ğ', 'g').Replace('Ğ', 'G')
            .Replace('ı', 'i').Replace('İ', 'I').Replace('ö', 'o').Replace('Ö', 'O')
            .Replace('ş', 's').Replace('Ş', 'S').Replace('ü', 'u').Replace('Ü', 'U');

        return mapped.ToUpperInvariant().Trim();
    }
}