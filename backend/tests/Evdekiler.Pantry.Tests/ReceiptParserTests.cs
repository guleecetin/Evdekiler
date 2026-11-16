using Evdekiler.Pantry.Api.Receipts;

namespace Evdekiler.Pantry.Tests;

public class ReceiptParserTests
{
    [Fact]
    public void Ignores_store_name_totals_and_tax_lines()
    {
        var result = ReceiptParser.Parse(
        [
            "MIGROS TICARET A.S.",
            "TOPLAM *412,53",
            "KDV %1 *4,08",
            "NAKIT *420,00"
        ]);

        Assert.Empty(result);
    }

    [Fact]
    public void Reads_weight_in_kilograms()
    {
        var line = Assert.Single(ReceiptParser.Parse(["DOMATES KG 1,250 X 24,90 *31,13"]));

        Assert.Equal("DOMATES", line.Text);
        Assert.Equal(1.25m, line.Quantity);
        Assert.Equal("Kilogram", line.Unit);
    }

    [Theory]
    [InlineData("SUT 1LT TAM YAG %1 *42,50", "SUT TAM YAG", 1, "Liter")]
    [InlineData("KASAR PEYN 400G %1 *189,90", "KASAR PEYN", 400, "Gram")]
    [InlineData("YUMURTA 30LU %1 *149,00", "YUMURTA", 30, "Piece")]
    [InlineData("ZEYTINYAGI 500ML *210,00", "ZEYTINYAGI", 500, "Milliliter")]
    [InlineData("BIRTAT YOGURT 1500GR%8 *825,000", "BIRTAT YOGURT", 1500, "Gram")]
    [InlineData("PINAR SUT 1/2 %8 *45,00", "PINAR SUT", 0.5, "Liter")]
    public void Reads_quantity_and_unit_from_product_line(string raw, string text, decimal qty, string unit)
    {
        var line = Assert.Single(ReceiptParser.Parse([raw]));

        Assert.Equal(text, line.Text);
        Assert.Equal(qty, line.Quantity);
        Assert.Equal(unit, line.Unit);
    }

    [Fact]
    public void Applies_count_line_to_the_next_product()
    {
        var line = Assert.Single(ReceiptParser.Parse(["2 X 15,90", "MAKARNA 500G %1 *31,80"]));

        Assert.Equal("MAKARNA", line.Text);
        Assert.Equal(1000m, line.Quantity);
        Assert.Equal("Gram", line.Unit);
    }

    [Fact]
    public void Folds_turkish_characters()
    {
        var line = Assert.Single(ReceiptParser.Parse(["Süt Kaşar Peyniri *99,90"]));

        Assert.Equal("SUT KASAR PEYNIRI", line.Text);
        Assert.Null(line.Quantity);
    }

    [Fact]
    public void Does_not_ignore_words_that_only_contain_an_ignored_word()
    {
        // "TEL" yok sayılan bir kelime ama "TEL SEHRIYE" bir ürün
        var line = Assert.Single(ReceiptParser.Parse(["TEL SEHRIYE 500G *19,90"]));

        Assert.Equal("TEL SEHRIYE", line.Text);
    }

    // ─── Gerçek fişler ─────────────────────────────────────────

    [Fact]
    public void Real_receipt_gima_with_cancelled_item()
    {
        string[] receipt =
        [
            "GIMA T.A.S.",
            "ADAPAZARI MAGAZALARI",
            "ADNAN MENDERES CAD. NO:180",
            "ADAPAZARI TEL:274 58 00",
            "ANADOLU KURUMLAR V.D. 3950079068",
            "TARIH : 15/12/1999 SAAT: 18:09",
            "FIS NO: 32",
            "###8690565100530#",
            "2 X 1.0 AD TL395,000 SF",
            "PINAR SUT 1/1 %8 *790,000",
            "###8690565100530#",
            "PINAR SUT 1/1 %8 *395,000",
            "*** HATA DUZELT. ***",
            "###8690565100530#",
            "PINAR SUT 1/1 %8 -395,000C",
            "###8690762020198#",
            "BIRTAT YOGURT 1500GR%8 *825,000",
            "3 X 1.0 KG TL200.000 SF",
            "K.BAKI UNLU MAM.%1 %1 *600,000",
            "ARATOP *6.550.500",
            "TOPKDV *499,663",
            "TOPLAM *6.550.500",
            "NAKIT *10.000.000",
            "P.USTU *3.449.500",
            "KASIYER: YASEMIN OCAK"
        ];

        var result = ReceiptParser.Parse(receipt);

        // İptal edilen tek süt düştü, 2 litrelik satır kaldı
        var milk = Assert.Single(result, r => r.Text == "PINAR SUT");
        Assert.Equal(2m, milk.Quantity);
        Assert.Equal("Liter", milk.Unit);

        var yogurt = Assert.Single(result, r => r.Text == "BIRTAT YOGURT");
        Assert.Equal(1500m, yogurt.Quantity);

        // 3 X 1.0 KG -> 3 kg unlu mamul
        var bakery = Assert.Single(result, r => r.Text.Contains("UNLU"));
        Assert.Equal(3m, bakery.Quantity);
        Assert.Equal("Kilogram", bakery.Unit);

        // Adres, toplam, ödeme satırlarından hiçbiri yok
        Assert.DoesNotContain(result, r => r.Text.Contains("ADNAN") || r.Text.Contains("TOP") || r.Text.Contains("KASIYER"));
    }

    [Fact]
    public void Real_receipt_small_market()
    {
        string[] receipt =
        [
            "TURUNCU MARKET",
            "GÖKTÜRK MAH.BAĞLAR CAD.NO:109/B",
            "ÇANKAYA/ANKARA",
            "CUMHURİYET V.D:638 1127 2134",
            "TEŞEKKÜR EDERİZ",
            "16/12/2017 FİŞ NO: 0001",
            "EKMEK %1 *128,95",
            "KDV *1,28",
            "TOP *128,95",
            "KREDİ *128,95",
            "KASİYER: A/KASİYER #1",
            "EKÜ NO:0001 Z NO:0019"
        ];

        var result = ReceiptParser.Parse(receipt);

        Assert.Contains(result, r => r.Text == "EKMEK");
        Assert.DoesNotContain(result, r => r.Text.Contains("MARKET") || r.Text.Contains("GOKTURK") || r.Text.Contains("KREDI"));
    }
}