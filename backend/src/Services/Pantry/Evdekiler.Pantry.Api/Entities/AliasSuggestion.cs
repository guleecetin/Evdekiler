namespace Evdekiler.Pantry.Api.Entities;

// Kullanıcıların "bu satır şu malzeme" düzeltmelerinden doğan eşanlamlı önerisi
public class AliasSuggestion
{
    public int Id { get; set; }
    public int IngredientId { get; set; }
    public Ingredient Ingredient { get; set; } = null!;

    public string Text { get; set; } = string.Empty;        // normalize: "siyahcay fskbrlk"
    public string SampleLine { get; set; } = string.Empty;  // fişteki ham satır (admin görsün)
    public int Count { get; set; }                          // kaç kez önerildi
    public DateTime CreatedAt { get; set; }
    public DateTime LastSeenAt { get; set; }
}