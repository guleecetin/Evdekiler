using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace Evdekiler.Pantry.Api.Data.Migrations
{
    /// <inheritdoc />
    public partial class ExpandIngredientCatalog : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.InsertData(
                table: "Ingredients",
                columns: new[] { "Id", "Category", "DefaultUnit", "Emoji", "Name" },
                values: new object[,]
                {
                    { 31, "Vegetable", "Piece", "🌿", "Maydanoz" },
                    { 32, "Vegetable", "Piece", "🌿", "Dereotu" },
                    { 33, "Spice", "Gram", "🌿", "Nane" },
                    { 34, "Vegetable", "Gram", "🍄", "Mantar" },
                    { 35, "Vegetable", "Piece", "🥦", "Brokoli" },
                    { 36, "Vegetable", "Piece", "🥦", "Karnabahar" },
                    { 37, "Vegetable", "Gram", "🫛", "Taze fasulye" },
                    { 38, "Legume", "Gram", "🫘", "Kuru fasulye" },
                    { 39, "Vegetable", "Piece", "🥬", "Pırasa" },
                    { 40, "Vegetable", "Gram", "🫛", "Bezelye" },
                    { 41, "Vegetable", "Gram", "🌽", "Mısır" },
                    { 42, "Vegetable", "Piece", "🥬", "Lahana" },
                    { 43, "Vegetable", "Piece", "🫑", "Kırmızı biber" },
                    { 44, "Meat", "Gram", "🌭", "Sucuk" },
                    { 45, "Meat", "Gram", "🥩", "Kuşbaşı et" },
                    { 46, "Meat", "Gram", "🐟", "Somon" },
                    { 47, "Other", "Gram", "🐟", "Ton balığı" },
                    { 48, "Dairy", "Milliliter", "🥛", "Krema" },
                    { 49, "Grain", "Piece", "🍞", "Ekmek" },
                    { 50, "Grain", "Piece", "🫓", "Lavaş" },
                    { 51, "Grain", "Gram", "🍜", "Tel şehriye" },
                    { 52, "Spice", "Gram", "🧂", "Karabiber" },
                    { 53, "Spice", "Gram", "🧂", "Kimyon" },
                    { 54, "Spice", "Gram", "🌿", "Kekik" },
                    { 55, "Other", "Gram", "🍬", "Şeker" },
                    { 56, "Other", "Gram", "🍯", "Bal" },
                    { 57, "Other", "Gram", "🌰", "Ceviz" },
                    { 58, "Fruit", "Piece", "🍌", "Muz" },
                    { 59, "Fruit", "Piece", "🍊", "Portakal" },
                    { 60, "Other", "Milliliter", "🫗", "Sıvı yağ" }
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 31);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 32);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 33);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 34);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 35);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 36);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 37);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 38);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 39);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 40);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 41);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 42);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 43);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 44);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 45);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 46);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 47);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 48);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 49);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 50);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 51);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 52);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 53);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 54);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 55);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 56);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 57);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 58);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 59);

            migrationBuilder.DeleteData(
                table: "Ingredients",
                keyColumn: "Id",
                keyValue: 60);
        }
    }
}
