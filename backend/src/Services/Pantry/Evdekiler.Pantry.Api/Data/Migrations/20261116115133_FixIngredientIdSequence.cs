using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Evdekiler.Pantry.Api.Data.Migrations
{
    /// <inheritdoc />
    public partial class FixIngredientIdSequence : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // HasData Id'leri elle verdi; otomatik sayacı en büyük Id'ye ayarla
            migrationBuilder.Sql("""
                SELECT setval(
                    pg_get_serial_sequence('"Ingredients"', 'Id'),
                    (SELECT COALESCE(MAX("Id"), 1) FROM "Ingredients"));
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
        }
    }
}