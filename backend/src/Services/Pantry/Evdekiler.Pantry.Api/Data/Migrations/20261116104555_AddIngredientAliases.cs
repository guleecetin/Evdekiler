using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace Evdekiler.Pantry.Api.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddIngredientAliases : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "IngredientAlias",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    IngredientId = table.Column<int>(type: "integer", nullable: false),
                    Alias = table.Column<string>(type: "character varying(60)", maxLength: 60, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_IngredientAlias", x => x.Id);
                    table.ForeignKey(
                        name: "FK_IngredientAlias_Ingredients_IngredientId",
                        column: x => x.IngredientId,
                        principalTable: "Ingredients",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.InsertData(
                table: "IngredientAlias",
                columns: new[] { "Id", "Alias", "IngredientId" },
                values: new object[,]
                {
                    { 1, "domates salcasi", 27 },
                    { 2, "biber salcasi", 27 },
                    { 3, "unlu mam", 49 },
                    { 4, "francala", 49 },
                    { 5, "kasar", 16 },
                    { 6, "beyaz peyn", 15 },
                    { 7, "tavuk gogus", 19 },
                    { 8, "pilic gogus", 19 },
                    { 9, "pilic but", 108 },
                    { 10, "aycicek", 60 },
                    { 11, "zeytin yagi", 28 },
                    { 12, "baldo", 21 },
                    { 13, "osmancik", 21 },
                    { 14, "spagetti", 22 },
                    { 15, "penne", 22 },
                    { 16, "kirmizi mercimek", 25 },
                    { 17, "toz seker", 55 },
                    { 18, "kup seker", 55 },
                    { 19, "maydonoz", 31 },
                    { 20, "dana kiyma", 20 }
                });

            migrationBuilder.CreateIndex(
                name: "IX_IngredientAlias_Alias",
                table: "IngredientAlias",
                column: "Alias",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_IngredientAlias_IngredientId",
                table: "IngredientAlias",
                column: "IngredientId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "IngredientAlias");
        }
    }
}
