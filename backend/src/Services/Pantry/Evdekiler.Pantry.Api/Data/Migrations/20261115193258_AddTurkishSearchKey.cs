using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Evdekiler.Pantry.Api.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddTurkishSearchKey : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Türkçe kurallarla küçük harf: "I" -> "ı", "İ" -> "i" ("SIR" -> "sır")
            migrationBuilder.Sql("""
                CREATE OR REPLACE FUNCTION tr_key(t text) RETURNS text
                LANGUAGE sql IMMUTABLE PARALLEL SAFE AS
                $$ SELECT lower(translate(t, 'Iİ', 'ıi')) $$;
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("DROP FUNCTION IF EXISTS tr_key(text);");
        }
    }
}