using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Evdekiler.Pantry.Api.Data.Migrations
{
    /// <inheritdoc />
    public partial class RemoveHasDataSeeds : Migration
    {
        // Seed HasData'dan PantrySeed'e (yoksa ekle) taşındı.
        // EF Core burada var olan seed verisini silmek istiyordu; veri kalmalı, o yüzden bilerek boş.
        protected override void Up(MigrationBuilder migrationBuilder)
        {
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
        }
    }
}