using Evdekiler.Pantry.Api.Entities;

namespace Evdekiler.Pantry.Api.Data;

public static class IngredientSeed
{
    private static Ingredient I(int id, string name, string emoji, IngredientCategory c, MeasureUnit u) =>
        new() { Id = id, Name = name, Emoji = emoji, Category = c, DefaultUnit = u };

    public static readonly Ingredient[] All =
    [
        // --- Temel sebze, meyve, süt ürünleri, et, tahıl ---
        I(1,  "Domates",       "🍅", IngredientCategory.Vegetable, MeasureUnit.Piece),
        I(2,  "Salatalık",     "🥒", IngredientCategory.Vegetable, MeasureUnit.Piece),
        I(3,  "Biber",         "🫑", IngredientCategory.Vegetable, MeasureUnit.Piece),
        I(4,  "Soğan",         "🧅", IngredientCategory.Vegetable, MeasureUnit.Piece),
        I(5,  "Sarımsak",      "🧄", IngredientCategory.Vegetable, MeasureUnit.Piece),
        I(6,  "Patates",       "🥔", IngredientCategory.Vegetable, MeasureUnit.Kilogram),
        I(7,  "Havuç",         "🥕", IngredientCategory.Vegetable, MeasureUnit.Piece),
        I(8,  "Kabak",         "🥒", IngredientCategory.Vegetable, MeasureUnit.Piece),
        I(9,  "Patlıcan",      "🍆", IngredientCategory.Vegetable, MeasureUnit.Piece),
        I(10, "Ispanak",       "🥬", IngredientCategory.Vegetable, MeasureUnit.Gram),
        I(11, "Limon",         "🍋", IngredientCategory.Fruit,     MeasureUnit.Piece),
        I(12, "Elma",          "🍎", IngredientCategory.Fruit,     MeasureUnit.Piece),
        I(13, "Süt",           "🥛", IngredientCategory.Dairy,     MeasureUnit.Liter),
        I(14, "Yoğurt",        "🥣", IngredientCategory.Dairy,     MeasureUnit.Gram),
        I(15, "Beyaz peynir",  "🧀", IngredientCategory.Dairy,     MeasureUnit.Gram),
        I(16, "Kaşar peyniri", "🧀", IngredientCategory.Dairy,     MeasureUnit.Gram),
        I(17, "Tereyağı",      "🧈", IngredientCategory.Dairy,     MeasureUnit.Gram),
        I(18, "Yumurta",       "🥚", IngredientCategory.Dairy,     MeasureUnit.Piece),
        I(19, "Tavuk göğsü",   "🍗", IngredientCategory.Meat,      MeasureUnit.Gram),
        I(20, "Kıyma",         "🥩", IngredientCategory.Meat,      MeasureUnit.Gram),
        I(21, "Pirinç",        "🍚", IngredientCategory.Grain,     MeasureUnit.Gram),
        I(22, "Makarna",       "🍝", IngredientCategory.Grain,     MeasureUnit.Gram),
        I(23, "Bulgur",        "🌾", IngredientCategory.Grain,     MeasureUnit.Gram),
        I(24, "Un",            "🌾", IngredientCategory.Grain,     MeasureUnit.Gram),
        I(25, "Mercimek",      "🫘", IngredientCategory.Legume,    MeasureUnit.Gram),
        I(26, "Nohut",         "🫘", IngredientCategory.Legume,    MeasureUnit.Gram),
        I(27, "Salça",         "🥫", IngredientCategory.Other,     MeasureUnit.Gram),
        I(28, "Zeytinyağı",    "🫒", IngredientCategory.Other,     MeasureUnit.Milliliter),
        I(29, "Tuz",           "🧂", IngredientCategory.Spice,     MeasureUnit.Gram),
        I(30, "Pul biber",     "🌶️", IngredientCategory.Spice,     MeasureUnit.Gram),

        // --- Ana yemek genişletmesi ---
        I(31, "Maydanoz",      "🌿", IngredientCategory.Vegetable, MeasureUnit.Piece),
        I(32, "Dereotu",       "🌿", IngredientCategory.Vegetable, MeasureUnit.Piece),
        I(33, "Nane",          "🌿", IngredientCategory.Spice,     MeasureUnit.Gram),
        I(34, "Mantar",        "🍄", IngredientCategory.Vegetable, MeasureUnit.Gram),
        I(35, "Brokoli",       "🥦", IngredientCategory.Vegetable, MeasureUnit.Piece),
        I(36, "Karnabahar",    "🥦", IngredientCategory.Vegetable, MeasureUnit.Piece),
        I(37, "Taze fasulye",  "🫛", IngredientCategory.Vegetable, MeasureUnit.Gram),
        I(38, "Kuru fasulye",  "🫘", IngredientCategory.Legume,    MeasureUnit.Gram),
        I(39, "Pırasa",        "🥬", IngredientCategory.Vegetable, MeasureUnit.Piece),
        I(40, "Bezelye",       "🫛", IngredientCategory.Vegetable, MeasureUnit.Gram),
        I(41, "Mısır",         "🌽", IngredientCategory.Vegetable, MeasureUnit.Gram),
        I(42, "Lahana",        "🥬", IngredientCategory.Vegetable, MeasureUnit.Piece),
        I(43, "Kırmızı biber", "🫑", IngredientCategory.Vegetable, MeasureUnit.Piece),
        I(44, "Sucuk",         "🌭", IngredientCategory.Meat,      MeasureUnit.Gram),
        I(45, "Kuşbaşı et",    "🥩", IngredientCategory.Meat,      MeasureUnit.Gram),
        I(46, "Somon",         "🐟", IngredientCategory.Meat,      MeasureUnit.Gram),
        I(47, "Ton balığı",    "🐟", IngredientCategory.Other,     MeasureUnit.Gram),
        I(48, "Krema",         "🥛", IngredientCategory.Dairy,     MeasureUnit.Milliliter),
        I(49, "Ekmek",         "🍞", IngredientCategory.Grain,     MeasureUnit.Piece),
        I(50, "Lavaş",         "🫓", IngredientCategory.Grain,     MeasureUnit.Piece),
        I(51, "Tel şehriye",   "🍜", IngredientCategory.Grain,     MeasureUnit.Gram),
        I(52, "Karabiber",     "🧂", IngredientCategory.Spice,     MeasureUnit.Gram),
        I(53, "Kimyon",        "🧂", IngredientCategory.Spice,     MeasureUnit.Gram),
        I(54, "Kekik",         "🌿", IngredientCategory.Spice,     MeasureUnit.Gram),
        I(55, "Şeker",         "🍬", IngredientCategory.Other,     MeasureUnit.Gram),
        I(56, "Bal",           "🍯", IngredientCategory.Other,     MeasureUnit.Gram),
        I(57, "Ceviz",         "🌰", IngredientCategory.Other,     MeasureUnit.Gram),
        I(58, "Muz",           "🍌", IngredientCategory.Fruit,     MeasureUnit.Piece),
        I(59, "Portakal",      "🍊", IngredientCategory.Fruit,     MeasureUnit.Piece),
        I(60, "Sıvı yağ",      "🫗", IngredientCategory.Other,     MeasureUnit.Milliliter),

        // --- Tatlı ve hamur işi ---
        I(61, "İrmik",           "🌾", IngredientCategory.Grain,     MeasureUnit.Gram),
        I(62, "Nişasta",         "🌽", IngredientCategory.Grain,     MeasureUnit.Gram),
        I(63, "Kakao",           "🍫", IngredientCategory.Other,     MeasureUnit.Gram),
        I(64, "Bitter çikolata", "🍫", IngredientCategory.Other,     MeasureUnit.Gram),
        I(65, "Vanilin",         "🍦", IngredientCategory.Spice,     MeasureUnit.Gram),
        I(66, "Kabartma tozu",   "🧁", IngredientCategory.Other,     MeasureUnit.Gram),
        I(67, "Kuru maya",       "🍞", IngredientCategory.Other,     MeasureUnit.Gram),
        I(68, "Yufka",           "🫓", IngredientCategory.Grain,     MeasureUnit.Piece),
        I(69, "Fındık",          "🌰", IngredientCategory.Other,     MeasureUnit.Gram),
        I(70, "Antep fıstığı",   "🥜", IngredientCategory.Other,     MeasureUnit.Gram),
        I(71, "Badem",           "🌰", IngredientCategory.Other,     MeasureUnit.Gram),
        I(72, "Kuru üzüm",       "🍇", IngredientCategory.Fruit,     MeasureUnit.Gram),
        I(73, "Tarçın",          "🧂", IngredientCategory.Spice,     MeasureUnit.Gram),
        I(74, "Pudra şekeri",    "🍬", IngredientCategory.Other,     MeasureUnit.Gram),
        I(75, "Hindistan cevizi","🥥", IngredientCategory.Other,     MeasureUnit.Gram),
        I(76, "Çilek",           "🍓", IngredientCategory.Fruit,     MeasureUnit.Gram),

        // --- Kahvaltılık ---
        I(77, "Labne",           "🧀", IngredientCategory.Dairy,     MeasureUnit.Gram),
        I(78, "Lor peyniri",     "🧀", IngredientCategory.Dairy,     MeasureUnit.Gram),
        I(79, "Zeytin",          "🫒", IngredientCategory.Other,     MeasureUnit.Gram),
        I(80, "Reçel",           "🫙", IngredientCategory.Other,     MeasureUnit.Gram),
        I(81, "Tahin",           "🫙", IngredientCategory.Other,     MeasureUnit.Gram),
        I(82, "Pekmez",          "🫙", IngredientCategory.Other,     MeasureUnit.Gram),
        I(83, "Kaymak",          "🥛", IngredientCategory.Dairy,     MeasureUnit.Gram),
        I(84, "Sosis",           "🌭", IngredientCategory.Meat,      MeasureUnit.Gram),
        I(85, "Pastırma",        "🥩", IngredientCategory.Meat,      MeasureUnit.Gram),

        // --- Salata ---
        I(86, "Marul",           "🥬", IngredientCategory.Vegetable, MeasureUnit.Piece),
        I(87, "Roka",            "🌿", IngredientCategory.Vegetable, MeasureUnit.Gram),
        I(88, "Nar ekşisi",      "🫙", IngredientCategory.Other,     MeasureUnit.Milliliter),
        I(89, "Nar",             "🍎", IngredientCategory.Fruit,     MeasureUnit.Piece),
        I(90, "Mor lahana",      "🥬", IngredientCategory.Vegetable, MeasureUnit.Piece),
        I(91, "Turp",            "🥕", IngredientCategory.Vegetable, MeasureUnit.Piece),
        I(92, "Taze soğan",      "🧅", IngredientCategory.Vegetable, MeasureUnit.Piece),
        I(93, "Avokado",         "🥑", IngredientCategory.Fruit,     MeasureUnit.Piece),

        // --- Çorba ve bakliyat ---
        I(94, "Yeşil mercimek",  "🫘", IngredientCategory.Legume,    MeasureUnit.Gram),
        I(95, "Tarhana",         "🥣", IngredientCategory.Grain,     MeasureUnit.Gram),
        I(96, "Arpa şehriye",    "🍜", IngredientCategory.Grain,     MeasureUnit.Gram),

        // --- Soslar ve kuru gıda ---
        I(97, "Sirke",           "🫙", IngredientCategory.Other,     MeasureUnit.Milliliter),
        I(98, "Hardal",          "🫙", IngredientCategory.Other,     MeasureUnit.Gram),
        I(99, "Mayonez",         "🫙", IngredientCategory.Other,     MeasureUnit.Gram),
        I(100, "Ketçap",         "🫙", IngredientCategory.Other,     MeasureUnit.Gram),
        I(101, "Galeta unu",     "🍞", IngredientCategory.Grain,     MeasureUnit.Gram),
        I(102, "Mısır unu",      "🌽", IngredientCategory.Grain,     MeasureUnit.Gram),

        // --- Baharat ---
        I(103, "Susam",          "🌾", IngredientCategory.Spice,     MeasureUnit.Gram),
        I(104, "Çörek otu",      "🌾", IngredientCategory.Spice,     MeasureUnit.Gram),
        I(105, "Toz kırmızı biber","🌶️", IngredientCategory.Spice,   MeasureUnit.Gram),
        I(106, "Zerdeçal",       "🧂", IngredientCategory.Spice,     MeasureUnit.Gram),

        // --- Et ve balık ---
        I(107, "Kuzu eti",       "🍖", IngredientCategory.Meat,      MeasureUnit.Gram),
        I(108, "Tavuk but",      "🍗", IngredientCategory.Meat,      MeasureUnit.Gram),
        I(109, "Hamsi",          "🐟", IngredientCategory.Meat,      MeasureUnit.Gram),
        I(110, "Levrek",         "🐟", IngredientCategory.Meat,      MeasureUnit.Gram)
    ];
}