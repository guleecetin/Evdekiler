using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace Evdekiler.Pantry.Api.Data.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Ingredients",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    Name = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    Category = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    DefaultUnit = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Ingredients", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "PantryItems",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    IngredientId = table.Column<int>(type: "integer", nullable: false),
                    Quantity = table.Column<decimal>(type: "numeric(10,2)", precision: 10, scale: 2, nullable: false),
                    Unit = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    ExpiresAt = table.Column<DateOnly>(type: "date", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    xmin = table.Column<uint>(type: "xid", rowVersion: true, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PantryItems", x => x.Id);
                    table.ForeignKey(
                        name: "FK_PantryItems_Ingredients_IngredientId",
                        column: x => x.IngredientId,
                        principalTable: "Ingredients",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.InsertData(
                table: "Ingredients",
                columns: new[] { "Id", "Category", "DefaultUnit", "Name" },
                values: new object[,]
                {
                    { 1, "Vegetable", "Piece", "Domates" },
                    { 2, "Vegetable", "Piece", "Salatalık" },
                    { 3, "Vegetable", "Piece", "Biber" },
                    { 4, "Vegetable", "Piece", "Soğan" },
                    { 5, "Vegetable", "Piece", "Sarımsak" },
                    { 6, "Vegetable", "Kilogram", "Patates" },
                    { 7, "Vegetable", "Piece", "Havuç" },
                    { 8, "Vegetable", "Piece", "Kabak" },
                    { 9, "Vegetable", "Piece", "Patlıcan" },
                    { 10, "Vegetable", "Gram", "Ispanak" },
                    { 11, "Fruit", "Piece", "Limon" },
                    { 12, "Fruit", "Piece", "Elma" },
                    { 13, "Dairy", "Liter", "Süt" },
                    { 14, "Dairy", "Gram", "Yoğurt" },
                    { 15, "Dairy", "Gram", "Beyaz peynir" },
                    { 16, "Dairy", "Gram", "Kaşar peyniri" },
                    { 17, "Dairy", "Gram", "Tereyağı" },
                    { 18, "Dairy", "Piece", "Yumurta" },
                    { 19, "Meat", "Gram", "Tavuk göğsü" },
                    { 20, "Meat", "Gram", "Kıyma" },
                    { 21, "Grain", "Gram", "Pirinç" },
                    { 22, "Grain", "Gram", "Makarna" },
                    { 23, "Grain", "Gram", "Bulgur" },
                    { 24, "Grain", "Gram", "Un" },
                    { 25, "Legume", "Gram", "Mercimek" },
                    { 26, "Legume", "Gram", "Nohut" },
                    { 27, "Other", "Gram", "Salça" },
                    { 28, "Other", "Milliliter", "Zeytinyağı" },
                    { 29, "Spice", "Gram", "Tuz" },
                    { 30, "Spice", "Gram", "Pul biber" }
                });

            migrationBuilder.CreateIndex(
                name: "IX_Ingredients_Name",
                table: "Ingredients",
                column: "Name",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_PantryItems_IngredientId",
                table: "PantryItems",
                column: "IngredientId");

            migrationBuilder.CreateIndex(
                name: "IX_PantryItems_UserId_ExpiresAt",
                table: "PantryItems",
                columns: new[] { "UserId", "ExpiresAt" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "PantryItems");

            migrationBuilder.DropTable(
                name: "Ingredients");
        }
    }
}
