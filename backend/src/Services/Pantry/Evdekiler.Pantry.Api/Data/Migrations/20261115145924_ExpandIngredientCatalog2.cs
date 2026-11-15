using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace Evdekiler.Pantry.Api.Data.Migrations
{
    /// <inheritdoc />
    public partial class ExpandIngredientCatalog2 : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.InsertData(
                table: "Ingredients",
                columns: new[] { "Id", "Category", "DefaultUnit", "Emoji", "Name" },
                values: new object[,]
                {
                    { 61, "Grain", "Gram", "🌾", "İrmik" },
                    { 62, "Grain", "Gram", "🌽", "Nişasta" },
                    { 63, "Other", "Gram", "🍫", "Kakao" },
                    { 64, "Other", "Gram", "🍫", "Bitter çikolata" },
                    { 65, "Spice", "Gram", "🍦", "Vanilin" },
                    { 66, "Other", "Gram", "🧁", "Kabartma tozu" },
                    { 67, "Other", "Gram", "🍞", "Kuru maya" },
                    { 68, "Grain", "Piece", "🫓", "Yufka" },
                    { 69, "Other", "Gram", "🌰", "Fındık" },
                    { 70, "Other", "Gram", "🥜", "Antep fıstığı" },
                    { 71, "Other", "Gram", "🌰", "Badem" },
                    { 72, "Fruit", "Gram", "🍇", "Kuru üzüm" },
                    { 73, "Spice", "Gram", "🧂", "Tarçın" },
                    { 74, "Other", "Gram", "🍬", "Pudra şekeri" },
                    { 75, "Other", "Gram", "🥥", "Hindistan cevizi" },
                    { 76, "Fruit", "Gram", "🍓", "Çilek" },
                    { 77, "Dairy", "Gram", "🧀", "Labne" },
                    { 78, "Dairy", "Gram", "🧀", "Lor peyniri" },
                    { 79, "Other", "Gram", "🫒", "Zeytin" },
                    { 80, "Other", "Gram", "🫙", "Reçel" },
                    { 81, "Other", "Gram", "🫙", "Tahin" },
                    { 82, "Other", "Gram", "🫙", "Pekmez" },
                    { 83, "Dairy", "Gram", "🥛", "Kaymak" },
                    { 84, "Meat", "Gram", "🌭", "Sosis" },
                    { 85, "Meat", "Gram", "🥩", "Pastırma" },
                    { 86, "Vegetable", "Piece", "🥬", "Marul" },
                    { 87, "Vegetable", "Gram", "🌿", "Roka" },
                    { 88, "Other", "Milliliter", "🫙", "Nar ekşisi" },
                    { 89, "Fruit", "Piece", "🍎", "Nar" },
                    { 90, "Vegetable", "Piece", "🥬", "Mor lahana" },
                    { 91, "Vegetable", "Piece", "🥕", "Turp" },
                    { 92, "Vegetable", "Piece", "🧅", "Taze soğan" },
                    { 93, "Fruit", "Piece", "🥑", "Avokado" },
                    { 94, "Legume", "Gram", "🫘", "Yeşil mercimek" },
                    { 95, "Grain", "Gram", "🥣", "Tarhana" },
                    { 96, "Grain", "Gram", "🍜", "Arpa şehriye" },
                    { 97, "Other", "Milliliter", "🫙", "Sirke" },
                    { 98, "Other", "Gram", "🫙", "Hardal" },
                    { 99, "Other", "Gram", "🫙", "Mayonez" },
                    { 100, "Other", "Gram", "🫙", "Ketçap" },
                    { 101, "Grain", "Gram", "🍞", "Galeta unu" },
                    { 102, "Grain", "Gram", "🌽", "Mısır unu" },
                    { 103, "Spice", "Gram", "🌾", "Susam" },
                    { 104, "Spice", "Gram", "🌾", "Çörek otu" },
                    { 105, "Spice", "Gram", "🌶️", "Toz kırmızı biber" },
                    { 106, "Spice", "Gram", "🧂", "Zerdeçal" },
                    { 107, "Meat", "Gram", "🍖", "Kuzu eti" },
                    { 108, "Meat", "Gram", "🍗", "Tavuk but" },
                    { 109, "Meat", "Gram", "🐟", "Hamsi" },
                    { 110, "Meat", "Gram", "🐟", "Levrek" }
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 61);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 62);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 63);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 64);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 65);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 66);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 67);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 68);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 69);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 70);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 71);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 72);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 73);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 74);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 75);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 76);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 77);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 78);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 79);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 80);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 81);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 82);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 83);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 84);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 85);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 86);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 87);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 88);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 89);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 90);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 91);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 92);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 93);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 94);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 95);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 96);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 97);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 98);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 99);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 100);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 101);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 102);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 103);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 104);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 105);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 106);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 107);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 108);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 109);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 110);
        }
    }
}
