using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Evdekiler.Recipe.Api.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddRecipeCategory : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Category",
                table: "Recipes",
                type: "character varying(20)",
                maxLength: 20,
                nullable: false,
                defaultValue: "MainCourse");

            migrationBuilder.CreateIndex(
                name: "IX_Recipes_Category",
                table: "Recipes",
                column: "Category");

            // Var olan tarifleri doğru kategoriye taşı (veri migration'ı)
            migrationBuilder.Sql("""
                UPDATE "Recipes" SET "Category" = 'Soup'
                    WHERE "Slug" IN ('mercimek-corbasi', 'ezogelin-corbasi');
                UPDATE "Recipes" SET "Category" = 'Salad'
                    WHERE "Slug" IN ('coban-salatasi');
                UPDATE "Recipes" SET "Category" = 'Breakfast'
                    WHERE "Slug" IN ('menemen', 'ispanakli-yumurta', 'sucuklu-yumurta');
                UPDATE "Recipes" SET "Category" = 'Snack'
                    WHERE "Slug" IN ('mucver');
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Recipes_Category",
                table: "Recipes");

            migrationBuilder.DropColumn(
                name: "Category",
                table: "Recipes");
        }
    }
}