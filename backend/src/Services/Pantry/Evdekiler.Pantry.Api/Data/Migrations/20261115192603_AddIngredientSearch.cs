using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Evdekiler.Pantry.Api.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddIngredientSearch : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Benzerlik (trigram) araması için PostgreSQL eklentisi
            migrationBuilder.Sql("CREATE EXTENSION IF NOT EXISTS pg_trgm;");

            // "Soğan" -> "sogan", "İrmik" -> "irmik": Türkçe karakterleri sadeleştirip küçük harfe çevirir
            migrationBuilder.Sql("""
                CREATE OR REPLACE FUNCTION search_key(t text) RETURNS text
                LANGUAGE sql IMMUTABLE PARALLEL SAFE AS
                $$ SELECT lower(translate(t, 'ÇĞİIÖŞÜçğıöşü', 'cgiiosucgiosu')) $$;
                """);

            // Aramayı hızlandıran index: fonksiyonun sonucu üzerinde trigram index
            migrationBuilder.Sql("""
                CREATE INDEX "IX_Ingredients_SearchKey"
                ON "Ingredients" USING gin (search_key("Name") gin_trgm_ops);
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""DROP INDEX IF EXISTS "IX_Ingredients_SearchKey";""");
            migrationBuilder.Sql("DROP FUNCTION IF EXISTS search_key(text);");
        }
    }
}